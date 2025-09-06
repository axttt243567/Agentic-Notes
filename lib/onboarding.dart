import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart';
import 'main.dart';
import 'data/models.dart';
import 'data/student_suggestions.dart';

class ProfileDraft {
  String? name;
  String? roll;
  String? section;
  String? group;
  int? semester;
  String? branch;
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final ProfileDraft _draft = ProfileDraft();

  int _index = 0;
  bool _obscureApiKey = true;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() => _index = page);
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Prefill from DB (non-blocking, only once).
    // Tests may pump MyApp() without the DBProvider, so use a nullable lookup
    // and fall back to defaults when the DB is not available.
    final db = context
        .dependOnInheritedWidgetOfExactType<DBProvider>()
        ?.database;
    if (_nameController.text.isEmpty) {
      final name = db?.currentProfile.displayName ?? 'You';
      _nameController.text = name;
    }
    final isLast = _index == 3;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  const _WelcomePage(),
                  _NamePage(nameController: _nameController, draft: _draft),
                  _ConfirmPage(draft: _draft),
                  _ApiKeyPage(
                    apiKeyController: _apiKeyController,
                    obscure: _obscureApiKey,
                    onToggleObscure: () =>
                        setState(() => _obscureApiKey = !_obscureApiKey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Visibility(
                        visible: _index != 0,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: TextButton(
                          onPressed: _index == 0
                              ? null
                              : () => _goTo(_index - 1),
                          child: const Text('Back'),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (!isLast) {
                            _goTo(_index + 1);
                          } else {
                            // Persist to DB then navigate to HomePage. If no DB is
                            // available (e.g. unit tests that don't provide it),
                            // skip persistence.
                            final name = _nameController.text.trim();
                            if (name.isNotEmpty && db != null) {
                              await db.setDisplayName(name);
                            }
                            // Persist profile details (roll, section, group, semester)
                            if (db != null) {
                              await db.setProfileDetails(
                                rollNo: _draft.roll,
                                section: _draft.section,
                                group: _draft.group,
                                semester:
                                    _draft.semester ??
                                    (_draft.roll != null
                                        ? _computeSemesterFromRoll(_draft.roll!)
                                        : null),
                                branch:
                                    _draft.branch ??
                                    (_draft.roll != null
                                        ? _deriveBranchFromRoll(_draft.roll!)
                                        : null),
                              );
                            }
                            if (!context.mounted) return;
                            final key = _apiKeyController.text.trim();
                            if (key.isNotEmpty && db != null) {
                              final id = DateTime.now().millisecondsSinceEpoch
                                  .toString();
                              await db.upsertApiKey(
                                ApiKeyModel(id: id, name: 'Gemini', value: key),
                              );
                              if (db.currentActiveApiKeyId == null) {
                                await db.setActiveApiKeyId(id);
                              }
                            }
                            // Demo seeding removed per new requirements (no pre-existing routines)
                            if (!context.mounted) return;
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => const HomePage(),
                              ),
                            );
                          }
                        },
                        child: Text(isLast ? 'Finish' : 'Next'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProgressDots(current: _index, total: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final selected = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: selected ? 22 : 6,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white24,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.white12),
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1D9BF0), Color(0xFF8ECDF8)],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 42,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Agentic Notes',
              textAlign: TextAlign.center,
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate and manage your notes with Gen-AI.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(color: Color(0xFF71767B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamePage extends StatefulWidget {
  const _NamePage({required this.nameController, required this.draft});

  final TextEditingController nameController;
  final ProfileDraft draft;

  @override
  State<_NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<_NamePage> {
  String _query = '';
  StudentSuggestion? _matched;
  String? _selectedSection;

  @override
  void initState() {
    super.initState();
    _query = widget.nameController.text;
    widget.nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final q = widget.nameController.text.trim();
    final m = _findExactMatch(q);
    setState(() {
      _query = q;
      _matched = m;
      if (m != null) {
        _selectedSection = m.section ?? _selectedSection;
        // no UI filter now; keep latest section for draft only
        // populate draft with latest
        widget.draft.name = m.name;
        widget.draft.roll = m.rollNo;
        widget.draft.section = m.section;
        widget.draft.group = m.group;
        widget.draft.semester = _computeSemesterFromRoll(m.rollNo);
        widget.draft.branch = _deriveBranchFromRoll(m.rollNo);
      }
    });
  }

  StudentSuggestion? _findExactMatch(String q) {
    if (q.isEmpty) return null;
    final lq = q.toLowerCase();
    // Prefer DB if available
    final db = context
        .dependOnInheritedWidgetOfExactType<DBProvider>()
        ?.database;
    if (db != null) {
      final sm = db.findStudentByExact(q);
      if (sm != null) {
        return StudentSuggestion(
          name: sm.name,
          rollNo: sm.rollNo,
          group: sm.group,
          section: sm.section,
          semester: sm.semester?.toString(),
        );
      }
    }
    // Fallback to in-memory
    for (final s in kStudentSuggestions) {
      if (s.name.toLowerCase() == lq) return s;
      if (s.rollNo.toLowerCase() == lq) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Enter your name or roll number',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.nameController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Your name or roll no.',
              hintText: 'e.g. Alex or 24BTAML01',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFF2F3336)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: const BorderSide(color: Color(0xFF1D9BF0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SuggestionChips(
            query: _query,
            matched: _matched,
            onPick: (student, fillText) {
              setState(() => _matched = student);
              widget.nameController.text = fillText;
              widget.nameController.selection = TextSelection.fromPosition(
                TextPosition(offset: widget.nameController.text.length),
              );
              setState(() {
                _selectedSection = student.section ?? _selectedSection;
                widget.draft.name = student.name;
                widget.draft.roll = student.rollNo;
                widget.draft.section = student.section;
                widget.draft.group = student.group;
                widget.draft.semester = _computeSemesterFromRoll(
                  student.rollNo,
                );
                widget.draft.branch = _deriveBranchFromRoll(student.rollNo);
              });
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Derive current semester (1..8) from the roll's first two digits (year of admission)
int _computeSemesterFromRoll(String roll) {
  final m = RegExp(r'^(\d{2})').firstMatch(roll);
  if (m == null) return 1;
  final yy = int.tryParse(m.group(1)!) ?? 0;
  final startYear = 2000 + yy;
  final now = DateTime.now();
  int years = now.year - startYear;
  if (years < 0) years = 0;
  int sem = years * 2 + (now.month >= 7 ? 1 : 2);
  if (sem < 1) sem = 1;
  if (sem > 8) sem = 8;
  return sem;
}

// Derive branch from roll number
String? _deriveBranchFromRoll(String roll) {
  final r = roll.toUpperCase();
  if (r.contains('BTCSE')) return 'CSE';
  if (r.contains('BTECE')) return 'ECE';
  if (r.contains('BTEEE')) return 'EEE';
  if (r.contains('BTICS')) return 'ICS';
  if (r.contains('BTAML')) return 'AIML';
  return null;
}

class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips({
    required this.query,
    required this.matched,
    required this.onPick,
  });

  final String query;
  final StudentSuggestion? matched;
  final void Function(StudentSuggestion student, String fillText) onPick;

  @override
  Widget build(BuildContext context) {
    final q = query.trim();

    if (matched != null) {
      final s = matched!;
      final sem = _computeSemesterFromRoll(s.rollNo);
      final branch = _deriveBranchFromRoll(s.rollNo);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Matched',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF71767B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StudentChip(
                label: 'Name: ${s.name}',
                onTap: () => onPick(s, s.name),
              ),
              _StudentChip(
                label: 'Roll: ${s.rollNo}',
                onTap: () => onPick(s, s.rollNo),
              ),
              if (s.section != null) _InfoChip(label: 'Section: ${s.section}'),
              _InfoChip(label: 'Group: ${s.group}'),
              _InfoChip(label: 'Semester: Sem-$sem'),
              if (branch != null) _InfoChip(label: 'Branch: $branch'),
            ],
          ),
        ],
      );
    }

    if (q.isEmpty) return const SizedBox.shrink();

    final lq = q.toLowerCase();
    final db = context
        .dependOnInheritedWidgetOfExactType<DBProvider>()
        ?.database;
    List<StudentSuggestion> nameMatches;
    List<StudentSuggestion> rollMatches;
    if (db != null) {
      final nameDb = db.queryStudentsByNamePrefix(lq, limit: 3);
      final rollDb = db.queryStudentsByRollPrefix(lq, limit: 3);
      nameMatches = nameDb
          .map(
            (sm) => StudentSuggestion(
              name: sm.name,
              rollNo: sm.rollNo,
              group: sm.group,
              section: sm.section,
              semester: sm.semester?.toString(),
            ),
          )
          .toList();
      rollMatches = rollDb
          .map(
            (sm) => StudentSuggestion(
              name: sm.name,
              rollNo: sm.rollNo,
              group: sm.group,
              section: sm.section,
              semester: sm.semester?.toString(),
            ),
          )
          .toList();
    } else {
      nameMatches = kStudentSuggestions
          .where((s) => s.name.toLowerCase().startsWith(lq))
          .take(3)
          .toList();
      rollMatches = kStudentSuggestions
          .where((s) => s.rollNo.toLowerCase().startsWith(lq))
          .take(3)
          .toList();
    }

    if (nameMatches.isEmpty && rollMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nameMatches.isNotEmpty) ...[
          Text(
            'Name matches',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF71767B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in nameMatches)
                _StudentChip(label: s.name, onTap: () => onPick(s, s.name)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (rollMatches.isNotEmpty) ...[
          Text(
            'Roll matches',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF71767B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in rollMatches)
                _StudentChip(
                  label: '${s.rollNo} • ${s.name}',
                  onTap: () => onPick(s, s.rollNo),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1113),
        border: Border.all(color: const Color(0xFF2F3336)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

// Filters removed per latest requirement.

class _ConfirmPage extends StatelessWidget {
  const _ConfirmPage({required this.draft});
  final ProfileDraft draft;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    // Compute semester from roll if missing
    int? sem = draft.semester;
    if (sem == null && (draft.roll?.isNotEmpty ?? false)) {
      sem = _computeSemesterFromRoll(draft.roll!);
    }
    final sections = {
      for (final s in kStudentSuggestions)
        if (s.section != null) s.section!,
    }.toList()..sort();
    final groups = {for (final s in kStudentSuggestions) s.group}.toList()
      ..sort();
    const branches = ['CSE', 'ECE', 'EEE', 'ICS', 'AIML'];
    // default draft.branch from roll if missing
    draft.branch ??= (draft.roll != null)
        ? _deriveBranchFromRoll(draft.roll!)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Confirm your details',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can change section, group, or semester if needed.',
            style: textTheme.titleSmall?.copyWith(
              color: const Color(0xFF71767B),
            ),
          ),
          const SizedBox(height: 16),
          _InfoChip(label: 'Name: ${draft.name ?? '—'}'),
          const SizedBox(height: 8),
          _InfoChip(label: 'Roll: ${draft.roll ?? '—'}'),
          const SizedBox(height: 16),
          Text('Branch', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final b in branches)
                ChoiceChip(
                  label: Text(b),
                  selected: draft.branch == b,
                  onSelected: (_) => draft.branch = b,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Section', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sec in sections)
                ChoiceChip(
                  label: Text(sec),
                  selected: draft.section == sec,
                  onSelected: (_) => draft.section = sec,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Group', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in groups)
                ChoiceChip(
                  label: Text(g),
                  selected: draft.group == g,
                  onSelected: (_) => draft.group = g,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Current semester', style: textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 1; i <= 8; i++)
                ChoiceChip(
                  label: Text('Sem-$i'),
                  selected: (draft.semester ?? sem) == i,
                  onSelected: (_) => draft.semester = i,
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StudentChip extends StatelessWidget {
  const _StudentChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF16181C),
          border: Border.all(color: const Color(0xFF2F3336)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _ApiKeyPage extends StatelessWidget {
  const _ApiKeyPage({
    required this.apiKeyController,
    required this.obscure,
    required this.onToggleObscure,
  });

  final TextEditingController apiKeyController;
  final bool obscure;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const double fieldHeight = 56.0;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Connect your API key',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This app requires a Gemini API key to function.',
            style: textTheme.titleSmall?.copyWith(color: Color(0xFF71767B)),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SizedBox(
                  height: fieldHeight,
                  child: TextField(
                    controller: apiKeyController,
                    obscureText: obscure,
                    enableSuggestions: false,
                    autocorrect: false,
                    decoration: InputDecoration(
                      labelText: 'API key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFF2F3336)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(color: Color(0xFF1D9BF0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      suffixIcon: IconButton(
                        tooltip: obscure ? 'Show' : 'Hide',
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: onToggleObscure,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: fieldHeight,
                child: _LightActionChip(
                  label: 'Check',
                  onPressed: () {
                    final key = apiKeyController.text.trim();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          key.isEmpty
                              ? 'Enter an API key first.'
                              : 'Checking key… (UI only)',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            children: [
              const _LightInfoChip(label: 'We never store your key'),
              _LightLinkChip(
                label: 'Get a Gemini API key',
                onPressed: () async {
                  final url = Uri.parse(
                    'https://aistudio.google.com/app/apikey',
                  );
                  final opened = await launchUrl(
                    url,
                    mode: LaunchMode.externalApplication,
                  );
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Couldn't open the link.")),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LightInfoChip extends StatelessWidget {
  const _LightInfoChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Text(label, style: const TextStyle(color: Colors.white60)),
      shape: const StadiumBorder(),
      backgroundColor: Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
      onPressed: null,
    );
  }
}

class _LightLinkChip extends StatelessWidget {
  const _LightLinkChip({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InputChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          const SizedBox(width: 6),
          const Icon(Icons.open_in_new, size: 16, color: Color(0xFF71767B)),
        ],
      ),
      shape: const StadiumBorder(),
      backgroundColor: Color(0xFF0A0A0A),
      side: const BorderSide(color: Color(0xFF2F3336)),
      onPressed: onPressed,
    );
  }
}

class _LightActionChip extends StatelessWidget {
  const _LightActionChip({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: const Color(0xFF71767B),
        shape: const StadiumBorder(),
        side: const BorderSide(color: Color(0xFF2F3336)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w500),
        elevation: 0,
      ),
      child: Text(label),
    );
  }
}
