import 'package:google_generative_ai/google_generative_ai.dart';
import 'database_service.dart';

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
    final userText = combined.isEmpty ? prompt : '$combined\n\nUser: $prompt';
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
