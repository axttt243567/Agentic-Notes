import 'dart:async';

import 'package:flutter/material.dart';

import 'data/models.dart';
import 'main.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  DateTime _anchor = DateTime.now();
  List<ScheduleModel> _schedules = const [];
  StreamSubscription? _schedSub;
  List<RoutineCategoryModel> _categories = const [];
  StreamSubscription? _catSub;
  List<SpaceModel> _spaces = const [];
  StreamSubscription? _spacesSub;

  @override
  void initState() {
    super.initState();
    // Three sections: Year, Weekly overview, and Routines
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedSub?.cancel();
    _catSub?.cancel();
    _spacesSub?.cancel();
    final db = DBProvider.of(context);
    _schedules = db.currentSchedules;
    _categories = db.currentRoutineCategories;
    _spaces = db.currentSpaces;
    _schedSub = db.schedulesStream.listen((list) {
      if (!mounted) return;
      setState(() => _schedules = list);
    });
    _catSub = db.routineCategoriesStream.listen((list) {
      if (!mounted) return;
      setState(() => _categories = list);
    });
    _spacesSub = db.spacesStream.listen((list) {
      if (!mounted) return;
      setState(() => _spaces = list);
    });
  }

  @override
  void dispose() {
    _schedSub?.cancel();
    _catSub?.cancel();
    _spacesSub?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Year'),
            Tab(text: 'Weekly overview'),
            Tab(text: 'Routines'),
          ],
        ),
        // Removed calendar/today icon as requested
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _YearView(year: _anchor.year, schedules: _schedules),
          _WeeklyOverviewView(schedules: _schedules),
          _RoutinesManagerView(
            schedules: _schedules,
            categories: _categories,
            spaces: _spaces,
          ),
        ],
      ),
    );
  }
}

bool _matchesDay(ScheduleModel s, DateTime date) {
  return s.daysOfWeek.contains(date.weekday);
}

class _YearView extends StatefulWidget {
  const _YearView({required this.year, required this.schedules});
  final int year;
  final List<ScheduleModel> schedules;

  @override
  State<_YearView> createState() => _YearViewState();
}

class _YearViewState extends State<_YearView> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.schedules.map((s) => s.id).toSet();
  }

  @override
  void didUpdateWidget(covariant _YearView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep selection in sync with available schedules (retain selections that still exist)
    final available = widget.schedules.map((s) => s.id).toSet();
    _selectedIds = _selectedIds.intersection(available);
    if (_selectedIds.isEmpty && available.isNotEmpty) {
      // Default to all when everything disappears (e.g., first load)
      _selectedIds = available;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.schedules
        .where((s) => _selectedIds.contains(s.id))
        .toList();

    return Column(
      children: [
        // Yearly grid of months
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: 12,
            itemBuilder: (context, i) {
              final month = i + 1;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF2F3336)),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _monthName(month),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _MiniMonthHeatmap(
                        year: widget.year,
                        month: month,
                        schedules: active,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Routine chips under the yearly calendar
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF2F3336))),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _RoutineChips(
            schedules: widget.schedules,
            selectedIds: _selectedIds,
            onToggleAll: () {
              setState(() {
                if (_selectedIds.length == widget.schedules.length) {
                  _selectedIds.clear();
                } else {
                  _selectedIds = widget.schedules.map((s) => s.id).toSet();
                }
              });
            },
            onToggleOne: (id) {
              setState(() {
                if (_selectedIds.contains(id)) {
                  _selectedIds.remove(id);
                } else {
                  _selectedIds.add(id);
                }
              });
            },
          ),
        ),
      ],
    );
  }
}

class _RoutineChips extends StatelessWidget {
  const _RoutineChips({
    required this.schedules,
    required this.selectedIds,
    required this.onToggleAll,
    required this.onToggleOne,
  });
  final List<ScheduleModel> schedules;
  final Set<String> selectedIds;
  final VoidCallback onToggleAll;
  final void Function(String id) onToggleOne;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(right: 12),
        children: [
          const SizedBox(width: 12),
          FilterChip(
            label: const Text('All'),
            selected:
                selectedIds.length == schedules.length && schedules.isNotEmpty,
            onSelected: (_) => onToggleAll(),
          ),
          const SizedBox(width: 8),
          ...schedules.map(
            (s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF2F3336),
                  child: Text(s.emoji, style: const TextStyle(fontSize: 12)),
                ),
                label: Text(s.title),
                selected: selectedIds.contains(s.id),
                onSelected: (_) => onToggleOne(s.id),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMonthHeatmap extends StatelessWidget {
  const _MiniMonthHeatmap({
    required this.year,
    required this.month,
    required this.schedules,
  });
  final int year;
  final int month;
  final List<ScheduleModel> schedules;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final startWeekday = first.weekday; // 1..7 Mon..Sun
    final totalCells = ((startWeekday - 1) + daysInMonth);
    final rows = ((totalCells + 6) ~/ 7);
    int dayNum = 1;
    return Column(
      children: List.generate(rows, (r) {
        return Expanded(
          child: Row(
            children: List.generate(7, (c) {
              final cellIndex = r * 7 + c;
              final isDayCell =
                  cellIndex >= (startWeekday - 1) && dayNum <= daysInMonth;
              if (!isDayCell) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }
              final date = DateTime(year, month, dayNum++);
              final busy = _busyCount(date, schedules);
              final color = busy == 0
                  ? const Color(0xFF16181A)
                  : busy == 1
                  ? const Color(0xFF223A4B)
                  : busy == 2
                  ? const Color(0xFF0E4D75)
                  : const Color(0xFF1D9BF0);
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

int _busyCount(DateTime date, List<ScheduleModel> schedules) {
  int count = 0;
  for (final s in schedules) {
    if (_matchesDay(s, date)) count++;
  }
  return count;
}

class _WeeklyOverviewView extends StatefulWidget {
  const _WeeklyOverviewView({required this.schedules});
  final List<ScheduleModel> schedules;

  @override
  State<_WeeklyOverviewView> createState() => _WeeklyOverviewViewState();
}

class _WeeklyOverviewViewState extends State<_WeeklyOverviewView> {
  late int _selectedDay; // 1..7

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now().weekday;
  }

  @override
  Widget build(BuildContext context) {
    final dayItems =
        widget.schedules
            .where((s) => s.daysOfWeek.contains(_selectedDay))
            .toList()
          ..sort((a, b) => (a.timeOfDay ?? '').compareTo(b.timeOfDay ?? ''));

    return Column(
      children: [
        // Header with actions
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              const Text(
                'Weekly overview',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: _addDemoRoutines,
                child: const Text('Add demo'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        // Horizontal week selector (Mon..Sun)
        SizedBox(
          height: 56,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final day = i + 1; // 1..7
              final selected = day == _selectedDay;
              return ChoiceChip(
                label: Text(_weekdayLabel(day)),
                selected: selected,
                onSelected: (_) => setState(() => _selectedDay = day),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemCount: 7,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: dayItems.isEmpty ? 1 : dayItems.length,
            itemBuilder: (context, index) {
              if (dayItems.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2F3336)),
                  ),
                  child: const Text(
                    'No routines for this day',
                    style: TextStyle(color: Color(0xFF71767B)),
                  ),
                );
              }
              final s = dayItems[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2F3336)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF2F3336),
                    child: Text(s.emoji, style: const TextStyle(fontSize: 16)),
                  ),
                  title: Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    s.timeOfDay ?? 'Anytime',
                    style: const TextStyle(
                      color: Color(0xFF71767B),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd() async {
    final created = await showModalBottomSheet<ScheduleModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddRoutineSheet(),
    );
    if (created == null) return;
    await DBProvider.of(context).upsertSchedule(created);
  }

  Future<void> _addDemoRoutines() async {
    final now = DateTime.now();
    final demos = <ScheduleModel>[
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-1',
        title: '🏋️ Gym',
        emoji: '🏋️',
        spaceId: null,
        daysOfWeek: const [1, 3, 5], // Mon, Wed, Fri
        timeOfDay: '07:30',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-2',
        title: '📚 Study',
        emoji: '📚',
        spaceId: null,
        daysOfWeek: const [2, 4], // Tue, Thu
        timeOfDay: '18:00',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-3',
        title: '🧘 Meditation',
        emoji: '🧘',
        spaceId: null,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7], // Daily
        timeOfDay: '08:00',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-4',
        title: '💻 Coding',
        emoji: '💻',
        spaceId: null,
        daysOfWeek: const [6, 7], // Sat, Sun
        timeOfDay: '14:00',
        createdAt: now,
        updatedAt: now,
      ),
    ];
    final db = DBProvider.of(context);
    for (final s in demos) {
      await db.upsertSchedule(s);
    }
  }
}

class _AddRoutineSheet extends StatefulWidget {
  const _AddRoutineSheet({this.initial});
  final ScheduleModel? initial;

  @override
  State<_AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<_AddRoutineSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _emojiCtrl;
  late Set<int> _days;
  String? _time; // HH:mm
  String? _selectedCategoryId;
  String? _selectedSpaceId;

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _emojiCtrl = TextEditingController(text: s?.emoji ?? '📘');
    _days = {
      ...(s?.daysOfWeek ?? const [1, 2, 3, 4, 5]),
    };
    _time = s?.timeOfDay;
    _selectedCategoryId = s?.categoryId;
    _selectedSpaceId = s?.spaceId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emojiCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = DBProvider.of(context);
    final categories = db.currentRoutineCategories;
    final spaces = db.currentSpaces;
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
              'Add routine',
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
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Physics Lab',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    hint: const Text('Category (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...categories.map(
                        (c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'New category',
                  onPressed: () async {
                    final name = await _promptText(context, 'New category');
                    if (name == null || name.trim().isEmpty) return;
                    final now = DateTime.now();
                    final cat = RoutineCategoryModel(
                      id: now.millisecondsSinceEpoch.toString(),
                      name: name.trim(),
                      createdAt: now,
                      updatedAt: now,
                    );
                    await DBProvider.of(context).upsertRoutineCategory(cat);
                    setState(() => _selectedCategoryId = cat.id);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: _selectedSpaceId,
              isExpanded: true,
              hint: const Text('Link to space (optional)'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None'),
                ),
                ...spaces.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text('${s.emoji} ${s.name}'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedSpaceId = v),
            ),
            const SizedBox(height: 12),
            const Text('Days of week'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in [1, 2, 3, 4, 5, 6, 7])
                  FilterChip(
                    label: Text(_weekdayLabel(d)),
                    selected: _days.contains(d),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _days.add(d);
                      } else {
                        _days.remove(d);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Time (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    child: InkWell(
                      onTap: _pickTime,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _time ?? 'Anytime',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const Icon(Icons.access_time, size: 18),
                        ],
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
                FilledButton(onPressed: _submit, child: const Text('Save')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() => _time = '$hh:$mm');
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '📘' : _emojiCtrl.text;
    if (title.isEmpty || _days.isEmpty) return;
    final now = DateTime.now();
    final model =
        (widget.initial ??
                ScheduleModel(
                  id: now.millisecondsSinceEpoch.toString(),
                  title: title,
                  emoji: emoji,
                  spaceId: _selectedSpaceId,
                  categoryId: _selectedCategoryId,
                  daysOfWeek: _days.toList()..sort(),
                  timeOfDay: _time,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              title: title,
              emoji: emoji,
              spaceId: _selectedSpaceId,
              categoryId: _selectedCategoryId,
              daysOfWeek: _days.toList()..sort(),
              timeOfDay: _time,
              updatedAt: now,
            );
    Navigator.of(context).pop(model);
  }
}

class _RoutinesManagerView extends StatelessWidget {
  const _RoutinesManagerView({
    required this.schedules,
    required this.categories,
    required this.spaces,
  });
  final List<ScheduleModel> schedules;
  final List<RoutineCategoryModel> categories;
  final List<SpaceModel> spaces;

  @override
  Widget build(BuildContext context) {
    final byCat = <String?, List<ScheduleModel>>{};
    for (final s in schedules) {
      byCat.putIfAbsent(s.categoryId, () => []).add(s);
    }
    final spaceMap = {for (final s in spaces) s.id: s};

    final sections = <Widget>[];
    // Categories first
    for (final c in categories) {
      final items = byCat[c.id] ?? const [];
      sections.addAll([
        _SectionHeader(
          title: c.name,
          actions: [
            PopupMenuButton<String>(
              tooltip: 'Category actions',
              onSelected: (v) async {
                if (v == 'rename') {
                  final name = await _promptText(context, 'Rename category');
                  if (name == null || name.trim().isEmpty) return;
                  final now = DateTime.now();
                  final updated = c.copyWith(name: name.trim(), updatedAt: now);
                  await DBProvider.of(context).upsertRoutineCategory(updated);
                } else if (v == 'delete') {
                  if ((byCat[c.id] ?? const []).isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Move or delete routines in this category first.',
                        ),
                      ),
                    );
                    return;
                  }
                  await DBProvider.of(context).deleteRoutineCategory(c.id);
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        ...items.map((s) => _RoutineTile(s: s, space: spaceMap[s.spaceId])),
        const SizedBox(height: 8),
      ]);
    }
    // Uncategorized
    final uncategorized = byCat[null] ?? const [];
    sections.addAll([
      if (uncategorized.isNotEmpty)
        _SectionHeader(title: 'Uncategorized', actions: const []),
      ...uncategorized.map(
        (s) => _RoutineTile(s: s, space: spaceMap[s.spaceId]),
      ),
    ]);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
          child: Row(
            children: [
              const Text(
                'Routines',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final name = await _promptText(context, 'New category');
                  if (name == null || name.trim().isEmpty) return;
                  final now = DateTime.now();
                  final cat = RoutineCategoryModel(
                    id: now.millisecondsSinceEpoch.toString(),
                    name: name.trim(),
                    createdAt: now,
                    updatedAt: now,
                  );
                  await DBProvider.of(context).upsertRoutineCategory(cat);
                },
                child: const Text('Add category'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () async {
                  final created = await showModalBottomSheet<ScheduleModel>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (ctx) => const _AddRoutineSheet(),
                  );
                  if (created == null) return;
                  await DBProvider.of(context).upsertSchedule(created);
                },
                icon: const Icon(Icons.add),
                label: const Text('Add routine'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            children: sections.isEmpty
                ? [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF2F3336)),
                      ),
                      child: const Text(
                        'No routines yet. Create one to get started.',
                        style: TextStyle(color: Color(0xFF71767B)),
                      ),
                    ),
                  ]
                : sections,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.actions});
  final String title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const Spacer(),
          ...actions,
        ],
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  const _RoutineTile({required this.s, this.space});
  final ScheduleModel s;
  final SpaceModel? space;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2F3336),
          child: Text(s.emoji, style: const TextStyle(fontSize: 16)),
        ),
        title: Text(
          s.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _daysAndTimeLabel(s),
          style: const TextStyle(color: Color(0xFF71767B), fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (space != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF2F3336)),
                ),
                child: Text(
                  '${space!.emoji} ${space!.name}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Routine actions',
              onSelected: (v) async {
                if (v == 'edit') {
                  final updated = await showModalBottomSheet<ScheduleModel>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => _AddRoutineSheet(initial: s),
                  );
                  if (updated != null) {
                    await DBProvider.of(context).upsertSchedule(updated);
                  }
                } else if (v == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete routine?'),
                      content: const Text('This will remove the routine.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).maybePop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await DBProvider.of(context).deleteSchedule(s.id);
                  }
                }
              },
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _daysAndTimeLabel(ScheduleModel s) {
  final days = s.daysOfWeek.map(_weekdayLabel).join(', ');
  return s.timeOfDay == null ? days : '$days · ${s.timeOfDay}';
}

Future<String?> _promptText(BuildContext context, String title) async {
  final res = await showDialog<String>(
    context: context,
    builder: (ctx) {
      final ctrl = TextEditingController();
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Enter name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).maybePop(),
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
  return res;
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

String _monthName(int m) {
  const names = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return names[m - 1];
}
