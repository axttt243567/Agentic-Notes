import 'dart:convert';

import 'package:http/http.dart' as http;

class PexelsService {
  static const _base = 'https://api.pexels.com/v1/search';

  final String apiKey;
  PexelsService(this.apiKey);

  Future<List<String>> searchImageUrls({
    required String query,
    int perPage = 10,
  }) async {
    final uri = Uri.parse(_base).replace(
      queryParameters: {
        'query': query,
        'per_page': perPage.toString(),
        'orientation': 'landscape',
      },
    );
    final resp = await http.get(uri, headers: {'Authorization': apiKey});
    if (resp.statusCode != 200) {
      throw StateError('Pexels error ${resp.statusCode}: ${resp.body}');
    }
    final map = jsonDecode(resp.body) as Map<String, dynamic>;
    final photos = (map['photos'] as List?) ?? const [];
    final urls = <String>[];
    for (final p in photos) {
      final src = (p as Map)['src'] as Map?;
      if (src == null) continue;
      final url = src['landscape'] as String? ?? src['large'] as String?;
      if (url != null) urls.add(url);
    }
    return urls;
  }
}
