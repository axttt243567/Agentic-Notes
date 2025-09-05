import 'package:flutter/material.dart';
import 'main.dart';
import 'data/models.dart';
import 'data/image_search.dart';
import 'widgets/emoji_icon.dart';

class RecommendedSpacesPage extends StatelessWidget {
  const RecommendedSpacesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = _categories();
    // Build up to a total of 5 recommendations across all categories.
    const totalLimit = 5;
    var shown = 0;
    final sections = <Widget>[];

    for (final c in cats) {
      if (shown >= totalLimit) break;
      final remaining = totalLimit - shown;
      final recs = c.recs.take(remaining).toList();
      if (recs.isEmpty) continue;
      sections.addAll([
        _CategorySection(title: c.title, recommendations: recs),
        const SizedBox(height: 16),
      ]);
      shown += recs.length;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Recommended spaces')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: sections,
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
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EmojiIcon(rec.emoji, size: 16, color: const Color(0xFF71767B)),
          const SizedBox(width: 6),
          Flexible(child: Text(rec.name, overflow: TextOverflow.ellipsis)),
        ],
      ),
      onPressed: () async {
        final addedName = await Navigator.of(context).push<String>(
          MaterialPageRoute(builder: (_) => _SpacePreviewPage(rec: rec)),
        );
        if (!context.mounted) return;
        if (addedName != null && addedName.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Added "$addedName"')));
        }
      },
      shape: const StadiumBorder(),
      backgroundColor: const Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
    );
  }
}

class _SpacePreviewPage extends StatefulWidget {
  const _SpacePreviewPage({required this.rec});
  final _Rec rec;

  @override
  State<_SpacePreviewPage> createState() => _SpacePreviewPageState();
}

class _SpacePreviewPageState extends State<_SpacePreviewPage> {
  List<String> _images = const [];
  bool _loading = true;
  bool _hasKey = true;

  List<String> _parseGoals(String goals) {
    return goals
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => e.startsWith('•') ? e.substring(1).trim() : e)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    () async {
      final images = await fetchRelatedImages(widget.rec.name, limit: 8);
      if (!mounted) return;
      setState(() {
        _images = images;
        _loading = false;
        _hasKey = images.isNotEmpty; // if key missing, we get empty list
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = widget.rec;
    final goals = _parseGoals(rec.goals);
    return Scaffold(
      appBar: AppBar(title: const Text('Preview space')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // Hero image if available
          if (!_loading && _images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  _images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: const Color(0xFF1A1A1A),
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported, size: 32),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 2),
              EmojiIcon(rec.emoji, size: 28, color: Colors.white70),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  rec.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(rec.description, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          // Related images
          if (_loading)
            const SizedBox(
              height: 110,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_images.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Related images',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF71767B),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final url = _images[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: const Color(0xFF1A1A1A),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 24,
                              ),
                            ),
                            loadingBuilder: (c, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                color: const Color(0xFF1A1A1A),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: _images.length,
                  ),
                ),
              ],
            )
          else if (_hasKey)
            const SizedBox.shrink()
          else
            // Missing API key; keep UI clean without errors.
            const SizedBox.shrink(),
          const SizedBox(height: 16),
          const Divider(height: 24),
          Text(
            'Goals',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF71767B),
            ),
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            Text('—', style: theme.textTheme.bodyMedium)
          else
            ...goals.map(
              (g) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(g)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Guide',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF71767B),
            ),
          ),
          const SizedBox(height: 8),
          Text(rec.guide, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add space'),
            onPressed: () async {
              final db = DBProvider.of(context);
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              await db.upsertSpace(
                SpaceModel(
                  id: id,
                  name: widget.rec.name,
                  emoji: widget.rec.emoji,
                  description: widget.rec.description,
                  goals: widget.rec.goals,
                  guide: widget.rec.guide,
                ),
              );
              if (!context.mounted) return;
              Navigator.of(context).pop<String>(widget.rec.name);
            },
          ),
        ),
      ),
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
