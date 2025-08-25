import 'package:flutter/material.dart';
import 'widgets/profile_sheet.dart';
import 'main.dart';
import 'chat_page.dart';
import 'space_page.dart';
import 'data/models.dart';
import 'dart:async';

/// Home page: minimal shell with a profile button.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<SpaceModel> _spaces = [];
  StreamSubscription? _spacesSub;
  String _suggestLevel = 'balanced';
  StreamSubscription? _suggestSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spacesSub?.cancel();
    _suggestSub?.cancel();
    final db = DBProvider.of(context);
    _spaces
      ..clear()
      ..addAll(db.currentSpaces);
    _suggestLevel = db.currentSuggestLevel;
    _spacesSub = db.spacesStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _spaces
          ..clear()
          ..addAll(list);
      });
    });
    _suggestSub = db.suggestLevelStream.listen((level) {
      if (!mounted) return;
      setState(() => _suggestLevel = level);
    });
  }

  @override
  void dispose() {
    _spacesSub?.cancel();
    _suggestSub?.cancel();
    super.dispose();
  }

  void _openProfile() async {
    final res = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const ProfileSheet(),
    );
    if (!mounted) return;
    if (res == 'open_suggestions') {
      _openSuggestionSettings();
    }
  }

  void _openChat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  }

  Future<void> _addSpace() async {
    final db = DBProvider.of(context);
    final created = await showModalBottomSheet<SpaceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddSpaceSheet(),
    );
    if (created == null) return;
    await db.upsertSpace(created);
  }

  void _quickCreateSpace(String emoji, String name) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final db = DBProvider.of(context);
    db.upsertSpace(SpaceModel(id: id, name: name, emoji: emoji));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Created $name')));
  }

  @override
  Widget build(BuildContext context) {
    final db = DBProvider.of(context);
    final name = db.currentProfile.displayName;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text('Spaces'),
        actions: [
          IconButton(
            tooltip: 'AI chat',
            onPressed: _openChat,
            icon: const Icon(Icons.star_border),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InputChip(
                label: Text(
                  name.isEmpty ? 'me' : name,
                  style: const TextStyle(color: Colors.white70),
                ),
                shape: const StadiumBorder(),
                backgroundColor: Colors.white10,
                side: const BorderSide(color: Colors.white12),
                onPressed: _openProfile,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _spaces.isEmpty
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                child: Center(
                  child: _EmptyState(
                    onCreate: _addSpace,
                    onQuickCreate: _quickCreateSpace,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                children: [
                  _smartSuggestionsSection(context),
                  const SizedBox(height: 12),
                  Text(
                    'Your spaces',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.2,
                        ),
                    itemCount: _spaces.length,
                    itemBuilder: (context, i) {
                      final s = _spaces[i];
                      return _SpaceCard(
                        space: s,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpacePage(
                              spaceId: s.id,
                              name: s.name,
                              emoji: s.emoji,
                            ),
                          ),
                        ),
                        onDelete: () =>
                            DBProvider.of(context).deleteSpace(s.id),
                      );
                    },
                  ),
                ],
              ),
      ),
      // Space creation has moved to Profile sheet; FAB removed.
    );
  }

  Widget _smartSuggestionsSection(BuildContext context) {
    final suggestions = _buildSuggestions();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  'Smart suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (suggestions.isEmpty)
              const Text(
                'No suggestions yet. Add some spaces to get started.',
                style: TextStyle(color: Colors.white70),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: suggestions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.9,
                ),
                itemBuilder: (context, i) {
                  final s = suggestions[i];
                  return _SuggestionCard(
                    icon: s.icon,
                    text: s.text,
                    onTap: s.onTap,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<_Suggestion> _buildSuggestions() {
    if (_spaces.isEmpty) return const [];
    final items = <_Suggestion>[];
    void addQuickTest(SpaceModel sp) {
      items.add(
        _Suggestion(
          icon: Icons.flash_on_outlined,
          text: 'Quick test from ${sp.name} space',
          actionLabel: 'Start',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SpacePage(spaceId: sp.id, name: sp.name, emoji: sp.emoji),
              ),
            );
          },
        ),
      );
    }

    void addExamWarn(SpaceModel sp) {
      items.add(
        _Suggestion(
          icon: Icons.warning_amber_rounded,
          text: 'Exam prep reminder from ${sp.name} space',
          actionLabel: 'Review',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SpacePage(spaceId: sp.id, name: sp.name, emoji: sp.emoji),
              ),
            );
          },
        ),
      );
    }

    void addAiChat(SpaceModel sp) {
      items.add(
        _Suggestion(
          icon: Icons.star_border,
          text: 'Chat with AI about ${sp.name}',
          actionLabel: 'Open',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(title: 'AI · ${sp.name}'),
              ),
            );
          },
        ),
      );
    }

    void addReviewNotes(SpaceModel sp) {
      items.add(
        _Suggestion(
          icon: Icons.notes_outlined,
          text: 'Review notes in ${sp.name} space',
          actionLabel: 'Open',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SpacePage(spaceId: sp.id, name: sp.name, emoji: sp.emoji),
              ),
            );
          },
        ),
      );
    }

    // Build from spaces in round-robin fashion
    for (final sp in _spaces) {
      addQuickTest(sp);
      addExamWarn(sp);
      addAiChat(sp);
      addReviewNotes(sp);
    }

    // Limit based on suggestion level
    final limit = _suggestLevel == 'less'
        ? 2
        : _suggestLevel == 'more'
        ? 8
        : 4; // balanced
    return items.take(limit).toList(growable: false);
  }

  void _openSuggestionSettings() async {
    final db = DBProvider.of(context);
    final levels = const ['less', 'balanced', 'more'];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String selected = _suggestLevel;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Text(
                  'Manage suggestions',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                const Text('How many suggestions?'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final l in levels)
                      ChoiceChip(
                        label: Text(
                          l == 'less'
                              ? 'Suggest less'
                              : l == 'more'
                              ? 'Suggest more'
                              : 'Balanced',
                        ),
                        selected: selected == l,
                        onSelected: (_) async {
                          selected = l;
                          await db.setSuggestLevel(l);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).maybePop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Suggestion {
  final IconData icon;
  final String text;
  final String actionLabel;
  final VoidCallback onTap;
  _Suggestion({
    required this.icon,
    required this.text,
    required this.actionLabel,
    required this.onTap,
  });
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.onOpen,
    required this.onDelete,
  });
  final SpaceModel space;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(space.emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                PopupMenuButton<String>(
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'rename', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                    if (v == 'rename') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Rename (UI only)')),
                      );
                    }
                  },
                ),
              ],
            ),
            const Spacer(),
            Text(
              space.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '0 notes · 0 resources',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate, required this.onQuickCreate});
  final VoidCallback onCreate;
  final void Function(String emoji, String name) onQuickCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 44, color: Colors.white60),
          const SizedBox(height: 12),
          Text(
            'Create your first space',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Organize topics like Programming, Physics, and more.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('New space'),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final s in const [
                ['💻', 'Programming'],
                ['🧪', 'Chemistry'],
                ['🧮', 'Math'],
                ['🪐', 'Physics'],
              ])
                InputChip(
                  label: Text('${s[0]} ${s[1]}'),
                  onPressed: () {
                    onQuickCreate(s[0], s[1]);
                  },
                  shape: const StadiumBorder(),
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Colors.white12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddSpaceSheet extends StatefulWidget {
  const _AddSpaceSheet();

  @override
  State<_AddSpaceSheet> createState() => _AddSpaceSheetState();
}

class _AddSpaceSheetState extends State<_AddSpaceSheet> {
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController(text: '📚');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'New space',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _emojiCtrl,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'Emoji',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Programming',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(onPressed: _submit, child: const Text('Create')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '📚' : _emojiCtrl.text;
    if (name.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    Navigator.of(context).pop(SpaceModel(id: id, name: name, emoji: emoji));
  }
}
