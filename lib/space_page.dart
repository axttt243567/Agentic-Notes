import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'chat_page.dart';
import 'main.dart';
import 'calendar_page.dart';
import 'data/models.dart';
import 'data/database_service.dart';
import 'data/pexels_service.dart';
import 'widgets/emoji_icon.dart';

class SpacePage extends StatefulWidget {
  const SpacePage({
    super.key,
    required this.spaceId,
    required this.name,
    required this.emoji,
  });
  final String spaceId;
  final String name;
  final String emoji;

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final List<_ResourceItem> _resources = [];
  SpaceModel? _space;
  StreamSubscription? _spacesSub;
  String? _pexelsKey;
  StreamSubscription? _pexelsSub;
  List<String> _bannerUrls = const [];
  bool _loadingBanner = false;
  // Schedules for routines linked to this space
  List<ScheduleModel> _schedules = const [];
  StreamSubscription? _schedulesSub;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tab.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    // Defer DB access until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = DBProvider.of(context);
      _hydrateSpace(db);
      _pexelsKey = db.currentPexelsApiKey;
      _maybeLoadBanner();
      // hydrate schedules for this space and subscribe to changes
      _schedules = db.currentSchedules;
      _schedulesSub?.cancel();
      _schedulesSub = db.schedulesStream.listen((list) {
        if (!mounted) return;
        setState(() => _schedules = list);
      });
      _spacesSub?.cancel();
      _spacesSub = db.spacesStream.listen((list) {
        if (!mounted) return;
        final s = list.firstWhere(
          (e) => e.id == widget.spaceId,
          orElse: () =>
              _space ??
              SpaceModel(
                id: widget.spaceId,
                name: widget.name,
                emoji: widget.emoji,
              ),
        );
        setState(() => _space = s);
      });
      _pexelsSub?.cancel();
      _pexelsSub = db.pexelsApiKeyStream.listen((v) {
        if (!mounted) return;
        setState(() {
          _pexelsKey = v;
        });
        _maybeLoadBanner();
      });
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _spacesSub?.cancel();
    _pexelsSub?.cancel();
    _schedulesSub?.cancel();
    super.dispose();
  }

  void _hydrateSpace(DatabaseService db) {
    final list = db.currentSpaces;
    final s = list.firstWhere(
      (e) => e.id == widget.spaceId,
      orElse: () => SpaceModel(
        id: widget.spaceId,
        name: widget.name,
        emoji: widget.emoji,
      ),
    );
    setState(() => _space = s);
  }

  Future<void> _maybeLoadBanner() async {
    final query = (_space?.name ?? widget.name).trim();
    if ((_pexelsKey ?? '').isEmpty || query.isEmpty) {
      setState(() => _bannerUrls = const []);
      return;
    }
    if (_loadingBanner) return;
    _loadingBanner = true;
    try {
      final svc = PexelsService(_pexelsKey!);
      final urls = await svc.searchImageUrls(query: query, perPage: 6);
      if (!mounted) return;
      setState(() => _bannerUrls = urls);
    } catch (_) {
      if (!mounted) return;
      setState(() => _bannerUrls = const []);
    } finally {
      _loadingBanner = false;
    }
  }

  Future<void> _saveSpace({
    String? description,
    String? goals,
    String? guide,
    String? tone,
    bool? advancedContext,
    String? metadataJson,
    bool? prefConcise,
    bool? prefExamples,
    bool? prefClarify,
  }) async {
    if (_space == null) return;
    final db = DBProvider.of(context);
    final updated = _space!.copyWith(
      description: description,
      goals: goals,
      guide: guide,
      tone: tone,
      advancedContext: advancedContext,
      metadataJson: metadataJson,
      prefConcise: prefConcise,
      prefExamples: prefExamples,
      prefClarify: prefClarify,
    );
    await db.upsertSpace(updated);
    if (!mounted) return;
    setState(() => _space = updated);
  }

  void _addResource() async {
    final added = await showModalBottomSheet<_ResourceItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddResourceSheet(),
    );
    if (added == null) return;
    if (!mounted) return;
    setState(() => _resources.add(added));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            EmojiIcon(
              _space?.emoji ?? widget.emoji,
              size: 20,
              color: Colors.white70,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _space?.name ?? widget.name,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Chat with AI',
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(
                  title: 'AI · ${widget.name}',
                  spaceId: widget.spaceId,
                ),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Study'),
            Tab(text: 'Routine'),
            Tab(text: 'Resources'),
            Tab(text: 'Gallery'),
            Tab(text: 'Personalization'),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 2
          ? FloatingActionButton.extended(
              onPressed: _addResource,
              icon: const Icon(Icons.add),
              label: const Text('Add resource'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
          _StudyTab(
            spaceId: widget.spaceId,
            spaceName: _space?.name ?? widget.name,
            description: _space?.description ?? '',
            goals: _space?.goals ?? '',
            guide: _space?.guide ?? '',
            onEditDescription: (text) => _saveSpace(description: text),
            onEditGoals: (text) => _saveSpace(goals: text),
            onEditGuide: (text) => _saveSpace(guide: text),
            banner: _BannerImage(urls: _bannerUrls),
          ),
          _SpaceRoutinesTab(
            spaceId: widget.spaceId,
            schedules: _schedules,
            banner: _BannerImage(urls: _bannerUrls),
            onOpenCalendar: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CalendarPage()));
            },
          ),
          _ResourcesTab(
            resources: _resources,
            onDelete: (id) {
              setState(() => _resources.removeWhere((e) => e.id == id));
            },
            banner: _BannerImage(urls: _bannerUrls),
          ),
          _PexelsGalleryTab(
            query: _space?.name ?? widget.name,
            pexelsKey: _pexelsKey,
            onTapReload: _maybeLoadBanner,
          ),
          _PersonalizationTab(
            currentTone: _space?.tone ?? '',
            advancedContext: _space?.advancedContext ?? true,
            onSetTone: (t) => _saveSpace(tone: t),
            onToggleAdvanced: (v) => _saveSpace(advancedContext: v),
            banner: _BannerImage(urls: _bannerUrls),
            metadataJson: _space?.metadataJson ?? '',
            onEditMetadata: (j) => _saveSpace(metadataJson: j),
            prefConcise: _space?.prefConcise ?? false,
            prefExamples: _space?.prefExamples ?? true,
            prefClarify: _space?.prefClarify ?? true,
            onToggleConcise: (v) => _saveSpace(prefConcise: v),
            onToggleExamples: (v) => _saveSpace(prefExamples: v),
            onToggleClarify: (v) => _saveSpace(prefClarify: v),
          ),
        ],
      ),
    );
  }
}

class _SpaceRoutinesTab extends StatelessWidget {
  const _SpaceRoutinesTab({
    required this.spaceId,
    required this.schedules,
    required this.banner,
    required this.onOpenCalendar,
  });
  final String spaceId;
  final List<ScheduleModel> schedules;
  final Widget banner;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final linked = schedules.where((s) => s.spaceId == spaceId).toList();
    if (linked.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          banner,
          const SizedBox(height: 12),
          const _SectionTitle('Routine'),
          const SizedBox(height: 8),
          _RoutinesEmpty(onOpenCalendar: onOpenCalendar),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: linked.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        if (i == 0) return banner;
        if (i == 1) return const _SectionTitle('Routine');
        final s = linked[i - 2];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2F3336)),
          ),
          child: ListTile(
            leading: EmojiIcon(
              s.emoji,
              size: 22,
              color: const Color(0xFF71767B),
            ),
            title: Text(s.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _metaLine(s),
                  style: const TextStyle(color: Color(0xFF71767B)),
                ),
                if ((s.description ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      s.description!,
                      style: const TextStyle(
                        color: Color(0xFF71767B),
                        fontSize: 12,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (s.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: -6,
                      children: [
                        for (final t in s.tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16181A),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF2F3336),
                              ),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: Color(0xFF71767B),
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              tooltip: 'Open calendar',
              icon: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF71767B),
              ),
              onPressed: onOpenCalendar,
            ),
          ),
        );
      },
    );
  }

  String _metaLine(ScheduleModel s) {
    final parts = <String>[];
    switch (s.recurrence) {
      case 'date':
        if ((s.date ?? '').isNotEmpty) parts.add(s.date!);
        break;
      case 'range':
        if ((s.startDate ?? '').isNotEmpty && (s.endDate ?? '').isNotEmpty) {
          parts.add('${s.startDate}→${s.endDate}');
        }
        parts.add(_formatDays(s.daysOfWeek));
        break;
      case 'weekly':
      default:
        parts.add(_formatDays(s.daysOfWeek));
    }
    if ((s.timeOfDay ?? '').isNotEmpty) {
      parts.add(
        (s.endTimeOfDay?.isNotEmpty ?? false)
            ? _formatRange(s.timeOfDay!, s.endTimeOfDay!)
            : _formatTime(s.timeOfDay!),
      );
    }
    if ((s.room ?? '').isNotEmpty) parts.add('Room ${s.room}');
    return parts.join(' · ');
  }

  String _formatDays(List<int> days) {
    const names = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return days.map((d) => names[d] ?? d.toString()).join(' ');
  }

  String _formatTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final suffix = h >= 12 ? 'PM' : 'AM';
    final hour12 = h % 12 == 0 ? 12 : h % 12;
    final mm = m.toString().padLeft(2, '0');
    return '$hour12:$mm $suffix';
  }

  String _formatRange(String a, String b) =>
      '${_formatTime(a)} - ${_formatTime(b)}';
}

class _RoutinesEmpty extends StatelessWidget {
  const _RoutinesEmpty({required this.onOpenCalendar});
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'No routines linked',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Link routines to this space from Calendar → Routines. They will appear here.',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenCalendar,
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('Open Calendar'),
          ),
        ],
      ),
    );
  }
}

class _StudyTab extends StatelessWidget {
  const _StudyTab({
    required this.spaceId,
    required this.spaceName,
    required this.description,
    required this.goals,
    required this.guide,
    required this.onEditDescription,
    required this.onEditGoals,
    required this.onEditGuide,
    required this.banner,
  });
  final String spaceId;
  final String spaceName;
  final String description;
  final String goals;
  final String guide;
  final ValueChanged<String> onEditDescription;
  final ValueChanged<String> onEditGoals;
  final ValueChanged<String> onEditGuide;
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        banner,
        const SizedBox(height: 12),
        _SectionTitle('Space details'),
        const SizedBox(height: 8),
        _EditableNoteCard(
          title: 'Description',
          text: description,
          placeholder: 'Add a brief overview of this space',
          onEdit: (txt) => onEditDescription(txt),
        ),
        const SizedBox(height: 8),
        _EditableNoteCard(
          title: 'Goals',
          text: goals,
          placeholder: 'List your goals or milestones',
          onEdit: (txt) => onEditGoals(txt),
        ),
        const SizedBox(height: 8),
        _EditableNoteCard(
          title: 'Guide',
          text: guide,
          placeholder: 'Write tips, steps, or a study plan',
          onEdit: (txt) => onEditGuide(txt),
        ),
        const SizedBox(height: 16),
        _SectionTitle('Study mode'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ActionCard(
              icon: Icons.flash_on_outlined,
              title: 'Quick test',
              subtitle: 'Short timed quiz to gauge your level',
              onTap: () => _showQuickTest(context),
            ),
            _ActionCard(
              icon: Icons.school_outlined,
              title: 'Prepare for exam',
              subtitle: 'Plan, practice, and review',
              onTap: () => _showExamPrep(context),
            ),
            _ActionCard(
              icon: Icons.topic_outlined,
              title: 'Prepare a topic',
              subtitle: 'Define a topic and get a plan',
              onTap: () => _prepareTopic(context),
            ),
            _ActionCard(
              icon: Icons.auto_awesome,
              title: 'Learn from AI',
              subtitle: 'Chat with an AI about $spaceName',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatPage(title: 'AI · $spaceName', spaceId: spaceId),
                ),
              ),
            ),
            _ActionCard(
              icon: Icons.insights_outlined,
              title: 'Progress tracking',
              subtitle: 'Track goals and streaks',
              onTap: () => _showProgress(context),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionTitle('Suggestions'),
        const SizedBox(height: 8),
        _SuggestionChips(
          chips: const [
            'Key formulas',
            'Core concepts',
            'Practice problems',
            'Mind map',
            'Flashcards',
          ],
          onSelected: (s) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Generate "$s" (UI only)')));
          },
        ),
      ],
    );
  }

  void _showQuickTest(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _QuickTestSheet(),
    );
  }

  void _showExamPrep(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ExamPrepSheet(),
    );
  }

  void _prepareTopic(BuildContext context) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Prepare a topic'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'e.g. Binary Trees'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Creating plan for "${ctrl.text}" (UI only)'),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showProgress(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _ProgressSheet(),
    );
  }
}

class _PersonalizationTab extends StatelessWidget {
  const _PersonalizationTab({
    required this.currentTone,
    required this.advancedContext,
    required this.onSetTone,
    required this.onToggleAdvanced,
    required this.banner,
    this.metadataJson = '',
    required this.onEditMetadata,
    this.prefConcise = false,
    this.prefExamples = true,
    this.prefClarify = true,
    required this.onToggleConcise,
    required this.onToggleExamples,
    required this.onToggleClarify,
  });
  final String currentTone;
  final bool advancedContext;
  final ValueChanged<String> onSetTone;
  final ValueChanged<bool> onToggleAdvanced;
  final Widget banner;
  final String metadataJson;
  final ValueChanged<String> onEditMetadata;
  final bool prefConcise;
  final bool prefExamples;
  final bool prefClarify;
  final ValueChanged<bool> onToggleConcise;
  final ValueChanged<bool> onToggleExamples;
  final ValueChanged<bool> onToggleClarify;

  static const List<String> tones = [
    'Chatty',
    'Witty',
    'Straight shooting',
    'Encouraging',
    'Gen Z',
    'Traditional',
    'Forward thinking',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        banner,
        const SizedBox(height: 12),
        const _SectionTitle('Personalization'),
        const SizedBox(height: 8),
        _PersonalizationCard(
          title: 'AI Tone',
          subtitle:
              'Choose how the AI talks inside this space. You can change anytime.',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tones)
                ChoiceChip(
                  label: Text(t),
                  selected: currentTone == t,
                  onSelected: (_) => onSetTone(t),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PersonalizationCard(
          title: 'Advanced context',
          subtitle:
              'Let AI use this space’s description, goals, guide, resources, routines, and past chats for better answers.',
          child: SwitchListTile(
            value: advancedContext,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable advanced context'),
            subtitle: const Text(
              'Recommended. Turn off if you want short, standalone replies.',
              style: TextStyle(color: Color(0xFF71767B)),
            ),
            onChanged: onToggleAdvanced,
          ),
        ),
        const SizedBox(height: 12),
        _PersonalizationCard(
          title: 'AI Preferences',
          subtitle: 'Tune how answers are shaped.',
          child: Column(
            children: [
              SwitchListTile(
                value: prefConcise,
                contentPadding: EdgeInsets.zero,
                title: const Text('Prefer concise answers'),
                onChanged: onToggleConcise,
              ),
              SwitchListTile(
                value: prefExamples,
                contentPadding: EdgeInsets.zero,
                title: const Text('Prefer examples in answers'),
                onChanged: onToggleExamples,
              ),
              SwitchListTile(
                value: prefClarify,
                contentPadding: EdgeInsets.zero,
                title: const Text('Ask clarifying questions when needed'),
                onChanged: onToggleClarify,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _PersonalizationCard(
          title: 'Metadata (JSON)',
          subtitle:
              'Optional JSON with extra context for this space. Keep it short and meaningful.',
          child: _MetadataEditor(initial: metadataJson, onSave: onEditMetadata),
        ),
      ],
    );
  }
}

class _PersonalizationCard extends StatelessWidget {
  const _PersonalizationCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Color(0xFF71767B))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _MetadataEditor extends StatefulWidget {
  const _MetadataEditor({required this.initial, required this.onSave});
  final String initial;
  final ValueChanged<String> onSave;

  @override
  State<_MetadataEditor> createState() => _MetadataEditorState();
}

class _MetadataEditorState extends State<_MetadataEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _MetadataEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _ctrl.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          minLines: 4,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: '{\n  "notes": "Any extra context"\n}',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => widget.onSave(_ctrl.text.trim()),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }
}

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({
    required this.resources,
    required this.onDelete,
    required this.banner,
  });
  final List<_ResourceItem> resources;
  final ValueChanged<String> onDelete;
  final Widget banner;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [banner, const SizedBox(height: 12), const _ResourcesEmpty()],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = resources[i];
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2F3336)),
          ),
          child: ListTile(
            leading: Icon(_iconFor(r.type), color: Color(0xFF71767B)),
            title: Text(r.title),
            subtitle: () {
              if (r.localPath != null && r.localPath!.isNotEmpty) {
                return Text(
                  'Local file · ${r.localPath!.split('\\').last}',
                  style: const TextStyle(color: Color(0xFF71767B)),
                );
              }
              if (r.url != null && r.url!.isNotEmpty) {
                return Text(
                  r.url!,
                  style: const TextStyle(color: Color(0xFF71767B)),
                );
              }
              return null;
            }(),
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {
                if (v == 'delete') onDelete(r.id);
                if (v == 'open') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        r.localPath != null
                            ? 'Open local (UI only)'
                            : 'Open (UI only)',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(_ResourceType t) {
    switch (t) {
      case _ResourceType.pdf:
        return Icons.picture_as_pdf_outlined;
      case _ResourceType.youtube:
        return Icons.ondemand_video_outlined;
      case _ResourceType.link:
        return Icons.link_outlined;
      case _ResourceType.text:
        return Icons.notes_outlined;
    }
  }
}

class _BannerImage extends StatelessWidget {
  const _BannerImage({required this.urls});
  final List<String> urls;
  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return _fallbackBanner(context);
    }
    final url = urls.first;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(url, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackBanner(BuildContext context) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
        color: const Color(0xFF0A0A0A),
      ),
      child: const Center(
        child: Text(
          'Add Pexels API key in Profile to load images',
          style: TextStyle(color: Color(0xFF71767B)),
        ),
      ),
    );
  }
}

class _PexelsGalleryTab extends StatefulWidget {
  const _PexelsGalleryTab({
    required this.query,
    required this.pexelsKey,
    required this.onTapReload,
  });
  final String query;
  final String? pexelsKey;
  final Future<void> Function() onTapReload;

  @override
  State<_PexelsGalleryTab> createState() => _PexelsGalleryTabState();
}

class _PexelsGalleryTabState extends State<_PexelsGalleryTab> {
  List<String> _urls = const [];
  bool _loading = false;
  String? _error;

  @override
  void didUpdateWidget(covariant _PexelsGalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query ||
        oldWidget.pexelsKey != widget.pexelsKey) {
      _fetch();
    }
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final key = widget.pexelsKey;
    if ((key ?? '').isEmpty) {
      setState(() {
        _urls = const [];
        _error = 'Missing Pexels API key.';
      });
      return;
    }
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final svc = PexelsService(key!);
      final urls = await svc.searchImageUrls(query: widget.query, perPage: 30);
      if (!mounted) return;
      setState(() => _urls = urls);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Images for "${widget.query}"',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Reload',
                icon: const Icon(Icons.refresh),
                onPressed: _fetch,
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if ((_error ?? '').isNotEmpty) {
                return _missingKeyOrError(context, _error!);
              }
              if (_loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_urls.isEmpty) {
                return _missingKeyOrError(context, 'No images found.');
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _urls.length,
                itemBuilder: (context, i) {
                  final u = _urls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(u, fit: BoxFit.cover),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.open_in_new, size: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _missingKeyOrError(BuildContext context, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 44, color: Colors.white60),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(color: Color(0xFF71767B))),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                await widget.onTapReload();
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Configure in Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResourcesEmpty extends StatelessWidget {
  const _ResourcesEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.folder_open, size: 44, color: Colors.white60),
          SizedBox(height: 12),
          Text(
            'No resources yet',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Add PDFs, links, and notes to your space.',
            style: TextStyle(color: Colors.white70),
          ),
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
  _ResourceType _type = _ResourceType.pdf;
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  String? _pickedPdfPath;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    _textCtrl.dispose();
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
                  color: Color(0xFF2F3336),
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
                for (final t in _ResourceType.values)
                  ChoiceChip(
                    label: Text(_labelFor(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            if (_type == _ResourceType.pdf) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _pickedPdfPath == null
                          ? 'No PDF selected'
                          : _pickedPdfPath!.split('\\').last,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF71767B)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Pick PDF'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text('or', style: TextStyle(color: Color(0xFF71767B))),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == _ResourceType.pdf ||
                _type == _ResourceType.youtube ||
                _type == _ResourceType.link)
              TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: _type == _ResourceType.pdf
                      ? 'PDF URL'
                      : _type == _ResourceType.youtube
                      ? 'YouTube URL'
                      : 'Link URL',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            if (_type == _ResourceType.text) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _textCtrl,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  hintText: 'Paste or write something here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(onPressed: _submit, child: const Text('Add')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _labelFor(_ResourceType t) {
    switch (t) {
      case _ResourceType.pdf:
        return 'PDF';
      case _ResourceType.youtube:
        return 'YouTube';
      case _ResourceType.link:
        return 'Link';
      case _ResourceType.text:
        return 'Text';
    }
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    switch (_type) {
      case _ResourceType.pdf:
        final url = _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim();
        if ((url == null || url.isEmpty) && (_pickedPdfPath == null)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pick a PDF or enter a PDF URL')),
          );
          return;
        }
        Navigator.of(context).pop(
          _ResourceItem(
            id: id,
            title: title,
            type: _type,
            url: url,
            localPath: _pickedPdfPath,
          ),
        );
        return;
      case _ResourceType.youtube:
      case _ResourceType.link:
        final url2 = _urlCtrl.text.trim();
        if (url2.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid URL')),
          );
          return;
        }
        Navigator.of(
          context,
        ).pop(_ResourceItem(id: id, title: title, type: _type, url: url2));
        return;
      case _ResourceType.text:
        final text = _textCtrl.text.trim();
        Navigator.of(
          context,
        ).pop(_ResourceItem(id: id, title: title, type: _type, note: text));
        return;
    }
  }

  Future<void> _pickPdf() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!mounted) return;
      if (res != null && res.files.isNotEmpty) {
        setState(() => _pickedPdfPath = res.files.single.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick file: $e')));
    }
  }
}

enum _ResourceType { pdf, youtube, link, text }

class _ResourceItem {
  final String id;
  final String title;
  final _ResourceType type;
  final String? url;
  final String? note;
  final String? localPath; // for local PDFs
  _ResourceItem({
    required this.id,
    required this.title,
    required this.type,
    this.url,
    this.note,
    this.localPath,
  });
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFF2F3336)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Color(0xFF71767B)),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF71767B), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: Color(0xFF71767B),
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({required this.chips, required this.onSelected});
  final List<String> chips;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final c in chips)
          InputChip(
            label: Text(c),
            onPressed: () => onSelected(c),
            shape: const StadiumBorder(),
            backgroundColor: Color(0xFF0A0A0A),
            side: const BorderSide(color: Color(0xFF2F3336)),
          ),
      ],
    );
  }
}

class _EditableNoteCard extends StatelessWidget {
  const _EditableNoteCard({
    required this.title,
    required this.text,
    required this.placeholder,
    required this.onEdit,
  });
  final String title;
  final String text;
  final String placeholder;
  final ValueChanged<String> onEdit;

  @override
  Widget build(BuildContext context) {
    final hasText = text.trim().isNotEmpty;
    return InkWell(
      onTap: () async {
        final updated = await _editText(context, title, text);
        if (updated != null) onEdit(updated);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2F3336)),
        ),
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              hasText ? text : placeholder,
              style: TextStyle(
                color: hasText
                    ? const Color(0xFFE7E9EA)
                    : const Color(0xFF71767B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _editText(
    BuildContext context,
    String title,
    String initial,
  ) async {
    final ctrl = TextEditingController(text: initial);
    String? result;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets;
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
                  'Edit $title',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      child: const Text('Cancel'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        result = ctrl.text.trim();
                        Navigator.of(ctx).maybePop();
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result;
  }
}

class _QuickTestSheet extends StatelessWidget {
  const _QuickTestSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                  color: Color(0xFF2F3336),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Quick test',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('Answer a few questions (UI only):'),
            const SizedBox(height: 12),
            const _MCQ(
              question: '1) What is Big-O of binary search?',
              options: ['O(n)', 'O(log n)', 'O(n log n)', 'O(1)'],
              answerIndex: 1,
            ),
            const _MCQ(
              question: '2) Derivative of sin(x)?',
              options: ['-cos(x)', 'cos(x)', 'sin(x)', 'tan(x)'],
              answerIndex: 1,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MCQ extends StatefulWidget {
  const _MCQ({
    required this.question,
    required this.options,
    required this.answerIndex,
  });
  final String question;
  final List<String> options;
  final int answerIndex;
  @override
  State<_MCQ> createState() => _MCQState();
}

class _MCQState extends State<_MCQ> {
  int? _selected;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF2F3336)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < widget.options.length; i++)
            RadioListTile<int>(
              // ignore: deprecated_member_use
              value: i,
              // ignore: deprecated_member_use
              groupValue: _selected,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _selected = v),
              title: Text(widget.options[i]),
            ),
          if (_selected != null)
            Text(
              _selected == widget.answerIndex ? 'Correct!' : 'Try again',
              style: TextStyle(
                color: _selected == widget.answerIndex
                    ? Colors.lightGreenAccent
                    : Colors.orangeAccent,
              ),
            ),
        ],
      ),
    );
  }
}

class _ExamPrepSheet extends StatelessWidget {
  const _ExamPrepSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                  color: Color(0xFF2F3336),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Exam prep',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const _ChecklistItem('Syllabus breakdown'),
            const _ChecklistItem('Daily practice schedule'),
            const _ChecklistItem('Weekly mock tests'),
            const _ChecklistItem('Revision plan'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Looks good'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistItem extends StatefulWidget {
  const _ChecklistItem(this.text);
  final String text;
  @override
  State<_ChecklistItem> createState() => _ChecklistItemState();
}

class _ChecklistItemState extends State<_ChecklistItem> {
  bool _done = false;
  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: _done,
      onChanged: (v) => setState(() => _done = v ?? false),
      title: Text(widget.text),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _ProgressSheet extends StatelessWidget {
  const _ProgressSheet();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
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
                  color: Color(0xFF2F3336),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'Progress',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _progress('Reading', .6),
            const SizedBox(height: 10),
            _progress('Practice', .35),
            const SizedBox(height: 10),
            _progress('Mock tests', .2),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: const [
                _StatChip(icon: Icons.auto_awesome, label: 'Streak 3d'),
                _StatChip(icon: Icons.timer_outlined, label: 'Weekly 2.5h'),
                _StatChip(icon: Icons.task_alt_outlined, label: 'Tasks 8/20'),
              ],
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: value, minHeight: 8),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return InputChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      shape: const StadiumBorder(),
      backgroundColor: Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
      onPressed: null,
    );
  }
}
