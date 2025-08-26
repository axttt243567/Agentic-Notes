import 'package:flutter/material.dart';
import 'widgets/universal_chat_toolbar.dart';
import 'main.dart';

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
      appBar: AppBar(
        title: Text(widget.title ?? 'AI Chat'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Voice call',
            icon: const Icon(Icons.call_outlined),
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Call (UI only)')));
            },
          ),
          IconButton(
            tooltip: 'Video call',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call (UI only)')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // top toolbar removed per user request
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: m.isUser
                                    ? const Color(0xFF1D9BF0)
                                    : const Color(0xFF0E0E0E),
                                borderRadius: BorderRadius.circular(18),
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
            // divider removed for a cleaner minimal look
            UniversalChatToolbar(
              textFieldFocus: _inputFocus,
              controller: _ctrl,
              sending: _sending,
              onAction: (a) {
                if (a == ChatAction.text) return; // focus managed
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Action: ${a.name}')));
              },
              onSend: (t) {
                _send();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
      _ctrl.clear();
    });

    try {
      final chat = ChatProvider.of(context);
      final reply = await chat.sendText(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chat failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
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
            'Uses Gemini 2.5 Flash-Lite. Add an API key in Profile.',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
        ],
      ),
    );
  }
}
