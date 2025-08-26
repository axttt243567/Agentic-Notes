import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';

class ChatService {
  final DatabaseService db;
  ChatService(this.db);

  /// Sends a single-turn text prompt to Gemini 2.5 Flash-Lite and returns the text reply.
  /// Throws StateError if no active API key is configured.
  Future<String> sendText(String prompt) async {
    final activeId = db.currentActiveApiKeyId;
    if (activeId == null) {
      throw StateError('No API key selected.');
    }
    final key = db.currentApiKeys.firstWhere(
      (k) => k.id == activeId,
      orElse: () => throw StateError('Active API key not found.'),
    );

    final model = GenerativeModel(
      model: 'gemini-2.5-flash-lite',
      apiKey: key.value,
    );

    final content = [Content.text(prompt)];
    final resp = await model.generateContent(content);
    return resp.text?.trim().isEmpty == false
        ? resp.text!.trim()
        : '(no response)';
  }
}
