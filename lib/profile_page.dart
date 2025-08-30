import 'package:flutter/material.dart';
import 'main.dart';
import 'data/models.dart';

/// Minimal profile page to view the user's profile details.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<UserProfileModel>(
          stream: DBProvider.of(context).profileStream,
          initialData: DBProvider.of(context).currentProfile,
          builder: (context, snapshot) {
            final profile =
                snapshot.data ?? const UserProfileModel(displayName: 'You');
            final chips = _buildChips(profile);
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _headerCard(theme, profile),
                const SizedBox(height: 12),
                if (chips.isNotEmpty) _chipsWrap(chips) else _emptyHint(),
                const SizedBox(height: 12),
                _detailsCard(context, profile),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _headerCard(ThemeData theme, UserProfileModel profile) {
    final initials = _initials(profile.displayName);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE7E9EA),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.displayName.isEmpty ? 'You' : profile.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitle(profile),
                    style: const TextStyle(
                      color: Color(0xFF71767B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r"\s+"));
    if (parts.isEmpty) return 'Y';
    if (parts.length == 1)
      return parts.first.isEmpty ? 'Y' : parts.first[0].toUpperCase();
    return (parts[0].isNotEmpty ? parts[0][0] : 'Y').toUpperCase() +
        (parts[1].isNotEmpty ? parts[1][0] : '').toUpperCase();
  }

  String _subtitle(UserProfileModel p) {
    final bits = <String>[];
    if ((p.rollNo ?? '').isNotEmpty) bits.add('Roll ${p.rollNo}');
    if ((p.branch ?? '').isNotEmpty) bits.add(p.branch!);
    if ((p.semester ?? 0) > 0) bits.add('Sem-${p.semester}');
    return bits.isEmpty ? 'Profile details' : bits.join(' · ');
  }

  List<Widget> _buildChips(UserProfileModel p) {
    final chips = <Widget>[];
    if ((p.section ?? '').isNotEmpty) {
      chips.add(_chip('Section: ${p.section}'));
    }
    if ((p.group ?? '').isNotEmpty) {
      chips.add(_chip('Group: ${p.group}'));
    }
    if ((p.branch ?? '').isNotEmpty) {
      chips.add(_chip('Branch: ${p.branch}'));
    }
    if ((p.semester ?? 0) > 0) {
      chips.add(_chip('Semester: Sem-${p.semester}'));
    }
    return chips;
  }

  Widget _chipsWrap(List<Widget> chips) =>
      Wrap(spacing: 8, runSpacing: 8, children: chips);

  Widget _chip(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFF2F3336)),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFFE7E9EA))),
  );

  Widget _emptyHint() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0A0A),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFF2F3336)),
    ),
    child: const Text(
      'No extra details yet. Set your section, group, branch, and semester during onboarding.',
      style: TextStyle(color: Color(0xFF71767B)),
    ),
  );

  Widget _detailsCard(BuildContext context, UserProfileModel p) {
    Widget row(IconData icon, String label, String? value) {
      final has = (value ?? '').isNotEmpty;
      return ListTile(
        leading: Icon(icon, color: const Color(0xFF71767B)),
        title: Text(label),
        subtitle: Text(
          has ? value! : 'Not set',
          style: const TextStyle(color: Color(0xFF71767B)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: Column(
        children: [
          row(Icons.badge_outlined, 'Roll number', p.rollNo),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF2F3336),
            indent: 56,
          ),
          row(Icons.school_outlined, 'Section', p.section),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF2F3336),
            indent: 56,
          ),
          row(Icons.groups_outlined, 'Group', p.group),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF2F3336),
            indent: 56,
          ),
          row(Icons.account_tree_outlined, 'Branch', p.branch),
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFF2F3336),
            indent: 56,
          ),
          ListTile(
            leading: const Icon(
              Icons.timeline_outlined,
              color: Color(0xFF71767B),
            ),
            title: const Text('Semester'),
            subtitle: Text(
              (p.semester ?? 0) > 0 ? 'Sem-${p.semester}' : 'Not set',
              style: const TextStyle(color: Color(0xFF71767B)),
            ),
          ),
        ],
      ),
    );
  }
}
