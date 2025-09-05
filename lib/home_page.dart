import 'package:flutter/material.dart';
import 'widgets/profile_sheet.dart';
import 'main.dart';
import 'chat_page.dart';
import 'space_page.dart';
import 'create_space_with_ai_page.dart';
import 'data/models.dart';
import 'dart:async';
import 'widgets/emoji_icon.dart';

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
  final List<ScheduleModel> _schedules = [];
  StreamSubscription? _schedSub;
  // Removed attendance persistence per simplified design

  late DateTime _weekAnchor; // Monday of the shown week
  late DateTime _selectedDate; // selected day within the week
  final Map<String, Set<String>> _localDone = {}; // dateKey -> scheduleIds

  // Pager for week-to-week horizontal scrolling of day chips
  late PageController _weekPageController;
  static const int _weekPageCenter = 5000;
  late DateTime _weekBaseAnchor; // anchor for the center page

  @override
  void initState() {
    super.initState();
    // Initialize with a temporary controller; real base anchor is set in didChangeDependencies
    _weekPageController = PageController(initialPage: _weekPageCenter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spacesSub?.cancel();
    _suggestSub?.cancel();
    _schedSub?.cancel();
    final db = DBProvider.of(context);
    _spaces
      ..clear()
      ..addAll(db.currentSpaces);
    _spacesSub = db.spacesStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _spaces
          ..clear()
          ..addAll(list);
      });
    });
    _suggestLevel = db.currentSuggestLevel;
    _suggestSub = db.suggestLevelStream.listen((level) {
      if (!mounted) return;
      setState(() => _suggestLevel = level);
    });
    _schedules
      ..clear()
      ..addAll(db.currentSchedules);
    _schedSub = db.schedulesStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _schedules
          ..clear()
          ..addAll(list);
      });
    });
    final now = DateTime.now();
    _weekAnchor = _startOfWeek(now);
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Set base anchor for paging once we have DB/context
    _weekBaseAnchor = _weekAnchor;
  }

  @override
  void dispose() {
    _spacesSub?.cancel();
    _suggestSub?.cancel();
    _schedSub?.cancel();
    _weekPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic Notes'),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: _openNewChat,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: _spaces.isEmpty
          ? ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                _smartSuggestionsSection(context),
                const SizedBox(height: 12),
                _timelineSection(context),
                const SizedBox(height: 12),
                _EmptyState(
                  onCreate: _addSpace,
                  onQuickCreate: _quickCreateSpace,
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                _smartSuggestionsSection(context),
                const SizedBox(height: 12),
                _timelineSection(context),
                const SizedBox(height: 12),
                Text(
                  'Your spaces',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF71767B),
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
    );
  }

  Widget _timelineSection(BuildContext context) {
    // Week days (Mon..Sun) based on anchor
    final days = List.generate(7, (i) => _weekAnchor.add(Duration(days: i)));
    // Clamp selected date to the currently shown week
    if (_selectedDate.isBefore(days.first) ||
        _selectedDate.isAfter(days.last)) {
      _selectedDate = days.first;
    }

    final headerText = _isSameDate(_selectedDate, DateTime.now())
        ? "Your today's schedule"
        : "Your schedule for ${_formatPretty(_selectedDate)}";

    final dow = _selectedDate.weekday; // 1..7
    final dayItems =
        _schedules.where((s) => s.daysOfWeek.contains(dow)).toList()
          ..sort((a, b) => (a.timeOfDay ?? '').compareTo(b.timeOfDay ?? ''));

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
                const Icon(Icons.schedule, size: 18, color: Color(0xFF71767B)),
                const SizedBox(width: 6),
                Text(
                  headerText,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: PageView.builder(
                controller: _weekPageController,
                onPageChanged: (idx) {
                  final newAnchor = _weekBaseAnchor.add(
                    Duration(days: 7 * (idx - _weekPageCenter)),
                  );
                  setState(() {
                    _weekAnchor = newAnchor;
                    // Clamp selected date handled below via days-first/last
                  });
                },
                itemBuilder: (context, pageIdx) {
                  final pageAnchor = _weekBaseAnchor.add(
                    Duration(days: 7 * (pageIdx - _weekPageCenter)),
                  );
                  final pageDays = List.generate(
                    7,
                    (i) => pageAnchor.add(Duration(days: i)),
                  );
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, i) {
                      final d = pageDays[i];
                      final isSel = _isSameDate(d, _selectedDate);
                      final dayName = _weekdayLabel(d.weekday).toLowerCase();
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${d.day}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(dayName, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        selected: isSel,
                        onSelected: (_) => setState(() => _selectedDate = d),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: 7,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (dayItems.isEmpty)
              const Text(
                'No schedules for this day. Add a subject or routine.',
                style: TextStyle(color: Color(0xFF71767B)),
              )
            else
              ListView.separated(
                itemCount: dayItems.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFF2F3336),
                  indent: 48,
                ),
                itemBuilder: (context, i) {
                  final sc = dayItems[i];
                  final dateKey = _formatYMD(_selectedDate);
                  final doneSet = _localDone.putIfAbsent(
                    dateKey,
                    () => <String>{},
                  );
                  final isDone = doneSet.contains(sc.id);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0x00000000),
                      foregroundColor: const Color(0x00000000),
                      child: EmojiIcon(
                        sc.emoji,
                        size: 20,
                        color: const Color(0xFF71767B),
                      ),
                    ),
                    title: Text(
                      sc.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      [
                        _formatTimeRange(sc) ?? 'Anytime',
                        if (sc.spaceId != null)
                          () {
                            final match = _spaces.firstWhere(
                              (s) => s.id == sc.spaceId,
                              orElse: () =>
                                  SpaceModel(id: '', name: '', emoji: ''),
                            );
                            return match.id.isEmpty ? null : '· ${match.name}';
                          }(),
                        if ((sc.room ?? '').isNotEmpty) '· Room ${sc.room}',
                      ].whereType<String>().join(' '),
                      style: const TextStyle(
                        color: Color(0xFF71767B),
                        fontSize: 12,
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Done',
                      onPressed: () => setState(() {
                        if (isDone) {
                          doneSet.remove(sc.id);
                        } else {
                          doneSet.add(sc.id);
                        }
                      }),
                      icon: Icon(
                        Icons.check_circle_rounded,
                        color: isDone
                            ? const Color(0xFF00BA7C)
                            : const Color(0xFF71767B),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // App bar actions & space creation
  void _openNewChat() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatPage()));
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ProfileSheet(),
    );
  }

  Future<void> _addSpace() async {
    final created = await showModalBottomSheet<SpaceModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddSpaceSheet(),
    );
    if (created == null) return;
    await DBProvider.of(context).upsertSpace(created);
  }

  Future<void> _quickCreateSpace(String emoji, String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final model = SpaceModel(id: id, name: name, emoji: emoji);
    await DBProvider.of(context).upsertSpace(model);
  }

  // Helpers for weekly timeline
  DateTime _startOfWeek(DateTime d) {
    final base = DateTime(d.year, d.month, d.day);
    return base.subtract(Duration(days: base.weekday - 1));
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Removed attendance-based progress computation per request (no persistence for now)

  String _formatPretty(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${_weekdayLabel(d.weekday)}, ${months[d.month - 1]} ${d.day}';
  }

  String _weekdayLabel(int d) {
    switch (d) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return d.toString();
    }
  }

  // Removed attendance summary per request (no historical progress display)

  // Removed: add-schedule entry from header per new design

  // Removed persistence of per-item progress; Done state is kept only in-memory for UI.

  String _formatYMD(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  String? _formatTimeRange(ScheduleModel s) {
    final start = s.timeOfDay;
    if (start == null || start.isEmpty) return null;
    final end = s.endTimeOfDay;
    if (end == null || end.isEmpty) return _format12h(start);
    return '${_format12h(start)}-${_format12h(end)}';
  }

  String _format12h(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$hour12:$mm$suffix';
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
                builder: (_) =>
                    ChatPage(title: 'AI · ${sp.name}', spaceId: sp.id),
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

// Removed progress widgets per simplified design

// Removed add-schedule sheet UI per new design focusing on viewing schedule only

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
          child: EmojiIcon(
            space.emoji,
            size: 20,
            color: const Color(0xFF71767B),
          ),
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
          // Minimal gradient AI icon inside a subtle circular holder
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x141D9BF0), // faint tint
              border: Border.all(color: const Color(0xFF2F3336)),
            ),
            alignment: Alignment.center,
            child: const _GradientAiIcon(size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            'Create your first space',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start quick or let AI help you set up.',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
          const SizedBox(height: 16),
          // 2) Quick start chips
          _SectionCard(
            title: 'Quick start',
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _QuickIconChip(
                  label: 'Programming',
                  emoji: '💻',
                  icon: Icons.code,
                  colors: const [Color(0xFF1D9BF0), Color(0xFF8A2BE2)],
                  onPick: onQuickCreate,
                ),
                _QuickIconChip(
                  label: 'Physics',
                  emoji: '🪐',
                  icon: Icons.auto_awesome_motion,
                  colors: const [Color(0xFF8A2BE2), Color(0xFFFF6FD8)],
                  onPick: onQuickCreate,
                ),
                _QuickIconChip(
                  label: 'Math',
                  emoji: '🧮',
                  icon: Icons.calculate,
                  colors: const [Color(0xFF00E5A8), Color(0xFF10B981)],
                  onPick: onQuickCreate,
                ),
                _QuickIconChip(
                  label: 'Chemistry',
                  emoji: '🧪',
                  icon: Icons.science,
                  colors: const [Color(0xFF34D399), Color(0xFF22D3EE)],
                  onPick: onQuickCreate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // 3) Create with AI
          _SectionCard(
            title: 'Create your first space with AI',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AiTextLine(
                  icon: Icons.chat_bubble_outline,
                  text: 'Tell us your topic and goals',
                ),
                const SizedBox(height: 8),
                const _AiTextLine(
                  icon: Icons.auto_awesome,
                  text: 'We assemble a tailored space',
                ),
                const SizedBox(height: 8),
                const _AiTextLine(
                  icon: Icons.check_circle_outline,
                  text: 'Review and confirm in minutes',
                ),
                const SizedBox(height: 12),
                _CreateWithAiChip(
                  label: 'Create with AI',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateSpaceWithAiPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientAiIcon extends StatelessWidget {
  const _GradientAiIcon({this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) {
    const gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF8A2BE2), Color(0xFF1D9BF0), Color(0xFF00E5A8)],
    );

    return ShaderMask(
      shaderCallback: (Rect bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, size, size)),
      blendMode: BlendMode.srcIn,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon(this.icon, {required this.size, required this.colors});
  final IconData icon;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
    return ShaderMask(
      shaderCallback: (Rect bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, size, size)),
      blendMode: BlendMode.srcIn,
      child: Icon(icon, size: size, color: const Color(0xFFFFFFFF)),
    );
  }
}

class _QuickIconChip extends StatelessWidget {
  const _QuickIconChip({
    required this.label,
    required this.emoji,
    required this.icon,
    required this.colors,
    required this.onPick,
  });
  final String label;
  final String emoji;
  final IconData icon;
  final List<Color> colors;
  final void Function(String emoji, String name) onPick;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: CircleAvatar(
        backgroundColor: const Color(0x00000000),
        foregroundColor: const Color(0x00000000),
        child: _GradientIcon(icon, size: 18, colors: colors),
      ),
      label: Text(label),
      onPressed: () => onPick(emoji, label),
      shape: const StadiumBorder(),
      backgroundColor: const Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
    );
  }
}

// Removed: _SuggestedSpaceCard and _AiTextChip (no longer used)

class _AiTextLine extends StatelessWidget {
  const _AiTextLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0x141D9BF0),
            border: Border.all(color: const Color(0xFF2F3336)),
          ),
          alignment: Alignment.center,
          child: _GradientIcon(
            icon,
            size: 16,
            colors: const [Color(0xFF8A2BE2), Color(0xFF1D9BF0)],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF8A2BE2), Color(0xFF1D9BF0)],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// (Removed) _GradientButton.icon: superseded by _CreateWithAiChip for this flow.

class _CreateWithAiChip extends StatelessWidget {
  const _CreateWithAiChip({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF1D9BF0)],
          ),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
            ],
          ),
        ),
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
