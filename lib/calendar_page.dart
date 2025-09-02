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

  @override
  void initState() {
    super.initState();
    // Two sections only: Year and Routine
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedSub?.cancel();
    final db = DBProvider.of(context);
    _schedules = db.currentSchedules;
    _schedSub = db.schedulesStream.listen((list) {
      if (!mounted) return;
      setState(() => _schedules = list);
    });
  }

  @override
  void dispose() {
    _schedSub?.cancel();
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
            Tab(text: 'Routine'),
          ],
        ),
        // Removed calendar/today icon as requested
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _YearView(year: _anchor.year, schedules: _schedules),
          _RoutineViewRedesigned(schedules: _schedules),
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

class _RoutineViewRedesigned extends StatefulWidget {
  const _RoutineViewRedesigned({required this.schedules});
  final List<ScheduleModel> schedules;

  @override
  State<_RoutineViewRedesigned> createState() => _RoutineViewRedesignedState();
}

class _RoutineViewRedesignedState extends State<_RoutineViewRedesigned> {
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
                'Routine',
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
  const _AddRoutineSheet();

  @override
  State<_AddRoutineSheet> createState() => _AddRoutineSheetState();
}

class _AddRoutineSheetState extends State<_AddRoutineSheet> {
  final _titleCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController(text: '📘');
  final Set<int> _days = {1, 2, 3, 4, 5};
  String? _time; // HH:mm

  @override
  void dispose() {
    _titleCtrl.dispose();
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
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    final model = ScheduleModel(
      id: id,
      title: title,
      emoji: emoji,
      spaceId: null,
      daysOfWeek: _days.toList()..sort(),
      timeOfDay: _time,
      createdAt: now,
      updatedAt: now,
    );
    Navigator.of(context).pop(model);
  }
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
