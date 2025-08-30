import 'models.dart';

/// Lightweight heuristics to build memory index from a chat session.
/// No network calls; uses simple NLP-like rules.
class MemoryBuilder {
  /// Estimate tokens from characters (very rough): ~4 chars/token English.
  static int _estimateTokens(String text) {
    if (text.isEmpty) return 0;
    final chars = text.runes.length;
    return (chars / 4).round();
  }

  static ChatAnalyticsModel buildAnalytics(ChatSessionModel s) {
    final startedAt = s.createdAt;
    final endedAt = s.updatedAt;
    final duration = endedAt.difference(startedAt).inSeconds;
    int total = s.messages.length;
    int userCount = 0, modelCount = 0;
    int userChars = 0, modelChars = 0;
    int userTokens = 0, modelTokens = 0;
    for (final m in s.messages) {
      final text = m.text;
      final tokens = _estimateTokens(text);
      if (m.role == 'user') {
        userCount++;
        userChars += text.length;
        userTokens += tokens;
      } else {
        modelCount++;
        modelChars += text.length;
        modelTokens += tokens;
      }
    }
    final avgModelTokens = modelCount == 0 ? 0.0 : modelTokens / modelCount;
    return ChatAnalyticsModel(
      sessionId: s.id,
      startedAt: startedAt,
      endedAt: endedAt,
      durationSeconds: duration,
      totalMessages: total,
      userRequestCount: userCount,
      modelResponseCount: modelCount,
      userCharsTotal: userChars,
      modelCharsTotal: modelChars,
      userTokensTotal: userTokens,
      modelTokensTotal: modelTokens,
      avgModelTokensPerResponse: avgModelTokens,
    );
  }

  /// Extract 10-20 hashtags from the entire session content.
  static List<String> buildSessionHashtags(
    ChatSessionModel s, {
    int min = 10,
    int max = 20,
  }) {
    final text = s.messages.map((m) => m.text).join('\n');
    final words = _keywords(text);
    final tags = <String>[];
    for (final w in words) {
      if (tags.length >= max) break;
      final tag = w.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
      if (tag.length < 3) continue;
      if (!tags.contains(tag)) tags.add(tag);
    }
    // Ensure min tags by backfilling with model/space/title heuristics
    if (tags.length < min) {
      final extras = <String?>[s.model, s.spaceId, s.title].whereType<String>();
      for (final e in extras) {
        if (tags.length >= min) break;
        final t = e.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
        if (t.length >= 3 && !tags.contains(t)) tags.add(t);
      }
    }
    return tags.take(max).toList(growable: false);
  }

  /// Slice the session into sub memory pieces by topic windows using simple rules.
  static List<SubMemoryPieceModel> buildPieces(ChatSessionModel s) {
    final pieces = <SubMemoryPieceModel>[];
    // Sliding window: group every ~6 messages as a piece, aligned on user prompts
    const window = 6;
    for (int i = 0; i < s.messages.length; i += window) {
      final chunk = s.messages.sublist(
        i,
        i + window > s.messages.length ? s.messages.length : i + window,
      );
      if (chunk.isEmpty) continue;
      final ids = chunk.map((e) => e.id).toList(growable: false);
      final text = chunk.map((e) => '${e.role}: ${e.text}').join('\n');
      final title = _titleFromChunk(chunk);
      final tags = _keywords(
        text,
      ).take(12).map((e) => e.toLowerCase()).toList();
      final summary = _summarize(text);
      pieces.add(
        SubMemoryPieceModel(
          id: 'piece_${s.id}_$i',
          sessionId: s.id,
          messageIds: ids,
          title: title,
          content: text,
          hashtags: tags,
          summary: summary,
          createdAt: DateTime.now(),
        ),
      );
    }
    return pieces;
  }

  /// Group pieces into core sections by dominant hashtag/topic.
  static List<CoreMemorySectionModel> buildSections(
    String sessionId,
    List<SubMemoryPieceModel> pieces,
  ) {
    final Map<String, List<SubMemoryPieceModel>> byTag = {};
    for (final p in pieces) {
      // pick the first hashtag as primary
      final primary = p.hashtags.isEmpty ? 'general' : p.hashtags.first;
      (byTag[primary] ??= []).add(p);
    }
    final now = DateTime.now();
    final sections = <CoreMemorySectionModel>[];
    for (final entry in byTag.entries) {
      final title = _titleCase(entry.key.replaceAll('_', ' '));
      final summary = _summarize(entry.value.map((e) => e.summary).join(' '));
      // merge top hashtags across pieces
      final topTags = _topKHashtags(entry.value, k: 10);
      sections.add(
        CoreMemorySectionModel(
          id: 'section_${sessionId}_${entry.key}',
          sessionId: sessionId,
          title: title,
          summary: summary,
          hashtags: topTags,
          pieces: entry.value,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    return sections;
  }

  static MemoryIndexModel buildIndex(ChatSessionModel s) {
    final analytics = buildAnalytics(s);
    final pieces = buildPieces(s);
    final sections = buildSections(s.id, pieces);
    return MemoryIndexModel(
      sessionId: s.id,
      generatedAt: DateTime.now(),
      analytics: analytics,
      sections: sections,
    );
  }

  // --- helpers ---
  static Iterable<String> _keywords(String text) {
    final normalized = text.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );
    final words = normalized.split(RegExp(r'\s+')).where((w) => w.length >= 3);
    // remove common stopwords
    const stop = {
      'the',
      'and',
      'for',
      'with',
      'that',
      'this',
      'from',
      'your',
      'you',
      'are',
      'was',
      'were',
      'have',
      'has',
      'had',
      'but',
      'not',
      'can',
      'use',
      'using',
      'about',
      'what',
      'how',
      'why',
      'when',
      'then',
      'than',
      'also',
      'any',
      'all',
      'get',
      'got',
      'will',
      'just',
      'like',
      'one',
      'two',
      'three',
      'onto',
      'each',
      'more',
      'most',
      'such',
      'per',
      'very',
      'much',
      'many',
      'able',
      'make',
      'made',
      'could',
      'should',
      'would',
    };
    final filtered = words.where((w) => !stop.contains(w));
    // frequency map
    final freq = <String, int>{};
    for (final w in filtered) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key);
  }

  static String _titleFromChunk(List<ChatMessageModel> chunk) {
    // Prefer the first user line as a piece title
    final user = chunk.firstWhere(
      (m) => m.role == 'user' && m.text.trim().isNotEmpty,
      orElse: () => chunk.first,
    );
    final txt = user.text.trim();
    if (txt.isEmpty) return 'Conversation';
    final single = txt.split('\n').first.trim();
    return single.length > 60 ? '${single.substring(0, 57)}…' : single;
  }

  static String _summarize(String text) {
    // Naive heuristic summary: first sentence or first ~140 chars
    final trimmed = text.replaceAll('\n', ' ').trim();
    final period = trimmed.indexOf('. ');
    if (period > 40 && period < 180) {
      return trimmed.substring(0, period + 1);
    }
    return trimmed.length > 160 ? '${trimmed.substring(0, 157)}…' : trimmed;
  }

  static List<String> _topKHashtags(
    List<SubMemoryPieceModel> pieces, {
    int k = 10,
  }) {
    final freq = <String, int>{};
    for (final p in pieces) {
      for (final h in p.hashtags) {
        freq[h] = (freq[h] ?? 0) + 1;
      }
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(k).map((e) => e.key).toList(growable: false);
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(RegExp(r'\s+'))
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : '');
        })
        .join(' ');
  }
}
