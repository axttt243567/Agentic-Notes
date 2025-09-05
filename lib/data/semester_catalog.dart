import 'dart:convert';

import 'models.dart';
import 'database_service.dart';

class _RoutineSpec {
  final List<int> daysOfWeek; // 1=Mon..7=Sun
  final String start; // HH:mm
  final String end; // HH:mm
  final String room;
  const _RoutineSpec({
    required this.daysOfWeek,
    required this.start,
    required this.end,
    required this.room,
  });
}

class _SubjectSpec {
  final String name;
  final String emoji;
  final String instructor;
  final String courseDetails;
  final List<_RoutineSpec> routines;
  const _SubjectSpec({
    required this.name,
    required this.emoji,
    required this.instructor,
    required this.courseDetails,
    required this.routines,
  });
}

// Demo catalog for Section-C, Semester-3 only (as requested).
const List<_SubjectSpec> _secC_sem3_subjects = [
  _SubjectSpec(
    name: 'Data Structures & Algorithms',
    emoji: '🧮',
    instructor: 'Dr. A. Sharma',
    courseDetails:
        'Stacks, queues, linked lists, trees, graphs, sorting & searching. Focus on complexity and implementation.',
    routines: [
      _RoutineSpec(
        daysOfWeek: [1, 3],
        start: '10:00',
        end: '11:00',
        room: 'C-301',
      ), // Mon, Wed
    ],
  ),
  _SubjectSpec(
    name: 'Discrete Mathematics',
    emoji: '📐',
    instructor: 'Prof. R. Iyer',
    courseDetails:
        'Logic, sets, relations, functions, combinatorics, graphs, and proof techniques.',
    routines: [
      _RoutineSpec(
        daysOfWeek: [2, 4],
        start: '09:00',
        end: '10:00',
        room: 'C-301',
      ), // Tue, Thu
    ],
  ),
  _SubjectSpec(
    name: 'Digital Logic Design',
    emoji: '🔌',
    instructor: 'Dr. S. Mehta',
    courseDetails:
        'Boolean algebra, logic gates, combinational & sequential circuits, FSMs.',
    routines: [
      _RoutineSpec(
        daysOfWeek: [1, 5],
        start: '12:00',
        end: '13:00',
        room: 'C-302',
      ), // Mon, Fri
    ],
  ),
  _SubjectSpec(
    name: 'OOP in Java',
    emoji: '☕',
    instructor: 'Ms. N. Kapoor',
    courseDetails:
        'Classes, objects, inheritance, polymorphism, exceptions, collections, and basic I/O.',
    routines: [
      _RoutineSpec(
        daysOfWeek: [2, 4],
        start: '11:00',
        end: '12:00',
        room: 'Lab-2',
      ), // Tue, Thu
    ],
  ),
  _SubjectSpec(
    name: 'Probability & Statistics',
    emoji: '📊',
    instructor: 'Dr. V. Rao',
    courseDetails:
        'Random variables, distributions, expectation, confidence intervals, and hypothesis testing.',
    routines: [
      _RoutineSpec(
        daysOfWeek: [3, 5],
        start: '09:00',
        end: '10:00',
        room: 'C-303',
      ), // Wed, Fri
    ],
  ),
];

String _metadataForSubject(_SubjectSpec s) {
  final map = {
    'instructor': s.instructor,
    'courseDetails': s.courseDetails,
    'routines': [
      for (final r in s.routines)
        {
          'daysOfWeek': r.daysOfWeek,
          'start': r.start,
          'end': r.end,
          'room': r.room,
        },
    ],
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

int _durationMinutes(String start, String end) {
  final sp = start.split(':'), ep = end.split(':');
  if (sp.length != 2 || ep.length != 2) return 0;
  final sh = int.tryParse(sp[0]) ?? 0;
  final sm = int.tryParse(sp[1]) ?? 0;
  final eh = int.tryParse(ep[0]) ?? 0;
  final em = int.tryParse(ep[1]) ?? 0;
  return (eh * 60 + em) - (sh * 60 + sm);
}

Future<void> seedForProfileIfEmpty(DatabaseService db) async {
  final profile = db.currentProfile;
  // Only seed for Section-C, Semester 3
  if ((profile.section ?? '').toLowerCase() != 'section-c' ||
      (profile.semester ?? -1) != 3) {
    return;
  }

  // Avoid duplicating: if spaces already exist with these names, skip
  final existingSpaceNames = db.currentSpaces.map((s) => s.name).toSet();
  final now = DateTime.now();

  for (final subj in _secC_sem3_subjects) {
    if (existingSpaceNames.contains(subj.name)) {
      // Optionally could still seed routines if missing for this space
      continue;
    }
    final spaceId = 'space-${now.millisecondsSinceEpoch}-${subj.name.hashCode}';
    final space = SpaceModel(
      id: spaceId,
      name: subj.name,
      emoji: subj.emoji,
      description: 'Semester 3 · Section C (demo) — ${subj.name}',
      goals:
          '• Attend classes on time\n• Maintain notes\n• Prepare weekly summaries',
      guide:
          'Use the Routine tab to see class timings. Store notes and past papers in Resources.',
      metadataJson: _metadataForSubject(subj),
    );
    await db.upsertSpace(space);

    for (final r in subj.routines) {
      final dur = _durationMinutes(r.start, r.end);
      final sched = ScheduleModel(
        id: 'sch-${DateTime.now().microsecondsSinceEpoch}-${subj.name.hashCode}',
        title: subj.name,
        emoji: subj.emoji,
        spaceId: spaceId,
        categoryId: null,
        daysOfWeek: r.daysOfWeek,
        timeOfDay: r.start,
        endTimeOfDay: r.end,
        durationMinutes: dur > 0 ? dur : null,
        room: r.room,
        createdAt: now,
        updatedAt: now,
      );
      await db.upsertSchedule(sched);
    }
  }
}
