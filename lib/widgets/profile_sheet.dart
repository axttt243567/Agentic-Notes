import 'package:flutter/material.dart';
import 'add_api_key_sheet.dart';
import 'dart:async';
import '../main.dart';
import '../data/models.dart';
import '../onboarding.dart';
import '../profile_page.dart';

class ProfileSheet extends StatefulWidget {
  const ProfileSheet({super.key});

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final List<ApiKeyModel> _keys = [];
  StreamSubscription? _sub;
  StreamSubscription? _activeSub;
  String? _activeId;
  final List<SpaceModel> _spaces = [];
  StreamSubscription? _spacesSub;
  String? _pexelsKey;
  StreamSubscription? _pexelsSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sub?.cancel();
    _activeSub?.cancel();
    _spacesSub?.cancel();
    _pexelsSub?.cancel();
    final db = DBProvider.of(context);
    _keys
      ..clear()
      ..addAll(db.currentApiKeys);
    _activeId = db.currentActiveApiKeyId;
    _spaces
      ..clear()
      ..addAll(db.currentSpaces);
    _pexelsKey = db.currentPexelsApiKey;
    _sub = db.apiKeysStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _keys
          ..clear()
          ..addAll(list);
      });
    });
    _activeSub = db.activeApiKeyStream.listen((id) {
      if (!mounted) return;
      setState(() => _activeId = id);
    });
    _spacesSub = db.spacesStream.listen((list) {
      if (!mounted) return;
      setState(() {
        _spaces
          ..clear()
          ..addAll(list);
      });
    });
    _pexelsSub = db.pexelsApiKeyStream.listen((v) {
      if (!mounted) return;
      setState(() => _pexelsKey = v);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _activeSub?.cancel();
    _spacesSub?.cancel();
    _pexelsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            // View profile
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.person_outline,
                  color: Color(0xFF71767B),
                ),
                title: const Text('View your profile'),
                subtitle: const Text('See your profile details'),
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.push(
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Internal setting
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2F3336)),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.tune_outlined,
                  color: Color(0xFF71767B),
                ),
                title: const Text('Internal setting'),
                subtitle: const Text('Advanced controls and data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openInternalSettings,
              ),
            ),
            const SizedBox(height: 16),
            // About us
            _aboutCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _addApiKey() async {
    final db = DBProvider.of(context);
    final res = await showModalBottomSheet<ApiKeyData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const AddApiKeySheet(),
    );
    if (res != null && mounted) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      await db.upsertApiKey(
        ApiKeyModel(id: id, name: res.name, value: res.value),
      );
    }
  }

  Widget _minimalKeyTile({
    required ApiKeyModel keyData,
    required VoidCallback onManage,
  }) {
    final last4 = keyData.value.length >= 4
        ? keyData.value.substring(keyData.value.length - 4)
        : keyData.value;
    final masked = '•••• •••• •••• $last4';
    final isActive = keyData.id == _activeId;
    return ListTile(
      leading: Icon(
        isActive ? Icons.check_circle : Icons.vpn_key_outlined,
        color: isActive ? Colors.lightGreenAccent : const Color(0xFF71767B),
      ),
      title: Text(keyData.name),
      subtitle: Text(masked, style: const TextStyle(color: Color(0xFF71767B))),
      trailing: InputChip(
        label: const Text('manage'),
        avatar: const Icon(Icons.settings_outlined, size: 18),
        onPressed: onManage,
        shape: const StadiumBorder(),
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Color(0xFF2F3336)),
      ),
    );
  }

  Future<void> _manageKey(ApiKeyModel key, int index) async {
    final db = DBProvider.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isActive = _activeId == key.id;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: Icon(
                    isActive
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(isActive ? 'Currently in use' : 'Use this key'),
                  onTap: isActive
                      ? null
                      : () async {
                          final navigator = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          await db.setActiveApiKeyId(key.id);
                          navigator.maybePop();
                          messenger.showSnackBar(
                            SnackBar(content: Text('Using "${key.name}"')),
                          );
                        },
                ),
                if (isActive)
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline),
                    title: const Text('Stop using this key'),
                    onTap: () async {
                      final navigator = Navigator.of(ctx);
                      await db.clearActiveApiKey();
                      navigator.maybePop();
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('Check'),
                  subtitle: const Text('UI only'),
                  onTap: () {
                    Navigator.of(ctx).maybePop();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Key looks valid (UI only)'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Delete'),
                  onTap: () async {
                    Navigator.of(ctx).maybePop();
                    final ok = await _confirm(
                      context,
                      'Delete API key "${key.name}"?',
                    );
                    if (ok == true && mounted) {
                      await db.deleteApiKey(key.id);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _aboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2F3336)),
      ),
      child: const ListTile(
        leading: Icon(Icons.info_outline),
        title: Text('Agentic Notes'),
        subtitle: Text('A lightweight UI demo. Front-end only.'),
      ),
    );
  }

  Widget _section(
    BuildContext ctx, {
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            title,
            style: Theme.of(
              ctx,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<bool?> _confirm(BuildContext context, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return ok;
  }

  // Spaces quick-create moved into Internal setting; helpers removed from main sheet

  Future<void> _confirmAndWipeAll() async {
    final ok = await _confirm(
      context,
      'This will permanently delete all app data on this device. Continue?',
    );
    if (ok != true || !mounted) return;
    final db = DBProvider.of(context);
    await db.wipeAllData();
    if (!mounted) return;
    // Pop the profile sheet
    Navigator.of(context).pop();
    // Restart flow by replacing with Onboarding
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingFlow()),
      (route) => false,
    );
  }

  Future<void> _managePexelsKey() async {
    final controller = TextEditingController(text: _pexelsKey ?? '');
    final db = DBProvider.of(context);
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
                  'Pexels API key',
                  style: Theme.of(
                    ctx,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'API key',
                    hintText: 'Paste your Pexels API key',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      child: const Text('Close'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        await db.setPexelsApiKey(null);
                        if (ctx.mounted) Navigator.of(ctx).maybePop();
                      },
                      child: const Text('Clear'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final v = controller.text.trim();
                        await db.setPexelsApiKey(v.isEmpty ? null : v);
                        if (ctx.mounted) Navigator.of(ctx).maybePop();
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
  }

  void _openInternalSettings() async {
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
          child: StatefulBuilder(
            builder: (ctx, setStfState) => SingleChildScrollView(
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
                    'Internal setting',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // API entry card -> opens API settings sheet
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2F3336)),
                    ),
                    child: ListTile(
                      leading: const Icon(
                        Icons.api_outlined,
                        color: Color(0xFF71767B),
                      ),
                      title: const Text('API'),
                      subtitle: const Text(
                        'Manage main API keys and Pexels API key',
                        style: TextStyle(color: Color(0xFF71767B)),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _openApiSettings,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Spaces
                  _section(
                    ctx,
                    title: 'Spaces',
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF2F3336),
                              ),
                            ),
                            child: Text(
                              '${_spaces.length} space${_spaces.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF71767B)),
                            ),
                          ),
                          const Spacer(),
                          InputChip(
                            label: const Text('+ new'),
                            onPressed: () async {
                              final res =
                                  await showModalBottomSheet<
                                    _SpaceQuickCreateResult
                                  >(
                                    context: ctx,
                                    isScrollControlled: true,
                                    backgroundColor: Theme.of(
                                      ctx,
                                    ).colorScheme.surface,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    builder: (c) => const _CreateSpaceSheet(),
                                  );
                              if (res != null && mounted) {
                                final db = DBProvider.of(context);
                                final id = DateTime.now().millisecondsSinceEpoch
                                    .toString();
                                await db.upsertSpace(
                                  SpaceModel(
                                    id: id,
                                    name: res.name,
                                    emoji: res.emoji,
                                  ),
                                );
                                if (ctx.mounted) setStfState(() {});
                              }
                            },
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Color(0xFF2F3336)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_spaces.isEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final s in const [
                              ['💻', 'Programming'],
                              ['🧪', 'Chemistry'],
                              ['🧮', 'Math'],
                              ['🪐', 'Physics'],
                              ['🧬', 'Biology'],
                              ['🌍', 'Geography'],
                            ])
                              InputChip(
                                label: Text('${s[0]} ${s[1]}'),
                                onPressed: () async {
                                  final db = DBProvider.of(context);
                                  final id = DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString();
                                  await db.upsertSpace(
                                    SpaceModel(id: id, name: s[1], emoji: s[0]),
                                  );
                                  if (ctx.mounted) setStfState(() {});
                                },
                                shape: const StadiumBorder(),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(
                                  color: Color(0xFF2F3336),
                                ),
                              ),
                          ],
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final sp in _spaces)
                              InputChip(
                                label: Text('${sp.emoji} ${sp.name}'),
                                onPressed: () {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Open spaces from Home. Profile shows list only.',
                                      ),
                                    ),
                                  );
                                },
                                shape: const StadiumBorder(),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(
                                  color: Color(0xFF2F3336),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Suggestions
                  _section(
                    ctx,
                    title: 'Suggestions',
                    children: [
                      ListTile(
                        leading: const Icon(Icons.settings_outlined),
                        title: const Text('Manage suggestions'),
                        subtitle: const Text('Opens suggestions settings'),
                        onTap: () {
                          Navigator.of(ctx).maybePop();
                          // Close profile and signal to open settings on Home
                          Navigator.of(context).pop('open_suggestions');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Danger zone
                  _section(
                    ctx,
                    title: 'Danger zone',
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2F3336)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.delete_forever_outlined,
                            color: Colors.redAccent,
                          ),
                          title: const Text(
                            'Delete all data',
                            style: TextStyle(color: Color(0xFFE7E9EA)),
                          ),
                          subtitle: const Text(
                            'Clears API keys, chats, spaces, students, and profile',
                            style: TextStyle(color: Color(0xFF71767B)),
                          ),
                          onTap: () async {
                            Navigator.of(ctx).maybePop();
                            await _confirmAndWipeAll();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openApiSettings() async {
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
          child: StatefulBuilder(
            builder: (ctx, setStfState) => SingleChildScrollView(
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
                    'API settings',
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Main API Keys
                  _section(
                    ctx,
                    title: 'Main API keys',
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFF2F3336),
                              ),
                            ),
                            child: Text(
                              '${_keys.length} key${_keys.length == 1 ? '' : 's'}',
                              style: const TextStyle(color: Color(0xFF71767B)),
                            ),
                          ),
                          const Spacer(),
                          InputChip(
                            label: const Text('+ add'),
                            onPressed: () async {
                              await _addApiKey();
                              if (ctx.mounted) setStfState(() {});
                            },
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Color(0xFF2F3336)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_keys.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.vpn_key_outlined,
                                color: Color(0xFF71767B),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'No API keys yet',
                                  style: TextStyle(color: Color(0xFF71767B)),
                                ),
                              ),
                              InputChip(
                                label: const Text('+ add'),
                                onPressed: () async {
                                  await _addApiKey();
                                  if (ctx.mounted) setStfState(() {});
                                },
                                shape: const StadiumBorder(),
                                backgroundColor: Colors.transparent,
                                side: const BorderSide(
                                  color: Color(0xFF2F3336),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2F3336)),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _keys.length; i++) ...[
                                _minimalKeyTile(
                                  keyData: _keys[i],
                                  onManage: () async {
                                    await _manageKey(_keys[i], i);
                                    if (ctx.mounted) setStfState(() {});
                                  },
                                ),
                                if (i < _keys.length - 1)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Color(0xFF2F3336),
                                    indent: 48,
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Pexels API key
                  _section(
                    ctx,
                    title: 'Pexels API key',
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2F3336)),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFF71767B),
                          ),
                          title: Text(
                            _pexelsKey == null || _pexelsKey!.isEmpty
                                ? 'Not configured'
                                : 'Configured',
                          ),
                          subtitle: const Text(
                            'Used for loading banner and gallery images.',
                            style: TextStyle(color: Color(0xFF71767B)),
                          ),
                          trailing: InputChip(
                            label: const Text('manage'),
                            avatar: const Icon(
                              Icons.settings_outlined,
                              size: 18,
                            ),
                            onPressed: () async {
                              await _managePexelsKey();
                              if (ctx.mounted) setStfState(() {});
                            },
                            shape: const StadiumBorder(),
                            backgroundColor: Colors.transparent,
                            side: const BorderSide(color: Color(0xFF2F3336)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).maybePop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpaceQuickCreateResult {
  final String emoji;
  final String name;
  const _SpaceQuickCreateResult(this.emoji, this.name);
}

class _CreateSpaceSheet extends StatefulWidget {
  const _CreateSpaceSheet();

  @override
  State<_CreateSpaceSheet> createState() => _CreateSpaceSheetState();
}

class _CreateSpaceSheetState extends State<_CreateSpaceSheet> {
  final _nameCtrl = TextEditingController();
  final _emojiCtrl = TextEditingController(text: '📚');

  @override
  void dispose() {
    _nameCtrl.dispose();
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Text(
              'New space',
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
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Programming',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
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
                FilledButton(onPressed: _submit, child: const Text('Create')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameCtrl.text.trim();
    final emoji = _emojiCtrl.text.trim().isEmpty ? '📚' : _emojiCtrl.text;
    if (name.isEmpty) return;
    Navigator.of(context).pop(_SpaceQuickCreateResult(emoji, name));
  }
}

// legacy private _ApiKey class removed in favor of persistent ApiKeyModel
