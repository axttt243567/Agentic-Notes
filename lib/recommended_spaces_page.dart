import 'package:flutter/material.dart';
import 'main.dart';
import 'data/models.dart';

class RecommendedSpacesPage extends StatelessWidget {
  const RecommendedSpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = _categories();
    return Scaffold(
      appBar: AppBar(title: const Text('Recommended spaces')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          for (final c in cats) ...[
            _CategorySection(title: c.title, recommendations: c.recs),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.title, required this.recommendations});
  final String title;
  final List<_Rec> recommendations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xFF71767B),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final r in recommendations) _RecommendChip(rec: r)],
        ),
      ],
    );
  }
}

class _RecommendChip extends StatelessWidget {
  const _RecommendChip({required this.rec});
  final _Rec rec;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text('${rec.emoji} ${rec.name}'),
      onPressed: () async {
        final db = DBProvider.of(context);
        final id = DateTime.now().millisecondsSinceEpoch.toString();
        await db.upsertSpace(
          SpaceModel(
            id: id,
            name: rec.name,
            emoji: rec.emoji,
            description: rec.description,
            goals: rec.goals,
            guide: rec.guide,
          ),
        );
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added "${rec.name}"')));
      },
      shape: const StadiumBorder(),
      backgroundColor: const Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
    );
  }
}

class _CategoryData {
  final String title;
  final List<_Rec> recs;
  const _CategoryData(this.title, this.recs);
}

class _Rec {
  final String emoji;
  final String name;
  final String description; // purpose/overview
  final String goals; // short bullet-like lines
  final String guide; // how to use the space
  const _Rec({
    required this.emoji,
    required this.name,
    required this.description,
    required this.goals,
    required this.guide,
  });
}

List<_CategoryData> _categories() => [
  _CategoryData('Health', [
    _Rec(
      emoji: '🩺',
      name: 'General Medicine',
      description: 'Core clinical knowledge for everyday care.',
      goals: '• Quick references\n• Common protocols\n• Case notes',
      guide: 'Capture symptoms, differentials, tests, and treatment steps.',
    ),
    _Rec(
      emoji: '🧠',
      name: 'Mental Health',
      description: 'Conditions, care, and self-help practices.',
      goals: '• Disorders & criteria\n• Coping strategies\n• Resources',
      guide: 'Document psychoeducation, CBT tools, and helpline resources.',
    ),
    _Rec(
      emoji: '🏃‍♂️',
      name: 'Fitness',
      description: 'Training plans, recovery, and progress.',
      goals: '• Workout splits\n• PR tracking\n• Recovery notes',
      guide: 'Add programs, warm-ups, and post-workout notes.',
    ),
  ]),
  _CategoryData('Basic education', [
    _Rec(
      emoji: '🔤',
      name: 'English Basics',
      description: 'Grammar, vocabulary, and usage.',
      goals: '• Parts of speech\n• Vocab sets\n• Writing practice',
      guide: 'Keep rules, examples, and quick exercises.',
    ),
    _Rec(
      emoji: '🔢',
      name: 'Basic Math',
      description: 'Numbers, arithmetic, and fractions.',
      goals: '• Daily drills\n• Key tricks\n• Error log',
      guide: 'Add solved examples and tip sheets.',
    ),
    _Rec(
      emoji: '🌍',
      name: 'General Knowledge',
      description: 'Facts across science, history, and culture.',
      goals: '• Curate facts\n• Mini quizzes\n• Weekly recap',
      guide: 'Organize by topic and add flashcards.',
    ),
  ]),
  _CategoryData('Academic', [
    _Rec(
      emoji: '📝',
      name: 'Research Methods',
      description: 'Approaches to scientific inquiry.',
      goals: '• Choose design\n• Sampling plan\n• Validity checks',
      guide: 'Outline methods, instruments, and ethics.',
    ),
    _Rec(
      emoji: '📚',
      name: 'Literature Review',
      description: 'Survey and synthesize prior work.',
      goals: '• Collect sources\n• Summaries\n• Thematic map',
      guide: 'Track citations and gaps found.',
    ),
    _Rec(
      emoji: '🧮',
      name: 'Statistics',
      description: 'Descriptive and inferential methods.',
      goals: '• Assumptions\n• Tests used\n• Interpretations',
      guide: 'Keep formulas and example analyses.',
    ),
  ]),
  _CategoryData('Programming', [
    _Rec(
      emoji: '💻',
      name: 'Programming',
      description: 'Core CS and coding patterns.',
      goals: '• Data structures\n• Algorithms\n• Code snippets',
      guide: 'Store patterns, pitfalls, and templates.',
    ),
    _Rec(
      emoji: '🌐',
      name: 'Web Development',
      description: 'Frontend, backend, and APIs.',
      goals: '• Project setup\n• Components\n• Deploy notes',
      guide: 'Add cheatsheets and best practices.',
    ),
    _Rec(
      emoji: '🧠',
      name: 'AI & ML',
      description: 'Models, training, and evaluation.',
      goals: '• Datasets\n• Experiments\n• Metrics logs',
      guide: 'Keep notebooks, configs, and results.',
    ),
  ]),
  _CategoryData('Hobby', [
    _Rec(
      emoji: '🎵',
      name: 'Music',
      description: 'Theory, practice, and repertoire.',
      goals: '• Daily practice\n• Pieces list\n• Technique log',
      guide: 'Keep sheets, tabs, and recordings.',
    ),
    _Rec(
      emoji: '🎨',
      name: 'Drawing & Art',
      description: 'Sketching and digital art skills.',
      goals: '• Exercises\n• Style studies\n• Portfolio',
      guide: 'Collect brushes, palettes, and references.',
    ),
    _Rec(
      emoji: '🍳',
      name: 'Cooking',
      description: 'Recipes, techniques, and meal plans.',
      goals: '• Weekly menu\n• Skill drills\n• Favorites',
      guide: 'Save recipes and shopping lists.',
    ),
  ]),
];
