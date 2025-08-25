import 'package:flutter/material.dart';

/// Front-end only bottom sheet for adding a new API key.
/// Returns an [ApiKeyData] via Navigator.pop when the user taps Add.
class AddApiKeySheet extends StatefulWidget {
  const AddApiKeySheet({super.key});

  @override
  State<AddApiKeySheet> createState() => _AddApiKeySheetState();
}

class _AddApiKeySheetState extends State<AddApiKeySheet> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _keyCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
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
              'Add API key',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. OpenAI (personal)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _keyCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'API key',
                hintText: 'sk-••••••••••••',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                suffixIcon: IconButton(
                  tooltip: _obscure ? 'Show' : 'Hide',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final name = _nameCtrl.text.trim();
                    final value = _keyCtrl.text.trim();
                    if (name.isEmpty || value.isEmpty) return;
                    Navigator.of(
                      context,
                    ).pop(ApiKeyData(name: name, value: value));
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ApiKeyData {
  final String name;
  final String value;
  ApiKeyData({required this.name, required this.value});
}
