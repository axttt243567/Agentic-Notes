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

  Future<void> _openSuggestionSettings() async {
    final db = DBProvider.of(context);
    String selected = _suggestLevel;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: StatefulBuilder(
            builder: (context, setStateSB) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F3336),
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
                    ChoiceChip(
                      label: const Text('Suggest less'),
                      selected: selected == 'less',
                      onSelected: (_) async {
                        setStateSB(() => selected = 'less');
                        await db.setSuggestLevel('less');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Balanced'),
                      selected: selected == 'balanced',
                      onSelected: (_) async {
                        setStateSB(() => selected = 'balanced');
                        await db.setSuggestLevel('balanced');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Suggest more'),
                      selected: selected == 'more',
                      onSelected: (_) async {
                        setStateSB(() => selected = 'more');
                        await db.setSuggestLevel('more');
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
        title: const Text(
          'Spaces',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'AI chat',
            onPressed: _openChat,
            icon: const Icon(Icons.auto_awesome),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InputChip(
                label: Text(
                  name.isEmpty ? 'me' : name,
                  style: const TextStyle(color: Color(0xFF71767B)),
                ),
                shape: const StadiumBorder(),
                backgroundColor: Color(0xFF0A0A0A),
                side: const BorderSide(color: Color(0xFF2F3336)),
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
                      color: Color(0xFF71767B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0A0A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2F3336)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _spaces.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFF2F3336),
                        indent: 64,
                      ),
                      itemBuilder: (context, i) {
                        final s = _spaces[i];
                        return _SpaceRow(
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
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 18,
                  color: Color(0xFF71767B),
                ),
                const SizedBox(width: 6),
                Text(
                  'Smart suggestions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (suggestions.isEmpty)
              const Text(
                'No suggestions yet. Add some spaces to get started.',
                style: TextStyle(color: Color(0xFF71767B)),
              )
            else
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: suggestions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final s = suggestions[i];
                    return _SuggestionCardX(
                      icon: s.icon,
                      text: s.text,
                      onTap: s.onTap,
                    );
                  },
                ),
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
          icon: Icons.auto_awesome,
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

class _SpaceRow extends StatelessWidget {
  const _SpaceRow({
    required this.space,
    required this.onOpen,
    required this.onDelete,
  });
  final SpaceModel space;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onOpen,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2F3336)),
        ),
        child: Center(
          child: Text(space.emoji, style: const TextStyle(fontSize: 20)),
        ),
      ),
      title: Text(
        space.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: const Text(
        '0 notes · 0 resources',
        style: TextStyle(color: Color(0xFF71767B), fontSize: 12),
      ),
      trailing: PopupMenuButton<String>(
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'rename', child: Text('Rename')),
          PopupMenuItem(value: 'delete', child: Text('Delete')),
        ],
        onSelected: (v) {
          if (v == 'delete') onDelete();
          if (v == 'rename') {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rename (UI only)')));
          }
        },
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }
}

class _SuggestionCardX extends StatelessWidget {
  const _SuggestionCardX({
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
        width: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2F3336)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF71767B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Color(0xFF1D9BF0),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Color(0xFF1D9BF0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          const Icon(Icons.auto_awesome, size: 44, color: Color(0xFF71767B)),
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
            style: TextStyle(color: Color(0xFF71767B)),
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
                  backgroundColor: Color(0xFF0A0A0A),
                  side: const BorderSide(color: Color(0xFF2F3336)),
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
                  color: const Color(0xFF2F3336),
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
