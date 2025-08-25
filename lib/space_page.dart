import 'package:flutter/material.dart';
import 'chat_page.dart';

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

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
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
    setState(() => _resources.add(added));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Text(widget.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.name,
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
            icon: const Icon(Icons.star_border),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatPage(title: 'AI · ${widget.name}'),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Study'),
            Tab(text: 'Resources'),
          ],
        ),
      ),
      floatingActionButton: _tab.index == 1
          ? FloatingActionButton.extended(
              onPressed: _addResource,
              icon: const Icon(Icons.add),
              label: const Text('Add resource'),
            )
          : null,
      body: TabBarView(
        controller: _tab,
        children: [
          _StudyTab(spaceName: widget.name),
          _ResourcesTab(
            resources: _resources,
            onDelete: (id) {
              setState(() => _resources.removeWhere((e) => e.id == id));
            },
          ),
        ],
      ),
    );
  }
}

class _StudyTab extends StatelessWidget {
  const _StudyTab({required this.spaceName});
  final String spaceName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
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
              icon: Icons.star_border,
              title: 'Learn from AI',
              subtitle: 'Chat with an AI about $spaceName',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatPage(title: 'AI · $spaceName'),
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

class _ResourcesTab extends StatelessWidget {
  const _ResourcesTab({required this.resources, required this.onDelete});
  final List<_ResourceItem> resources;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) {
      return const _ResourcesEmpty();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: resources.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final r = resources[i];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: ListTile(
            leading: Icon(_iconFor(r.type), color: Colors.white70),
            title: Text(r.title),
            subtitle: r.url == null
                ? null
                : Text(r.url!, style: const TextStyle(color: Colors.white70)),
            trailing: PopupMenuButton<String>(
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'open', child: Text('Open')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {
                if (v == 'delete') onDelete(r.id);
                if (v == 'open') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Open (UI only)')),
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
      case _ResourceType.youtube:
      case _ResourceType.link:
        final url = _urlCtrl.text.trim();
        Navigator.of(
          context,
        ).pop(_ResourceItem(id: id, title: title, type: _type, url: url));
        return;
      case _ResourceType.text:
        final text = _textCtrl.text.trim();
        Navigator.of(
          context,
        ).pop(_ResourceItem(id: id, title: title, type: _type, note: text));
        return;
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
  _ResourceItem({
    required this.id,
    required this.title,
    required this.type,
    this.url,
    this.note,
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
            color: Colors.white10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
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
        color: Colors.white70,
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
            backgroundColor: Colors.white10,
            side: const BorderSide(color: Colors.white12),
          ),
      ],
    );
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
                  color: Colors.white24,
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
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
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
              value: i,
              groupValue: _selected,
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
                  color: Colors.white24,
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
                  color: Colors.white24,
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
      backgroundColor: Colors.white10,
      side: const BorderSide(color: Colors.white12),
      onPressed: null,
    );
  }
}
