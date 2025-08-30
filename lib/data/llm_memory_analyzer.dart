import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import 'models.dart';

/// Calls Gemini (gemini-2.5-flash) to produce memory summary, hashtags, and core/sub sections.
class LlmMemoryAnalyzer {
  final DatabaseService db;
  LlmMemoryAnalyzer(this.db);

  Future<MemoryIndexModel?> analyzeSession(ChatSessionModel s) async {
    final activeId = db.currentActiveApiKeyId;
    if (activeId == null) return null; // no key, skip
    final key = db.currentApiKeys.firstWhere(
      (k) => k.id == activeId,
      orElse: () => throw StateError('Active API key not found.'),
    );

    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: key.value,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );

    final spec = {
      'instructions':
          'You are a memory indexer. Given a conversation, return JSON with:\n'
          '- sessionSummary: a 30-word concise summary.\n'
          '- sessionHashtags: 10-20 hashtags like #word1_word2 (lowercase, underscores, no spaces).\n'
          '- cores: 5 core memory sections (title, summary, hashtags).\n'
          '- subs: sub memories mapped to cores (title, summary, hashtags).\n',
      'output_schema': {
        'type': 'object',
        'properties': {
          'sessionSummary': {'type': 'string'},
          'sessionHashtags': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'cores': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'title': {'type': 'string'},
                'summary': {'type': 'string'},
                'hashtags': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
              'required': ['title', 'summary', 'hashtags'],
            },
          },
          'subs': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'coreTitle': {'type': 'string'},
                'title': {'type': 'string'},
                'summary': {'type': 'string'},
                'hashtags': {
                  'type': 'array',
                  'items': {'type': 'string'},
                },
              },
              'required': ['coreTitle', 'title', 'summary', 'hashtags'],
            },
          },
        },
        'required': ['sessionSummary', 'sessionHashtags', 'cores'],
      },
    };

    final transcript = s.messages
        .map((m) => '${m.role == 'user' ? 'User' : 'Assistant'}: ${m.text}')
        .join('\n');
    final prompt =
        'System spec (JSON):\n${jsonEncode(spec)}\n\n'
        'Conversation transcript:\n$transcript\n\n'
        'Return only JSON.';

    final resp = await model.generateContent([Content.text(prompt)]);
    final text = resp.text ?? '';
    Map<String, dynamic> data;
    try {
      data = jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      // Fallback: if model returned text around JSON, strip non-JSON
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start >= 0 && end > start) {
        data =
            jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
      } else {
        return null;
      }
    }

    // Build sections from cores/subs (subs are attached as pieces with summaries)
    final now = DateTime.now();
    final cores = (data['cores'] as List? ?? const []).cast<Map>();
    final subs = (data['subs'] as List? ?? const []).cast<Map>();

    final coreSections = <CoreMemorySectionModel>[];
    for (final c in cores) {
      final title = (c['title'] as String? ?? '').trim();
      final summary = (c['summary'] as String? ?? '').trim();
      final hashtags = ((c['hashtags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList();

      // Attach subs for this core by title match
      final relatedSubs = subs.where(
        (e) =>
            (e['coreTitle'] as String? ?? '').trim().toLowerCase() ==
            title.toLowerCase(),
      );
      final pieces = <SubMemoryPieceModel>[];
      int i = 0;
      for (final sm in relatedSubs) {
        pieces.add(
          SubMemoryPieceModel(
            id: 'sm_${s.id}_$i',
            sessionId: s.id,
            messageIds: const [],
            title: (sm['title'] as String? ?? '').trim(),
            content: '',
            hashtags: ((sm['hashtags'] as List?) ?? const [])
                .map((e) => e.toString())
                .toList(),
            summary: (sm['summary'] as String? ?? '').trim(),
            createdAt: now,
          ),
        );
        i++;
      }

      coreSections.add(
        CoreMemorySectionModel(
          id: 'core_${s.id}_${title.hashCode}',
          sessionId: s.id,
          title: title.isEmpty ? 'Core' : title,
          summary: summary,
          hashtags: hashtags,
          pieces: pieces,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    final analytics = _heuristicAnalytics(s);
    return MemoryIndexModel(
      sessionId: s.id,
      generatedAt: now,
      analytics: analytics,
      sections: coreSections,
      sessionSummary: (data['sessionSummary'] as String?)?.trim(),
      sessionHashtags: ((data['sessionHashtags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  ChatAnalyticsModel _heuristicAnalytics(ChatSessionModel s) {
    int userChars = 0, modelChars = 0, userCount = 0, modelCount = 0;
    for (final m in s.messages) {
      final len = m.text.length;
      if (m.role == 'user') {
        userChars += len;
        userCount++;
      } else {
        modelChars += len;
        modelCount++;
      }
    }
    final userTokens = (userChars / 4).round();
    final modelTokens = (modelChars / 4).round();
    final avg = modelCount == 0 ? 0.0 : modelTokens / modelCount;
    return ChatAnalyticsModel(
      sessionId: s.id,
      startedAt: s.createdAt,
      endedAt: s.updatedAt,
      durationSeconds: s.updatedAt.difference(s.createdAt).inSeconds,
      totalMessages: s.messages.length,
      userRequestCount: userCount,
      modelResponseCount: modelCount,
      userCharsTotal: userChars,
      modelCharsTotal: modelChars,
      userTokensTotal: userTokens,
      modelTokensTotal: modelTokens,
      avgModelTokensPerResponse: avg,
    );
  }
}
