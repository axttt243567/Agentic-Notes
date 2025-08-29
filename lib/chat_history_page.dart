import 'package:flutter/material.dart';
import 'data/models.dart';
import 'main.dart';
import 'chat_page.dart';
import 'dart:async';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<ChatSessionModel> _sessions = const [];
  StreamSubscription<List<ChatSessionModel>>? _sub;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final db = DBProvider.of(context);
    _sessions = db.currentChatSessions;
    _sub?.cancel();
    _sub = db.chatSessionsStream.listen((list) {
      if (!mounted) return;
      setState(() => _sessions = list);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat history')),
      body: _sessions.isEmpty
          ? const Center(child: Text('No conversations yet'))
          : ListView.separated(
              itemCount: _sessions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = _sessions[i];
                return ListTile(
                  title: Text(
                    s.title.isEmpty ? 'Untitled chat' : s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${s.model} · ${s.messageCount} messages\n${s.lastSnippet ?? ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _fmtTime(s.updatedAt),
                    style: const TextStyle(
                      color: Color(0xFF71767B),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ChatPage(sessionId: s.id, title: s.title),
                      ),
                    );
                  },
                  onLongPress: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete conversation?'),
                        content: const Text(
                          'This will permanently remove the conversation.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      DBProvider.of(context).deleteChatSession(s.id);
                    }
                  },
                );
              },
            ),
    );
  }

  String _fmtTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
