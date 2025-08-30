import 'package:flutter/material.dart';
import 'main.dart';
import 'data/models.dart';

class MemoryInsightsPage extends StatelessWidget {
  const MemoryInsightsPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final db = DBProvider.of(context);
    final idx = db.getMemoryIndex(sessionId);
    final session = db.getChatSession(sessionId);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          session?.title.isNotEmpty == true ? session!.title : 'Insights',
        ),
      ),
      body: idx == null
          ? const Center(
              child: Text('No insights yet. Analyze from Memory tab.'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (idx.sessionSummary != null ||
                    (idx.sessionHashtags?.isNotEmpty ?? false))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session summary',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          if (idx.sessionSummary != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              idx.sessionSummary!,
                              style: const TextStyle(color: Color(0xFF71767B)),
                            ),
                          ],
                          if ((idx.sessionHashtags?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: idx.sessionHashtags!
                                  .map((h) => InputChip(label: Text(h)))
                                  .toList(growable: false),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                _AnalyticsCard(a: idx.analytics),
                const SizedBox(height: 12),
                ...idx.sections.map((sec) => _SectionCard(section: sec)),
              ],
            ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.a});
  final ChatAnalyticsModel a;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _Chip('Duration', '${a.durationSeconds}s'),
                _Chip('Messages', '${a.totalMessages}'),
                _Chip('Prompts', '${a.userRequestCount}'),
                _Chip('Responses', '${a.modelResponseCount}'),
                _Chip('User chars', '${a.userCharsTotal}'),
                _Chip('AI chars', '${a.modelCharsTotal}'),
                _Chip('User tokens', '${a.userTokensTotal}'),
                _Chip('AI tokens', '${a.modelTokensTotal}'),
                _Chip(
                  'Avg AI tokens/resp',
                  a.avgModelTokensPerResponse.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return InputChip(label: Text('$label: $value'), onPressed: () {});
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section});
  final CoreMemorySectionModel section;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              section.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: section.hashtags
                  .take(12)
                  .map((h) => InputChip(label: Text('#$h'), onPressed: () {}))
                  .toList(growable: false),
            ),
            const SizedBox(height: 8),
            Text(
              section.summary,
              style: const TextStyle(color: Color(0xFF71767B)),
            ),
            const Divider(height: 16),
            ...section.pieces.map(
              (p) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.summary,
                    style: const TextStyle(color: Color(0xFF71767B)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
