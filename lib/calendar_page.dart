import 'dart:async';

import 'package:flutter/material.dart';

import 'data/models.dart';
import 'main.dart';
import 'widgets/emoji_icon.dart';

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
  switch (s.recurrence) {
    case 'date':
      if ((s.date ?? '').isEmpty) return false;
      return s.date == _formatYMD(date);
    case 'range':
      final start = s.startDate;
      final end = s.endDate;
      if (start == null || end == null) return false;
      final sd = DateTime.tryParse(start);
      final ed = DateTime.tryParse(end);
      if (sd == null || ed == null) return false;
      if (date.isBefore(sd) || date.isAfter(ed)) return false;
      return s.daysOfWeek.contains(date.weekday);
    case 'weekly':
    default:
      return s.daysOfWeek.contains(date.weekday);
  }
}

String _formatYMD(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
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
                  child: EmojiIcon(s.emoji, size: 14, color: Colors.white70),
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
    final today = DateTime.now();
    final dateForSel = today.add(Duration(days: _selectedDay - today.weekday));
    final dayItems =
        widget.schedules.where((s) => _matchesDay(s, dateForSel)).toList()
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
                    child: EmojiIcon(s.emoji, size: 18, color: Colors.white70),
                  ),
                  title: Text(
                    s.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _subtitleFor(s),
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

  String _subtitleFor(ScheduleModel s) {
    final start = s.timeOfDay;
    final end = s.endTimeOfDay;
    String time;
    if ((start ?? '').isEmpty) {
      time = 'Anytime';
    } else if ((end ?? '').isEmpty) {
      time = _fmt(start!);
    } else {
      time = '${_fmt(start!)}-${_fmt(end!)}';
    }
    if ((s.room ?? '').isNotEmpty) time += ' · Room ${s.room}';
    return time;
  }

  String _fmt(String hhmm) {
    final p = hhmm.split(':');
    if (p.length != 2) return hhmm;
    final h = int.tryParse(p[0]) ?? 0;
    final m = int.tryParse(p[1]) ?? 0;
    final am = h < 12;
    final hh = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm${am ? 'AM' : 'PM'}';
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
        title: 'Gym',
        emoji: '🏋️',
        spaceId: null,
        daysOfWeek: const [1, 3, 5], // Mon, Wed, Fri
        timeOfDay: '07:30',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-2',
        title: 'Study',
        emoji: '📚',
        spaceId: null,
        daysOfWeek: const [2, 4], // Tue, Thu
        timeOfDay: '18:00',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-3',
        title: 'Meditation',
        emoji: '🧘',
        spaceId: null,
        daysOfWeek: const [1, 2, 3, 4, 5, 6, 7], // Daily
        timeOfDay: '08:00',
        createdAt: now,
        updatedAt: now,
      ),
      ScheduleModel(
        id: 'demo-${now.millisecondsSinceEpoch}-4',
        title: 'Coding',
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
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _tagsCtrl; // comma or # separated
  late Set<int> _days;
  String? _time; // HH:mm
  String? _endTime; // HH:mm
  String? _room;
  String? _selectedCategoryId;
  String? _selectedSpaceId;
  String _recurrence = 'weekly'; // weekly | date | range
  DateTime? _singleDate; // for date
  DateTime? _rangeStart; // for range
  DateTime? _rangeEnd; // for range

  @override
  void initState() {
    super.initState();
    final s = widget.initial;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _emojiCtrl = TextEditingController(text: s?.emoji ?? '📘');
    _descriptionCtrl = TextEditingController(text: s?.description ?? '');
    _tagsCtrl = TextEditingController(text: (s?.tags ?? const []).join(', '));
    _days = {
      ...(s?.daysOfWeek ?? const [1, 2, 3, 4, 5]),
    };
    _time = s?.timeOfDay;
    _endTime = s?.endTimeOfDay;
    _room = s?.room;
    _selectedCategoryId = s?.categoryId;
    _selectedSpaceId = s?.spaceId;
    _recurrence = s?.recurrence ?? 'weekly';
    if (s?.recurrence == 'date' && (s?.date ?? '').isNotEmpty) {
      _singleDate = _parseYMD(s!.date!);
    }
    if (s?.recurrence == 'range') {
      if ((s?.startDate ?? '').isNotEmpty) {
        _rangeStart = _parseYMD(s!.startDate!);
      }
      if ((s?.endDate ?? '').isNotEmpty) {
        _rangeEnd = _parseYMD(s!.endDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _emojiCtrl.dispose();
    _descriptionCtrl.dispose();
    _tagsCtrl.dispose();
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
                    child: Row(
                      children: [
                        EmojiIcon(
                          s.emoji,
                          size: 14,
                          color: const Color(0xFF71767B),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _selectedSpaceId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: const InputDecoration(
                labelText: 'Recurrence',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'weekly',
                  child: Text('Weekly (days of week)'),
                ),
                DropdownMenuItem(value: 'date', child: Text('Specific date')),
                DropdownMenuItem(
                  value: 'range',
                  child: Text('Date range + weekly pattern'),
                ),
              ],
              onChanged: (v) => setState(() => _recurrence = v ?? 'weekly'),
            ),
            const SizedBox(height: 12),
            if (_recurrence == 'date')
              _buildSingleDatePicker(context)
            else if (_recurrence == 'range')
              _buildRangePicker(context)
            else ...[
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
            ],
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start time (optional)',
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
                const SizedBox(width: 8),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'End time (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    child: InkWell(
                      onTap: _pickEndTime,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _endTime ?? '—',
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
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Room (optional)',
                hintText: 'e.g., C-301',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              onChanged: (v) => _room = v.trim().isEmpty ? null : v.trim(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Details, notes, objectives...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'e.g., #instructor: GH Mishra, #book: CLRS',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
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

  Widget _buildSingleDatePicker(BuildContext context) {
    final label = _singleDate == null
        ? 'Pick date'
        : '${_singleDate!.year}-${_two(_singleDate!.month)}-${_two(_singleDate!.day)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 3),
              initialDate: _singleDate ?? now,
            );
            if (picked != null) setState(() => _singleDate = picked);
          },
          icon: const Icon(Icons.event),
          label: Text(label),
        ),
      ],
    );
  }

  Widget _buildRangePicker(BuildContext context) {
    final startLabel = _rangeStart == null
        ? 'Start date'
        : '${_rangeStart!.year}-${_two(_rangeStart!.month)}-${_two(_rangeStart!.day)}';
    final endLabel = _rangeEnd == null
        ? 'End date'
        : '${_rangeEnd!.year}-${_two(_rangeEnd!.month)}-${_two(_rangeEnd!.day)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 3),
                    initialDate: _rangeStart ?? now,
                  );
                  if (picked != null) setState(() => _rangeStart = picked);
                },
                child: Text(startLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 3),
                    initialDate: _rangeEnd ?? (_rangeStart ?? now),
                  );
                  if (picked != null) setState(() => _rangeEnd = picked);
                },
                child: Text(endLabel),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Select days of week within range',
          style: TextStyle(fontSize: 12, color: Color(0xFF71767B)),
        ),
        const SizedBox(height: 6),
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
      ],
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

  Future<void> _pickEndTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    setState(() => _endTime = '$hh:$mm');
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '📘' : _emojiCtrl.text;
    if (title.isEmpty) return;
    if (_recurrence == 'weekly' && _days.isEmpty) return;
    if (_recurrence == 'range' && (_rangeStart == null || _rangeEnd == null)) {
      return;
    }
    if (_recurrence == 'date' && _singleDate == null) return;
    final tags = _parseTags(_tagsCtrl.text);
    final now = DateTime.now();
    final model =
        (widget.initial ??
                ScheduleModel(
                  id: now.millisecondsSinceEpoch.toString(),
                  title: title,
                  emoji: emoji,
                  spaceId: _selectedSpaceId,
                  categoryId: _selectedCategoryId,
                  daysOfWeek: _recurrence == 'date' ? [] : _days.toList()
                    ..sort(),
                  timeOfDay: _time,
                  endTimeOfDay: _endTime,
                  durationMinutes: _calcDuration(_time, _endTime),
                  room: _room,
                  description: _descriptionCtrl.text.trim().isEmpty
                      ? null
                      : _descriptionCtrl.text.trim(),
                  tags: tags,
                  recurrence: _recurrence,
                  date: _recurrence == 'date' ? _formatYMD(_singleDate!) : null,
                  startDate: _recurrence == 'range'
                      ? _formatYMD(_rangeStart!)
                      : null,
                  endDate: _recurrence == 'range'
                      ? _formatYMD(_rangeEnd!)
                      : null,
                  createdAt: now,
                  updatedAt: now,
                ))
            .copyWith(
              title: title,
              emoji: emoji,
              spaceId: _selectedSpaceId,
              categoryId: _selectedCategoryId,
              daysOfWeek: _recurrence == 'date' ? [] : _days.toList()
                ..sort(),
              timeOfDay: _time,
              endTimeOfDay: _endTime,
              durationMinutes: _calcDuration(_time, _endTime),
              room: _room,
              description: _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
              tags: tags,
              recurrence: _recurrence,
              date: _recurrence == 'date' ? _formatYMD(_singleDate!) : null,
              startDate: _recurrence == 'range'
                  ? _formatYMD(_rangeStart!)
                  : null,
              endDate: _recurrence == 'range' ? _formatYMD(_rangeEnd!) : null,
              updatedAt: now,
            );
    Navigator.of(context).pop(model);
  }

  List<String> _parseTags(String input) {
    if (input.trim().isEmpty) return const [];
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('#') ? e : e)
        .toList();
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  DateTime? _parseYMD(String ymd) {
    try {
      final p = ymd.split('-');
      if (p.length != 3) return null;
      return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  String _formatYMD(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  int? _calcDuration(String? start, String? end) {
    if (start == null || end == null) return null;
    final sp = start.split(':'), ep = end.split(':');
    if (sp.length != 2 || ep.length != 2) return null;
    final sh = int.tryParse(sp[0]) ?? 0;
    final sm = int.tryParse(sp[1]) ?? 0;
    final eh = int.tryParse(ep[0]) ?? 0;
    final em = int.tryParse(ep[1]) ?? 0;
    final diff = (eh * 60 + em) - (sh * 60 + sm);
    return diff > 0 ? diff : null;
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
    final uncategorized = byCat[null] ?? const [];

    List<Widget> buildRoutineList(List<ScheduleModel> list) => list
        .map((s) => _RoutineCompactTile(
              schedule: s,
              space: spaceMap[s.spaceId],
            ))
        .toList();

    final categorySections = <Widget>[];
    for (final c in categories) {
      final items = byCat[c.id] ?? const [];
      if (items.isEmpty) continue;
      categorySections.add(
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            children: [
              Text(
                c.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181A),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF2F3336)),
                ),
                child: Text(
                  '${items.length}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF71767B)),
                ),
              ),
            ],
          ),
        ),
      );
      categorySections.addAll(buildRoutineList(items));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const Text(
          'Your routines',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Manage categories'),
              avatar: const Icon(Icons.tune, size: 18),
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (_) => _ManageCategoriesSheet(
                    categories: categories,
                    byCat: byCat,
                  ),
                );
              },
            ),
            ActionChip(
              label: const Text('+ Add routine'),
              avatar: const Icon(Icons.add, size: 18),
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
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2F3336)),
            ),
            child: const Text(
              'No routines yet. Add your first one.',
              style: TextStyle(color: Color(0xFF71767B)),
            ),
          )
        else ...[
          if (uncategorized.isNotEmpty) ...[
            const Text(
              'Uncategorized',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            ...buildRoutineList(uncategorized),
            if (categorySections.isNotEmpty) const SizedBox(height: 12),
          ],
          ...categorySections,
        ],
      ],
    );
  }
}

class _RoutineCompactTile extends StatelessWidget {
  const _RoutineCompactTile({required this.schedule, this.space});
  final ScheduleModel schedule;
  final SpaceModel? space;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => _RoutineDetailSheet(
              schedule: schedule,
              space: space,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF2F3336),
                child: EmojiIcon(
                  schedule.emoji,
                  size: 18,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            schedule.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (space != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EmojiIcon(
                                space!.emoji,
                                size: 14,
                                color: const Color(0xFF71767B),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                space!.name,
                                style: const TextStyle(
                                  color: Color(0xFF71767B),
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _daysAndTimeLabel(schedule),
                      style: const TextStyle(
                        color: Color(0xFF71767B),
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((schedule.tags).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: [
                            for (final t in schedule.tags.take(3))
                              Text(
                                '#$t',
                                style: const TextStyle(
                                  color: Color(0xFF444B52),
                                  fontSize: 11,
                                ),
                              ),
                            if (schedule.tags.length > 3)
                              Text(
                                '+${schedule.tags.length - 3}',
                                style: const TextStyle(
                                  color: Color(0xFF444B52),
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManageCategoriesSheet extends StatelessWidget {
  const _ManageCategoriesSheet({
    required this.categories,
    required this.byCat,
  });
  final List<RoutineCategoryModel> categories;
  final Map<String?, List<ScheduleModel>> byCat;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
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
            Row(
              children: [
                const Text(
                  'Manage categories',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Add category',
                  icon: const Icon(Icons.add),
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
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (categories.isEmpty)
              const Text(
                'No categories yet.',
                style: TextStyle(color: Color(0xFF71767B)),
              )
            else
              ...categories.map(
                (c) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF2F3336)),
                  ),
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text(
                      '${(byCat[c.id] ?? const []).length} routines',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF71767B),
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final name =
                              await _promptText(context, 'Rename category');
                          if (name == null || name.trim().isEmpty) return;
                          final now = DateTime.now();
                          final updated = c.copyWith(
                            name: name.trim(),
                            updatedAt: now,
                          );
                          await DBProvider.of(context)
                              .upsertRoutineCategory(updated);
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
                          await DBProvider.of(context)
                              .deleteRoutineCategory(c.id);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


class _RoutineDetailSheet extends StatelessWidget {
  const _RoutineDetailSheet({required this.schedule, this.space});
  final ScheduleModel schedule;
  final SpaceModel? space;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tags = schedule.tags;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => SingleChildScrollView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
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
            Row(
              children: [
                EmojiIcon(schedule.emoji, size: 32, color: Colors.white70),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schedule.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final updated = await showModalBottomSheet<ScheduleModel>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => _AddRoutineSheet(initial: schedule),
                    );
                    if (updated != null) {
                      await DBProvider.of(context).upsertSchedule(updated);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (dctx) => AlertDialog(
                        title: const Text('Delete routine?'),
                        content: const Text('This will remove the routine.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(dctx).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await DBProvider.of(context).deleteSchedule(schedule.id);
                      if (context.mounted) Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Recurrence', _recurrenceLabel(schedule)),
            if ((schedule.timeOfDay ?? '').isNotEmpty)
              _detailRow(
                'Time',
                (schedule.endTimeOfDay?.isNotEmpty ?? false)
                    ? '${schedule.timeOfDay}-${schedule.endTimeOfDay}'
                    : schedule.timeOfDay!,
              ),
            if ((schedule.room ?? '').isNotEmpty)
              _detailRow('Room', schedule.room!),
            if (space != null) _detailRow('Space', space!.name),
            if ((schedule.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Description', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                schedule.description!,
                style: const TextStyle(color: Color(0xFFB0B3B8)),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Tags', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: -4,
                children: [
                  for (final t in tags)
                    Chip(
                      label: Text(t),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -4,
                        vertical: -4,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF71767B),
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  String _recurrenceLabel(ScheduleModel s) {
    switch (s.recurrence) {
      case 'date':
        return 'On ${s.date ?? '-'}';
      case 'range':
        final days = s.daysOfWeek.map(_weekdayLabel).join(',');
        return 'Range ${s.startDate ?? '-'}→${s.endDate ?? '-'} ($days)';
      case 'weekly':
      default:
        return s.daysOfWeek.map(_weekdayLabel).join(', ');
    }
  }
}

String _daysAndTimeLabel(ScheduleModel s) {
  final parts = <String>[];
  switch (s.recurrence) {
    case 'date':
      if ((s.date ?? '').isNotEmpty) parts.add(s.date!);
      break;
    case 'range':
      if ((s.startDate ?? '').isNotEmpty && (s.endDate ?? '').isNotEmpty) {
        parts.add('${s.startDate}→${s.endDate}');
      }
      if (s.daysOfWeek.isNotEmpty) {
        parts.add(s.daysOfWeek.map(_weekdayLabel).join(','));
      }
      break;
    case 'weekly':
    default:
      if (s.daysOfWeek.isNotEmpty) {
        parts.add(s.daysOfWeek.map(_weekdayLabel).join(','));
      }
  }
  if ((s.timeOfDay ?? '').isNotEmpty) {
    parts.add(
      (s.endTimeOfDay?.isNotEmpty ?? false)
          ? '${s.timeOfDay}-${s.endTimeOfDay}'
          : s.timeOfDay!,
    );
  } else {
    parts.add('Anytime');
  }
  if ((s.room ?? '').isNotEmpty) parts.add('Room ${s.room}');
  if (s.tags.isNotEmpty) parts.add(s.tags.map((e) => '#${e}').join(' '));
  return parts.join(' · ');
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
