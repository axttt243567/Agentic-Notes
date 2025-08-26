import 'package:flutter/material.dart';
import 'widgets/universal_chat_toolbar.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.title});
  final String? title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _inputFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'AI Chat')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: UniversalChatToolbar(
                textFieldFocus: _inputFocus,
                onAction: (a) {
                  // Placeholder interactions for front-end only
                  switch (a) {
                    case ChatAction.text:
                      // focus handled in toolbar
                      break;
                    case ChatAction.camera:
                    case ChatAction.gallery:
                    case ChatAction.files:
                    case ChatAction.audio:
                    case ChatAction.call:
                    case ChatAction.video:
                    case ChatAction.spaces:
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Action: ${a.name}')),
                      );
                      break;
                  }
                },
              ),
            ),
            Expanded(
              child: _messages.isEmpty
                  ? const _ChatEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      reverse: true,
                      itemCount: _messages.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final m = _messages[_messages.length - 1 - i];
                        return Align(
                          alignment: m.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .75,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: m.isUser
                                    ? const Color(0xFF1D9BF0)
                                    : const Color(0xFF0A0A0A),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Color(0xFF2F3336)),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1, color: Color(0xFF2F3336)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _inputFocus,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
      _ctrl.clear();
    });

    // Simulate AI response (front-end only)
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: 'Echo: $text', isUser: false));
      _sending = false;
    });
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome, size: 44, color: Color(0xFF71767B)),
          SizedBox(height: 12),
          Text(
            'Start a conversation',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Front-end only demo chat',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
        ],
      ),
    );
  }
}
