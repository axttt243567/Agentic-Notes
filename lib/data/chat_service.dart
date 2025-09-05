import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';
import 'models.dart';

class ChatService {
  final DatabaseService db;
  ChatService(this.db);

  /// Sends a text prompt to Gemini using the selected model and optional history for context.
  /// Throws StateError if no active API key is configured.
  Future<String> sendText(
    String prompt, {
    List<Map<String, String>> history =
        const [], // [{'role':'user|model','text':'...'}]
    String? model,
    String? spaceId,
  }) async {
    final activeId = db.currentActiveApiKeyId;
    if (activeId == null) {
      throw StateError('No API key selected.');
    }
    final key = db.currentApiKeys.firstWhere(
      (k) => k.id == activeId,
      orElse: () => throw StateError('Active API key not found.'),
    );

    final selectedModel = model ?? db.currentPreferredModel;

    final genModel = GenerativeModel(
      model: selectedModel,
      apiKey: key.value,
      generationConfig: GenerationConfig(responseMimeType: 'text/plain'),
    );

    // Flatten history into a single user message to avoid SDK role issues
    // seen with 'model' role on some versions/models.
    String combined = '';
    if (history.isNotEmpty) {
      final buf = StringBuffer('Context (previous turns):\n');
      // Keep last ~6 items to control prompt length
      final start = history.length > 6 ? history.length - 6 : 0;
      for (final h in history.sublist(start)) {
        final role = (h['role'] == 'user') ? 'User' : 'Assistant';
        final text = h['text'] ?? '';
        if (text.isEmpty) continue;
        buf.writeln('$role: $text');
      }
      buf.writeln('\nNow continue the conversation.');
      combined = buf.toString();
    }
    // Build optional advanced context from space
    String spaceContext = '';
    if ((spaceId ?? '').isNotEmpty) {
      final space = db.currentSpaces.firstWhere(
        (s) => s.id == spaceId,
        orElse: () => SpaceModel(id: spaceId!, name: '', emoji: ''),
      );
      if (space.advancedContext) {
        final tone = (space.tone).trim();
        final desc = space.description.trim();
        final goals = space.goals.trim();
        final guide = space.guide.trim();
        final meta = space.metadataJson.trim();

        final ctx = StringBuffer();
        ctx.writeln('You are assisting in a specific space. Use this context:');
        if (tone.isNotEmpty) ctx.writeln('Tone: $tone');
        if (desc.isNotEmpty) ctx.writeln('Description: $desc');
        if (goals.isNotEmpty) ctx.writeln('Goals: $goals');
        if (guide.isNotEmpty) ctx.writeln('Guide: $guide');
        if (meta.isNotEmpty) {
          ctx.writeln('Additional metadata (JSON):');
          ctx.writeln(meta);
        }

        // Answer preferences
        final prefs = <String>[];
        if (space.prefConcise) prefs.add('Be concise.');
        if (space.prefExamples) prefs.add('Include concrete examples.');
        if (space.prefClarify)
          prefs.add('Ask clarifying questions when ambiguous.');
        if (prefs.isNotEmpty) {
          ctx.writeln('Answer style preferences:');
          for (final p in prefs) ctx.writeln('- $p');
        }

        // Include a short summary from recent sessions in this space
        final sessions = db.currentChatSessions
            .where((s) => s.spaceId == spaceId)
            .toList(growable: false);
        if (sessions.isNotEmpty) {
          // use last updated session's lastSnippet for compact context
          sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          final recent = sessions.take(4); // last few
          final lines = <String>[];
          for (final s in recent) {
            final idx = db.getMemoryIndex(s.id);
            if (idx?.sessionSummary != null &&
                idx!.sessionSummary!.isNotEmpty) {
              lines.add(idx.sessionSummary!);
            } else if ((s.lastSnippet ?? '').trim().isNotEmpty) {
              lines.add(s.lastSnippet!.trim());
            }
          }
          if (lines.isNotEmpty) {
            ctx.writeln('Recent conversation summaries:');
            for (final l in lines.take(4)) ctx.writeln('- $l');
          }
        }

        // Include routine schedules linked to this space
        final schedules = db.currentSchedules
            .where((sch) => sch.spaceId == spaceId)
            .toList(growable: false);
        if (schedules.isNotEmpty) {
          String daysToStr(List<int> d) {
            const names = {
              1: 'Mon',
              2: 'Tue',
              3: 'Wed',
              4: 'Thu',
              5: 'Fri',
              6: 'Sat',
              7: 'Sun',
            };
            return d.map((e) => names[e] ?? e.toString()).join(' ');
          }

          ctx.writeln('Linked routines:');
          for (final sch in schedules.take(6)) {
            final t = sch.timeOfDay ?? '';
            ctx.writeln(
              '- ${sch.title} (${daysToStr(sch.daysOfWeek)}${t.isNotEmpty ? ' · $t' : ''})',
            );
          }
        }

        // Include combined space chat history if available (trim to keep prompt size bounded)
        final combo = db.getSpaceComboHistory(spaceId!);
        if (combo != null && combo.content.trim().isNotEmpty) {
          const maxChars = 4000; // keep context compact
          final text = combo.content.trim();
          final trimmed = text.length <= maxChars
              ? text
              : text.substring(text.length - maxChars);
          ctx.writeln('Combined chat history (recent, trimmed):');
          ctx.writeln(trimmed);
        }

        spaceContext = ctx.toString();
      }
    }

    final parts = <String>[];
    if (spaceContext.isNotEmpty) parts.add(spaceContext);
    if (combined.isNotEmpty) parts.add(combined);
    parts.add('User: $prompt');
    final userText = parts.join('\n\n');
    final messages = [Content.text(userText)];

    GenerateContentResponse resp;
    try {
      resp = await genModel.generateContent(messages);
    } on GenerativeAIException catch (e) {
      // Graceful fallback for models that may be restricted/unsupported.
      final msg = (e.message).toLowerCase();
      final isModelError =
          msg.contains('model') ||
          msg.contains('permission') ||
          msg.contains('unsupported');
      if (selectedModel.contains('pro') && isModelError) {
        final fallback = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: key.value,
          generationConfig: GenerationConfig(responseMimeType: 'text/plain'),
        );
        resp = await fallback.generateContent(messages);
      } else {
        rethrow;
      }
    }
    return resp.text?.trim().isEmpty == false
        ? resp.text!.trim()
        : '(no response)';
  }
}
