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

Future<void> seedForProfileIfEmpty(DatabaseService db) async {
  // Disabled (no demo data seeding). If legacy demo data exists, you can
  // optionally invoke purgeDemoSemester3SectionC(db) elsewhere to remove it.
  return;
}

/// Optional cleanup for previously seeded Semester 3 Section-C demo data.
Future<int> purgeDemoSemester3SectionC(DatabaseService db) async {
  final subjectNames = _secC_sem3_subjects.map((s) => s.name).toSet();
  int removed = 0;
  // Remove schedules whose title matches demo subject names.
  for (final sc in db.currentSchedules) {
    if (subjectNames.contains(sc.title)) {
      await db.deleteSchedule(sc.id);
      removed++;
    }
  }
  // Remove spaces with those names (only if user hasn't modified? For now, direct).
  for (final sp in db.currentSpaces) {
    if (subjectNames.contains(sp.name)) {
      await db.deleteSpace(sp.id);
    }
  }
  return removed;
}
