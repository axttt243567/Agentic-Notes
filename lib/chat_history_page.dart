import 'package:flutter/material.dart';
import 'data/models.dart';
import 'main.dart';
import 'chat_page.dart';
import 'data/memory_builder.dart';
import 'memory_insights_page.dart';
import 'dart:async';
import 'widgets/emoji_icon.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  List<ChatSessionModel> _all = const [];
  List<SpaceModel> _spaces = const [];
  List<MemoryItemModel> _memories = const [];
  Map<String, MemoryIndexModel> _memoryIndex = const {};

  StreamSubscription<List<ChatSessionModel>>? _subSessions;
  StreamSubscription<List<SpaceModel>>? _subSpaces;
  StreamSubscription<List<MemoryItemModel>>? _subMemories;
  StreamSubscription<Map<String, MemoryIndexModel>>? _subMemIdx;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = DBProvider.of(context);
      _all = db.currentChatSessions;
      _spaces = db.currentSpaces;
      _memories = db.currentMemories;
      _memoryIndex = db.currentMemoryIndex;
      setState(() {});
      _subSessions?.cancel();
      _subSessions = db.chatSessionsStream.listen((v) {
        if (!mounted) return;
        setState(() => _all = v);
      });
      _subSpaces?.cancel();
      _subSpaces = db.spacesStream.listen((v) {
        if (!mounted) return;
        setState(() => _spaces = v);
      });
      _subMemories?.cancel();
      _subMemories = db.memoriesStream.listen((v) {
        if (!mounted) return;
        setState(() => _memories = v);
      });
      _subMemIdx?.cancel();
      _subMemIdx = db.memoryIndexStream.listen((v) {
        if (!mounted) return;
        setState(() => _memoryIndex = v);
      });
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _subSessions?.cancel();
    _subSpaces?.cancel();
    _subMemories?.cancel();
    _subMemIdx?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'All chats'),
            Tab(text: 'Memory'),
            Tab(text: 'Spaces'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _AllChatsList(
            sessions: _all,
            onOpen: _openSession,
            onDelete: _deleteSession,
          ),
          _MemoryList(
            items: _memories,
            onCreate: _createMemory,
            onDelete: _deleteMemory,
            sessions: _all,
            memoryIndex: _memoryIndex,
            onAnalyzeOne: _analyzeOne,
            onAnalyzeAll: _analyzeAll,
            onOpenInsights: _openInsights,
          ),
          _SpaceHistory(
            sections: _groupBySpace(_all, _spaces),
            onOpen: _openSession,
          ),
        ],
      ),
    );
  }

  Map<SpaceModel?, List<ChatSessionModel>> _groupBySpace(
    List<ChatSessionModel> sessions,
    List<SpaceModel> spaces,
  ) {
    final byId = {for (final s in spaces) s.id: s};
    final map = <SpaceModel?, List<ChatSessionModel>>{};
    for (final s in sessions) {
      final sp = s.spaceId == null ? null : byId[s.spaceId!];
      map.putIfAbsent(sp, () => []).add(s);
    }
    return map;
  }

  void _openSession(ChatSessionModel s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(sessionId: s.id, title: s.title),
      ),
    );
  }

  Future<void> _deleteSession(ChatSessionModel s) async {
    final ok = await _confirm(
      'Delete conversation?',
      'This will permanently remove the conversation.',
    );
    if (ok != true) return;
    await DBProvider.of(context).deleteChatSession(s.id);
  }

  Future<void> _createMemory() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New memory'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(hintText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(hintText: 'Details'),
              minLines: 3,
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final now = DateTime.now();
      final mem = MemoryItemModel(
        id: 'mem_${now.microsecondsSinceEpoch}',
        title: titleCtrl.text.trim().isEmpty
            ? 'Memory ${now.toIso8601String()}'
            : titleCtrl.text.trim(),
        content: contentCtrl.text.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await DBProvider.of(context).upsertMemory(mem);
    }
  }

  Future<void> _deleteMemory(MemoryItemModel m) async {
    final ok = await _confirm(
      'Delete memory?',
      'This will permanently remove the memory.',
    );
    if (ok != true) return;
    await DBProvider.of(context).deleteMemory(m.id);
  }

  Future<void> _analyzeOne(ChatSessionModel s) async {
    final db = DBProvider.of(context);
    final session = db.getChatSession(s.id) ?? s;
    final idx = MemoryBuilder.buildIndex(session);
    await db.upsertMemoryIndex(idx);
  }

  Future<void> _analyzeAll() async {
    for (final s in _all) {
      await _analyzeOne(s);
    }
  }

  void _openInsights(ChatSessionModel s) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MemoryInsightsPage(sessionId: s.id)),
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  }
}

class _AllChatsList extends StatelessWidget {
  const _AllChatsList({
    required this.sessions,
    required this.onOpen,
    required this.onDelete,
  });
  final List<ChatSessionModel> sessions;
  final void Function(ChatSessionModel) onOpen;
  final Future<void> Function(ChatSessionModel) onDelete;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const Center(child: Text('No conversations yet'));
    }
    return ListView.separated(
      itemCount: sessions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = sessions[i];
        return ListTile(
          leading: s.spaceId != null
              ? const Icon(Icons.folder_open, size: 20)
              : const Icon(Icons.chat_bubble_outline, size: 20),
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
            style: const TextStyle(color: Color(0xFF71767B), fontSize: 12),
          ),
          onTap: () => onOpen(s),
          onLongPress: () => onDelete(s),
        );
      },
    );
  }
}

class _MemoryList extends StatelessWidget {
  const _MemoryList({
    required this.items,
    required this.onCreate,
    required this.onDelete,
    required this.sessions,
    required this.memoryIndex,
    required this.onAnalyzeOne,
    required this.onAnalyzeAll,
    required this.onOpenInsights,
  });
  final List<MemoryItemModel> items;
  final VoidCallback onCreate;
  final Future<void> Function(MemoryItemModel) onDelete;
  final List<ChatSessionModel> sessions;
  final Map<String, MemoryIndexModel> memoryIndex;
  final Future<void> Function(ChatSessionModel) onAnalyzeOne;
  final Future<void> Function() onAnalyzeAll;
  final void Function(ChatSessionModel) onOpenInsights;

  @override
  Widget build(BuildContext context) {
    final analyzed = <ChatSessionModel>[];
    final pending = <ChatSessionModel>[];
    for (final s in sessions) {
      if (memoryIndex.containsKey(s.id)) {
        analyzed.add(s);
      } else {
        pending.add(s);
      }
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              const Text(
                'Memories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (items.isEmpty)
          const ListTile(
            title: Text('No memories yet'),
            subtitle: Text('Save key facts or prompts here'),
          )
        else
          ...items.map(
            (m) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bookmark_border),
                  title: Text(
                    m.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    m.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    _fmtTime(m.updatedAt),
                    style: const TextStyle(
                      color: Color(0xFF71767B),
                      fontSize: 12,
                    ),
                  ),
                  onLongPress: () => onDelete(m),
                ),
                const Divider(height: 1),
              ],
            ),
          ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Session insights',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onAnalyzeAll,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Analyze all'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        if (sessions.isEmpty)
          const ListTile(title: Text('No sessions yet'))
        else ...[
          if (pending.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: const Text(
                'Needs analysis',
                style: TextStyle(color: Color(0xFF71767B)),
              ),
            ),
          ...pending.map(
            (s) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pending_outlined),
                  title: Text(
                    s.title.isEmpty ? 'Untitled chat' : s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${s.model} · ${s.messageCount} messages',
                    maxLines: 1,
                  ),
                  trailing: TextButton(
                    onPressed: () => onAnalyzeOne(s),
                    child: const Text('Analyze'),
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          if (analyzed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: const Text(
                'Ready',
                style: TextStyle(color: Color(0xFF71767B)),
              ),
            ),
          ...analyzed.map(
            (s) => Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: Text(
                    s.title.isEmpty ? 'Untitled chat' : s.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Builder(
                    builder: (context) {
                      final idx = memoryIndex[s.id];
                      final summary = idx?.sessionSummary;
                      final tags = idx?.sessionHashtags ?? const [];
                      final tagStr = tags.take(4).join('  ');
                      final base = '${s.model} · ${s.messageCount} messages';
                      final extra = [
                        if (summary != null && summary.isNotEmpty) summary,
                        if (tagStr.isNotEmpty) tagStr,
                      ].join('\n');
                      return Text(
                        extra.isEmpty ? base : '$base\n$extra',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenInsights(s),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SpaceHistory extends StatelessWidget {
  const _SpaceHistory({required this.sections, required this.onOpen});
  final Map<SpaceModel?, List<ChatSessionModel>> sections;
  final void Function(ChatSessionModel) onOpen;

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) {
      return const Center(child: Text('No space chats yet'));
    }
    final orderedKeys = sections.keys.toList()
      ..sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return 1;
        if (b == null) return -1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return ListView.builder(
      itemCount: orderedKeys.length,
      itemBuilder: (context, idx) {
        final key = orderedKeys[idx];
        final group = sections[key]!
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        final title = key == null ? 'Unassigned' : key.name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (key != null) ...[
                    EmojiIcon(
                      key.emoji,
                      size: 16,
                      color: const Color(0xFF71767B),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (key != null)
                    TextButton.icon(
                      onPressed: () {
                        final db = DBProvider.of(context);
                        final combo = db.getSpaceComboHistory(key.id);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Combined history — ${key.name}'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: SingleChildScrollView(
                                child: Text(
                                  (combo?.content ?? '').isEmpty
                                      ? '(empty)'
                                      : combo!.content,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Close'),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await DBProvider.of(
                                    context,
                                  ).rebuildSpaceComboHistory(key.id);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Combined history rebuilt'),
                                    ),
                                  );
                                },
                                child: const Text('Rebuild'),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.subject, size: 16),
                      label: const Text('Combined'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...group.map(
              (s) => ListTile(
                leading: const Icon(Icons.chat_bubble_outline, size: 20),
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
                onTap: () => onOpen(s),
              ),
            ),
          ],
        );
      },
    );
  }
}

String _fmtTime(DateTime t) {
  final now = DateTime.now();
  final diff = now.difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  return '${diff.inDays}d';
}
