import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Home page showing user "Spaces" (e.g., Physics, Math, CS) with a front-end only flow
/// to create/edit spaces and add placeholder resources.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<NoteSpace> _spaces = [
    NoteSpace.sample(
      name: 'Physics',
      emoji: '🧪',
      color: const Color(0xFF7B61FF),
      description: 'Mechanics, EM, Quantum…',
      samples: [
        SpaceResource(title: 'Kinematics Notes', type: ResourceType.note),
        SpaceResource(title: 'EM Waves PDF', type: ResourceType.pdf),
        SpaceResource(
          title: 'Veritasium: Gravity',
          type: ResourceType.video,
          url: 'https://youtu.be/XYZ',
        ),
      ],
    ),
    NoteSpace.sample(
      name: 'Data Structures',
      emoji: '🧩',
      color: const Color(0xFF50C878), // emerald
      description: 'Arrays, Trees, Graphs, Heaps',
      samples: [
        SpaceResource(title: 'Trees basics', type: ResourceType.note),
        SpaceResource(title: 'Graph Traversals PDF', type: ResourceType.pdf),
      ],
    ),
    NoteSpace.sample(
      name: 'Algorithms',
      emoji: '⚙️',
      color: const Color(0xFF00BFA6), // teal
      description: 'Sorting, DP, Greedy, Backtracking',
      samples: [
        SpaceResource(
          title: 'Dynamic Programming intro',
          type: ResourceType.note,
        ),
        SpaceResource(title: 'CLRS Chapter Notes', type: ResourceType.pdf),
      ],
    ),
    NoteSpace.sample(
      name: 'Machine Learning',
      emoji: '🤖',
      color: const Color(0xFFFF6F61), // coral
      description: 'Models, Training, Evaluation',
      samples: [
        SpaceResource(
          title: 'Overfitting vs. Underfitting',
          type: ResourceType.note,
        ),
        SpaceResource(
          title: 'Andrew Ng videos',
          type: ResourceType.link,
          url: 'https://www.youtube.com/machinelearning',
        ),
      ],
    ),
    NoteSpace.sample(
      name: 'Deep Learning',
      emoji: '🧠',
      color: const Color(0xFF9B59B6), // amethyst
      description: 'CNNs, RNNs, Transformers',
      samples: [
        SpaceResource(
          title: 'Attention is all you need (summary)',
          type: ResourceType.note,
        ),
        SpaceResource(title: 'ResNet paper PDF', type: ResourceType.pdf),
      ],
    ),
    NoteSpace.sample(
      name: 'Web Dev',
      emoji: '🌐',
      color: const Color(0xFF3498DB), // blue
      description: 'Frontend, Backend, APIs',
      samples: [
        SpaceResource(title: 'HTTP essentials', type: ResourceType.note),
        SpaceResource(
          title: 'MDN: Fetch Guide',
          type: ResourceType.link,
          url: 'https://developer.mozilla.org/',
        ),
      ],
    ),
    NoteSpace.sample(
      name: 'System Design',
      emoji: '🏗️',
      color: const Color(0xFF2ECC71), // green
      description: 'Scalability, Caching, Sharding',
      samples: [
        SpaceResource(title: 'CAP Theorem', type: ResourceType.note),
        SpaceResource(title: 'Load Balancing intro', type: ResourceType.note),
      ],
    ),
    NoteSpace.sample(
      name: 'Databases',
      emoji: '🗄️',
      color: const Color(0xFFF39C12), // amber
      description: 'SQL, NoSQL, Indexing',
      samples: [
        SpaceResource(title: 'Indexes explained', type: ResourceType.note),
        SpaceResource(title: 'Normalization PDF', type: ResourceType.pdf),
      ],
    ),
    NoteSpace.sample(
      name: 'Operating Systems',
      emoji: '🧵',
      color: const Color(0xFF1ABC9C), // turquoise
      description: 'Processes, Threads, Memory',
      samples: [
        SpaceResource(title: 'Threads vs Processes', type: ResourceType.note),
        SpaceResource(
          title: 'Virtual Memory overview',
          type: ResourceType.note,
        ),
      ],
    ),
    NoteSpace.sample(
      name: 'Networks',
      emoji: '📡',
      color: const Color(0xFF16A085), // deep teal
      description: 'TCP/IP, Routing, DNS',
      samples: [
        SpaceResource(title: 'TCP handshake', type: ResourceType.note),
        SpaceResource(title: 'OSI layers PDF', type: ResourceType.pdf),
      ],
    ),
    NoteSpace.sample(
      name: 'Cyber Security',
      emoji: '🛡️',
      color: const Color(0xFFE74C3C), // red
      description: 'Auth, Threats, Best Practices',
      samples: [
        SpaceResource(
          title: 'OWASP Top 10',
          type: ResourceType.link,
          url: 'https://owasp.org/www-project-top-ten/',
        ),
        SpaceResource(title: 'Encryption basics', type: ResourceType.note),
      ],
    ),
    NoteSpace.sample(
      name: 'Mathematics',
      emoji: '📐',
      color: const Color(0xFF00D4FF),
      description: 'Algebra, Calculus, Number Theory',
      samples: [
        SpaceResource(title: 'Derivatives Cheatsheet', type: ResourceType.pdf),
        SpaceResource(title: 'Integration Tricks', type: ResourceType.note),
        SpaceResource(
          title: '3Blue1Brown Playlist',
          type: ResourceType.link,
          url: 'https://www.youtube.com/@3blue1brown',
        ),
      ],
    ),
    NoteSpace.sample(
      name: 'C Programming',
      emoji: '💻',
      color: const Color(0xFFFF8A00),
      description: 'Syntax, Pointers, Memory, DS & Algos',
      samples: [
        SpaceResource(title: 'C Pointers Deep Dive', type: ResourceType.note),
        SpaceResource(title: 'ANSI C PDF', type: ResourceType.pdf),
        SpaceResource(
          title: 'YT: CS50 C Lectures',
          type: ResourceType.video,
          url: 'https://youtube.com/cs50',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _createOrEditSpace({NoteSpace? existing}) async {
    final created = await showModalBottomSheet<NoteSpace>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CreateSpaceSheet(initial: existing),
    );
    if (!mounted || created == null) return;

    setState(() {
      if (existing == null) {
        _spaces.add(created);
      } else {
        final idx = _spaces.indexWhere((s) => s.id == existing.id);
        if (idx != -1) {
          _spaces[idx] = created.copyWith(resources: existing.resources);
        }
      }
    });
  }

  void _openSpace(NoteSpace space) async {
    final updated = await Navigator.of(context).push<NoteSpace>(
      MaterialPageRoute(builder: (_) => SpaceDetailsPage(space: space)),
    );
    if (!mounted || updated == null) return;
    setState(() {
      final idx = _spaces.indexWhere((s) => s.id == updated.id);
      if (idx != -1) _spaces[idx] = updated;
    });
  }

  void _openProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _spaces
        .where((s) => s.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Spaces',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: InputChip(
                label: const Text(
                  'me',
                  style: TextStyle(color: Colors.white70),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createOrEditSpace(),
        icon: const Icon(Icons.add),
        label: const Text('New space'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            int crossAxisCount = 2;
            if (width > 1000) {
              crossAxisCount = 4;
            } else if (width > 700) {
              crossAxisCount = 3;
            }

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _SearchBar(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(top: 12)),
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _EmptyState(onCreate: () => _createOrEditSpace()),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final space = filtered[i];
                        return _SpaceCard(
                          space: space,
                          onOpen: () => _openSpace(space),
                          onEdit: () => _createOrEditSpace(existing: space),
                          onDelete: () {
                            setState(
                              () =>
                                  _spaces.removeWhere((s) => s.id == space.id),
                            );
                          },
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search spaces…',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.close)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.space,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final NoteSpace space;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = Border.all(color: Colors.white10);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        space.color.withValues(alpha: 0.25),
        Colors.white.withValues(alpha: 0.03),
      ],
    );
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          border: border,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _EmojiBadge(emoji: space.emoji, color: space.color),
                const Spacer(),
                PopupMenuButton<String>(
                  color: theme.colorScheme.surface,
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'open', child: Text('Open')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                  onSelected: (v) {
                    switch (v) {
                      case 'open':
                        onOpen();
                        break;
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              space.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (space.description?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                space.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
            const Spacer(),
            SizedBox(
              height: 36,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _StatChip(
                      icon: Icons.note_alt_outlined,
                      label: 'Notes',
                      count: space.count(ResourceType.note),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'PDFs',
                      count: space.count(ResourceType.pdf),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.link_outlined,
                      label: 'Links',
                      count: space.count(ResourceType.link),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      icon: Icons.play_circle_outline,
                      label: 'Videos',
                      count: space.count(ResourceType.video),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
  });
  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text('$count $label', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white12),
              ),
              child: const Center(
                child: Icon(
                  Icons.space_dashboard_outlined,
                  size: 42,
                  color: Colors.white54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first space',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Group notes, PDFs, videos, and links in one place.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('New space'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmojiBadge extends StatelessWidget {
  const _EmojiBadge({required this.emoji, required this.color});
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _CreateSpaceSheet extends StatefulWidget {
  const _CreateSpaceSheet({this.initial});
  final NoteSpace? initial;

  @override
  State<_CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends State<_CreateSpaceSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _emoji = '📚';
  Color _color = const Color(0xFF7B61FF);

  static const _colorOptions = <Color>[
    Color(0xFF7B61FF),
    Color(0xFFFF8A00),
    Color(0xFF00D4FF),
    Color(0xFF00E676),
    Color(0xFFFF5C93),
    Color(0xFFFFC107),
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initial?.name ?? '');
    _descCtrl = TextEditingController(text: widget.initial?.description ?? '');
    _emoji = widget.initial?.emoji ?? _emoji;
    _color = widget.initial?.color ?? _color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final isEditing = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
              isEditing ? 'Edit space' : 'Create space',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _EmojiPicker(
                  value: _emoji,
                  onChanged: (e) => setState(() => _emoji = e),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: _roundedInputDecoration(
                      'Space name',
                      hint: 'e.g. C Programming',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              minLines: 2,
              decoration: _roundedInputDecoration(
                'Description',
                hint: 'Add a short summary…',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Color',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _colorOptions)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == c ? Colors.white : Colors.white24,
                          width: _color == c ? 2 : 1,
                        ),
                      ),
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
                FilledButton(
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a space name.'),
                        ),
                      );
                      return;
                    }
                    final created =
                        (widget.initial ??
                                NoteSpace.newSpace(
                                  name: name,
                                  emoji: _emoji,
                                  color: _color,
                                  description: _descCtrl.text.trim().isEmpty
                                      ? null
                                      : _descCtrl.text.trim(),
                                ))
                            .copyWith(
                              name: name,
                              emoji: _emoji,
                              color: _color,
                              description: _descCtrl.text.trim().isEmpty
                                  ? null
                                  : _descCtrl.text.trim(),
                            );
                    Navigator.of(context).pop(created);
                  },
                  child: Text(isEditing ? 'Save' : 'Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _roundedInputDecoration(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
}

class _EmojiPicker extends StatefulWidget {
  const _EmojiPicker({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_EmojiPicker> createState() => _EmojiPickerState();
}

class _EmojiPickerState extends State<_EmojiPicker> {
  static const _emojis = [
    '📚',
    '🧪',
    '📐',
    '💻',
    '📝',
    '🔬',
    '🧠',
    '📊',
    '🔗',
    '🎥',
  ];
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: _current,
      onSelected: (v) {
        setState(() => _current = v);
        widget.onChanged(v);
      },
      itemBuilder: (context) => _emojis
          .map(
            (e) => PopupMenuItem<String>(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 18)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(_current, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}

// Models and details page (front-end only)

enum ResourceType { note, pdf, link, video }

@immutable
class SpaceResource {
  final String id;
  final String title;
  final ResourceType type;
  final String? url; // for link/video; optional for pdf placeholder

  SpaceResource({String? id, required this.title, required this.type, this.url})
    : id = id ?? _rid();
}

String _rid() =>
    '${DateTime.now().millisecondsSinceEpoch}-${math.Random().nextInt(1 << 32)}';

@immutable
class NoteSpace {
  final String id;
  final String name;
  final String emoji;
  final Color color;
  final String? description;
  final List<SpaceResource> resources;

  NoteSpace({
    String? id,
    required this.name,
    required this.emoji,
    required this.color,
    this.description,
    this.resources = const [],
  }) : id = id ?? _rid();

  factory NoteSpace.newSpace({
    required String name,
    required String emoji,
    required Color color,
    String? description,
  }) => NoteSpace(
    name: name,
    emoji: emoji,
    color: color,
    description: description,
    resources: const [],
  );

  factory NoteSpace.sample({
    required String name,
    required String emoji,
    required Color color,
    String? description,
    List<SpaceResource> samples = const [],
  }) => NoteSpace(
    name: name,
    emoji: emoji,
    color: color,
    description: description,
    resources: samples,
  );

  NoteSpace copyWith({
    String? id,
    String? name,
    String? emoji,
    Color? color,
    Object? description = _sentinel,
    List<SpaceResource>? resources,
  }) {
    return NoteSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      color: color ?? this.color,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      resources: resources ?? this.resources,
    );
  }

  int count(ResourceType t) => resources.where((r) => r.type == t).length;
}

const _sentinel = Object();

class SpaceDetailsPage extends StatefulWidget {
  const SpaceDetailsPage({super.key, required this.space});
  final NoteSpace space;

  @override
  State<SpaceDetailsPage> createState() => _SpaceDetailsPageState();
}

class _SpaceDetailsPageState extends State<SpaceDetailsPage>
    with SingleTickerProviderStateMixin {
  late NoteSpace _space;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _space = widget.space;
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _addResource() async {
    final added = await showModalBottomSheet<SpaceResource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddResourceSheet(),
    );
    if (added == null) return;
    setState(() {
      _space = _space.copyWith(resources: [..._space.resources, added]);
    });
  }

  // Pop with updated space when navigating back
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(_space);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              _EmojiBadge(emoji: _space.emoji, color: _space.color),
              const SizedBox(width: 10),
              Text(
                _space.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Add resource',
              onPressed: _addResource,
              icon: const Icon(Icons.add_circle_outline),
            ),
            PopupMenuButton<String>(
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'color', child: Text('Change color')),
              ],
              onSelected: (v) {
                switch (v) {
                  case 'rename':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rename (UI only)')),
                    );
                  case 'color':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Change color (UI only)')),
                    );
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Notes'),
              Tab(text: 'Resources'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addResource,
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          controller: _tab,
          children: [
            _NotesTab(space: _space),
            _ResourcesTab(
              space: _space,
              onRemove: (id) {
                setState(
                  () => _space = _space.copyWith(
                    resources: _space.resources
                        .where((r) => r.id != id)
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.space});
  final NoteSpace space;

  @override
  Widget build(BuildContext context) {
    // Placeholder list of generated notes (front-end only)
    final notes = space.resources
        .where((r) => r.type == ResourceType.note)
        .toList();
    if (notes.isEmpty) {
      return const _TabEmptyState(
        icon: Icons.note_alt_outlined,
        title: 'No notes yet',
        subtitle: 'Generate or add notes to see them here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: notes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final n = notes[i];
        return _ResourceTile(
          resource: n,
          trailing: const Icon(Icons.chevron_right),
        );
      },
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.space, required this.onRemove});
  final NoteSpace space;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (space.resources.isEmpty) {
      return const _TabEmptyState(
        icon: Icons.folder_open,
        title: 'No resources yet',
        subtitle: 'Add PDFs, links, and videos to your space.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: space.resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = space.resources[i];
        return _ResourceTile(
          resource: r,
          trailing: IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => onRemove(r.id),
          ),
        );
      },
    );
  }
}

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({required this.resource, this.trailing});
  final SpaceResource resource;
  final Widget? trailing;

  IconData get _icon {
    switch (resource.type) {
      case ResourceType.note:
        return Icons.note_alt_outlined;
      case ResourceType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ResourceType.link:
        return Icons.link_outlined;
      case ResourceType.video:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: Icon(_icon, color: Colors.white70),
        title: Text(resource.title),
        subtitle: resource.url == null
            ? null
            : Text(
                resource.url!,
                style: const TextStyle(color: Colors.white70),
              ),
        trailing: trailing,
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Open (UI only)')));
        },
      ),
    );
  }
}

class _TabEmptyState extends StatelessWidget {
  const _TabEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: Colors.white60),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _AddResourceSheet extends StatefulWidget {
  const _AddResourceSheet();

  @override
  State<_AddResourceSheet> createState() => _AddResourceSheetState();
}

class _AddResourceSheetState extends State<_AddResourceSheet> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _urlCtrl = TextEditingController();
  ResourceType _type = ResourceType.note;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
              'Add resource',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final t in ResourceType.values)
                  ChoiceChip(
                    label: Text(_typeLabel(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: _roundedInput('Title', hint: 'e.g. CS50 Lecture 1'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            if (_type != ResourceType.note)
              TextField(
                controller: _urlCtrl,
                decoration: _roundedInput(
                  'URL',
                  hint: _type == ResourceType.pdf ? 'Link to PDF' : 'https://…',
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final title = _titleCtrl.text.trim();
                    if (title.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title.')),
                      );
                      return;
                    }
                    final url = _urlCtrl.text.trim().isEmpty
                        ? null
                        : _urlCtrl.text.trim();
                    Navigator.of(
                      context,
                    ).pop(SpaceResource(title: title, type: _type, url: url));
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(ResourceType t) {
    switch (t) {
      case ResourceType.note:
        return 'Note';
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.link:
        return 'Link';
      case ResourceType.video:
        return 'Video';
    }
  }

  InputDecoration _roundedInput(String label, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white),
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      );
}

// Profile bottom sheet with many useful options for a profile page
class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  final TextEditingController _nameCtrl = TextEditingController(text: 'You');
  final TextEditingController _apiKeyCtrl = TextEditingController();
  bool _hideApiKey = true;
  bool _useDynamicColor = true;
  bool _compactCards = false;
  bool _enableHaptics = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Material(
            color: theme.colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(child: _grabber()),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverList.list(
                    children: [
                      Text(
                        'Profile',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _section(
                        title: 'Account',
                        children: [
                          _tile(
                            leading: const CircleAvatar(
                              radius: 16,
                              child: Text('👤', style: TextStyle(fontSize: 18)),
                            ),
                            title: 'Display name',
                            subtitle: 'Used across your spaces',
                            trailing: SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  hintText: 'Your name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _tile(
                            leading: const Icon(Icons.alternate_email),
                            title: 'Username',
                            subtitle: '@you (local only)',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'AI API',
                        children: [
                          _tile(
                            leading: const Icon(Icons.vpn_key_outlined),
                            title: 'API key',
                            subtitle: _apiKeyCtrl.text.isEmpty
                                ? 'Not set'
                                : _hideApiKey
                                ? '••••••••••••'
                                : _apiKeyCtrl.text,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: _hideApiKey ? 'Show' : 'Hide',
                                  onPressed: () => setState(
                                    () => _hideApiKey = !_hideApiKey,
                                  ),
                                  icon: Icon(
                                    _hideApiKey
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Copy',
                                  onPressed: _apiKeyCtrl.text.isEmpty
                                      ? null
                                      : () {
                                          Clipboard.setData(
                                            ClipboardData(
                                              text: _apiKeyCtrl.text,
                                            ),
                                          );
                                          _snack(context, 'API key copied');
                                        },
                                  icon: const Icon(Icons.copy_all_outlined),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final key = await _editText(
                                      context,
                                      title: 'Set API key',
                                      initial: _apiKeyCtrl.text,
                                      isSecret: true,
                                    );
                                    if (key == null) return;
                                    if (!mounted) return;
                                    setState(() => _apiKeyCtrl.text = key);
                                  },
                                  child: const Text('Set'),
                                ),
                              ],
                            ),
                          ),
                          _tile(
                            leading: const Icon(Icons.swap_horiz_outlined),
                            title: 'Provider',
                            subtitle: 'OpenAI / Anthropic / Local',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.memory_outlined),
                            title: 'Model',
                            subtitle: 'gpt-4o-mini (example)',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Preferences',
                        children: [
                          SwitchListTile.adaptive(
                            value: _useDynamicColor,
                            onChanged: (v) =>
                                setState(() => _useDynamicColor = v),
                            title: const Text('Use dynamic color'),
                            subtitle: const Text('Blend UI with system colors'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile.adaptive(
                            value: _compactCards,
                            onChanged: (v) => setState(() => _compactCards = v),
                            title: const Text('Compact cards'),
                            subtitle: const Text('Show denser space cards'),
                            contentPadding: EdgeInsets.zero,
                          ),
                          SwitchListTile.adaptive(
                            value: _enableHaptics,
                            onChanged: (v) =>
                                setState(() => _enableHaptics = v),
                            title: const Text('Enable haptics'),
                            subtitle: const Text(
                              'Vibration feedback on actions',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Security',
                        children: [
                          _tile(
                            leading: const Icon(Icons.lock_outline),
                            title: 'App lock',
                            subtitle: 'PIN/biometrics (coming soon)',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.fingerprint),
                            title: 'Biometric unlock',
                            subtitle: 'Use device biometrics',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Data',
                        children: [
                          _tile(
                            leading: const Icon(Icons.backup_outlined),
                            title: 'Backup & restore',
                            subtitle: 'Export or import spaces',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.storage_outlined),
                            title: 'Storage',
                            subtitle: 'Clear caches, manage space',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.delete_outline),
                            title: 'Delete all data',
                            subtitle: 'Remove all local content',
                            onTap: () => _confirm(context, 'Delete all data?'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'Integrations',
                        children: [
                          _tile(
                            leading: const Icon(Icons.link_outlined),
                            title: 'Web clipper',
                            subtitle: 'Save links from browser',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.picture_as_pdf_outlined),
                            title: 'PDF reader',
                            subtitle: 'Open and annotate PDFs',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _section(
                        title: 'About',
                        children: [
                          _tile(
                            leading: const Icon(Icons.info_outline),
                            title: 'Version',
                            subtitle: 'Agentic Notes (UI demo)',
                          ),
                          _tile(
                            leading: const Icon(Icons.description_outlined),
                            title: 'Privacy & terms',
                            onTap: _showComingSoon,
                          ),
                          _tile(
                            leading: const Icon(Icons.help_outline),
                            title: 'Help & feedback',
                            onTap: _showComingSoon,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _grabber() => Center(
    child: Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );

  Widget _section({required String title, required List<Widget> children}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 10),
        ...children,
      ],
    );
  }

  Widget _tile({
    Widget? leading,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: ListTile(
        leading: leading,
        title: Text(title),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: const TextStyle(color: Colors.white70)),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showComingSoon() {
    _snack(context, 'Coming soon (UI only)');
  }

  Future<String?> _editText(
    BuildContext context, {
    required String title,
    String? initial,
    bool isSecret = false,
  }) async {
    final ctrl = TextEditingController(text: initial ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: ctrl,
            obscureText: isSecret,
            decoration: const InputDecoration(hintText: 'Enter value'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    return res == null || res.isEmpty ? null : res;
  }

  Future<void> _confirm(BuildContext context, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
    if (ok == true) {
      // Intentionally avoid using context after await to satisfy analyzer.
      // In a real app, handle the action result here.
    }
  }
}
