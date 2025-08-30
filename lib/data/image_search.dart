import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

// Provide your Pexels API key at build/run time:
// flutter run --dart-define=PEXELS_API_KEY=YOUR_KEY
const String _pexelsKey = String.fromEnvironment(
  'PEXELS_API_KEY',
  defaultValue: '',
);

const String _geminiKey = String.fromEnvironment(
  'GEMINI_API_KEY',
  defaultValue: '',
);

Future<String?> _refineQueryWithGemini(String topic) async {
  if (_geminiKey.isEmpty) return null;
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiKey,
    );
    final prompt =
        'Give 2-5 concise, search-ready photo keywords for high-quality, non-branded images related to: "$topic". '
        'Focus on concrete nouns or activities. Return ONLY the keywords, comma-separated, no extra text.';
    final resp = await model.generateContent([Content.text(prompt)]);
    final text = resp.text?.trim();
    if (text == null || text.isEmpty) return null;
    final parts = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  } catch (_) {
    return null;
  }
}

Future<List<String>> fetchRelatedImages(String query, {int limit = 8}) async {
  if (_pexelsKey.isEmpty) {
    // No key configured. Silently return empty to keep UI clean.
    return const [];
  }

  // Try to improve the query with Gemini, fallback to original.
  final refined = await _refineQueryWithGemini(query);
  final effectiveQuery = (refined != null && refined.isNotEmpty)
      ? '$query $refined'
      : query;

  final uri = Uri.https('api.pexels.com', '/v1/search', {
    'query': effectiveQuery,
    'per_page': limit.toString(),
    'orientation': 'landscape',
  });

  try {
    final res = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        // Pexels requires the API key in the Authorization header.
        'Authorization': _pexelsKey,
      },
    );

    if (res.statusCode != 200) return const [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final photos = (data['photos'] as List?) ?? const [];
    return photos
        .map((e) => (e as Map<String, dynamic>)['src'] as Map<String, dynamic>?)
        .where(
          (src) =>
              src != null &&
              (src['medium'] is String || src['small'] is String),
        )
        .map((src) => (src!['medium'] as String?) ?? (src['small'] as String))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}
