import 'package:flutter/material.dart';
import 'widgets/universal_chat_toolbar.dart';
import 'main.dart';
// DB access via DBProvider in main.dart
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.title});
  final String? title;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<_ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  bool _sending = false;
  String _model = 'gemini-2.5-flash-lite';
  _PendingTimer? _pending;
  bool _createImageActive = false;

  @override
  void dispose() {
    _inputFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'AI Chat'),
        centerTitle: true,
        actions: const [SizedBox(width: 4)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // top toolbar removed per user request
            Expanded(
              child: _messages.isEmpty
                  ? const _ChatEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      reverse: true,
                      itemCount: _messages.length + (_pending != null ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        // With reverse: true, index 0 is newest at bottom.
                        if (_pending != null && i == 0) {
                          final t = _pending!;
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: _TimerBubble(elapsed: t.elapsed),
                          );
                        }
                        final idx =
                            _messages.length -
                            1 -
                            (i - (_pending != null ? 1 : 0));
                        final m = _messages[idx];
                        return Align(
                          alignment: m.isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * .75,
                            ),
                            child: _MessageBubble(message: m),
                          ),
                        );
                      },
                    ),
            ),
            // divider removed for a cleaner minimal look
            UniversalChatToolbar(
              textFieldFocus: _inputFocus,
              controller: _ctrl,
              sending: _sending,
              currentModel: _model,
              onPickModel: _pickModel,
              createImageActive: _createImageActive,
              onAction: (a) {
                if (a == ChatAction.text) return; // focus managed
                if (a == ChatAction.createImage) {
                  setState(() => _createImageActive = !_createImageActive);
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Action: ${a.name}')));
              },
              onSend: (t) {
                if (_createImageActive) {
                  _generateImageFromText();
                } else {
                  _send();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _sending = true;
      _ctrl.clear();
      _pending = _PendingTimer()..start();
    });

    // Intercept demo image commands (frontend only)
    final demoCount = _parseDemoImageCount(text);
    if (demoCount != null) {
      await _showDemoImages(demoCount);
      return;
    }

    try {
      final chat = ChatProvider.of(context);
      final reply = await chat.sendText(
        text,
        history: _asHistory(),
        model: _model,
      );
      if (!mounted) return;
      setState(() {
        final elapsed = _pending?.elapsed.value ?? Duration.zero;
        final timeStr = _formatElapsed(elapsed);
        _messages.add(
          _ChatMessage(text: '$reply\n\n— took $timeStr', isUser: false),
        );
      });
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Chat failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          final p = _pending;
          p?.stop();
          p?.dispose();
          _pending = null;
        });
      }
    }
  }

  int? _parseDemoImageCount(String t) {
    final m = RegExp(r'^#demoimg([1-5])$').firstMatch(t);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  List<String> _demoImageUrls(int count) {
    final seedBase = DateTime.now().millisecondsSinceEpoch;
    return [
      for (int i = 0; i < count; i++)
        'https://picsum.photos/seed/demo_${seedBase}_$i/600/600',
    ];
  }

  Future<void> _showDemoImages(int count) async {
    final urls = _demoImageUrls(count);
    for (int i = 0; i < urls.length; i++) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(text: '', isUser: false, imageUrls: [urls[i]]),
        );
      });
      // Small delay so images appear one-by-one
      await Future.delayed(const Duration(milliseconds: 450));
    }
    if (!mounted) return;
    setState(() {
      _sending = false;
      final p = _pending;
      p?.stop();
      p?.dispose();
      _pending = null;
    });
  }

  List<Map<String, String>> _asHistory() {
    // Convert to a compact history list while keeping order
    return [
      for (final m in _messages)
        {'role': m.isUser ? 'user' : 'model', 'text': m.text},
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load preferred model from DB
    final db = DBProvider.of(context);
    _model = db.currentPreferredModel;
  }

  String _formatElapsed(Duration d) {
    final secs = d.inSeconds.toString().padLeft(2, '0');
    final centis = ((d.inMilliseconds % 1000) / 10).floor().toString().padLeft(
      2,
      '0',
    );
    return '($secs:$centis s:ms)';
  }

  Future<void> _pickModel() async {
    final db = DBProvider.of(context);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ModelPicker(current: _model),
    );
    if (selected != null && mounted) {
      setState(() => _model = selected);
      await db.setPreferredModel(selected);
    }
  }

  Future<void> _generateImageFromText() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(text: prompt, isUser: true));
      _sending = true;
      _ctrl.clear();
      _pending = _PendingTimer()..start();
    });

    try {
      final url = _demoImageUrls(1).first;
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(text: '', isUser: false, imageUrls: [url]));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image generation failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          final p = _pending;
          p?.stop();
          p?.dispose();
          _pending = null;
          _createImageActive = false; // exit toggle after generation
        });
      }
    }
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? imageUrls;
  _ChatMessage({required this.text, required this.isUser, this.imageUrls});
  bool get hasImages => (imageUrls != null && imageUrls!.isNotEmpty);
}

class _ChatEmpty extends StatelessWidget {
  const _ChatEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.auto_awesome, size: 44, color: Color(0xFF71767B)),
          SizedBox(height: 12),
          Text(
            'Start a conversation',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 6),
          Text(
            'Uses Gemini 2.5 Flash-Lite. Add an API key in Profile.',
            style: TextStyle(color: Color(0xFF71767B)),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bgColor = isUser ? const Color(0xFF0A84FF) : const Color(0xFF1C1C1E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.text.isNotEmpty)
            Text(message.text, style: const TextStyle(color: Colors.white)),
          if (message.text.isNotEmpty && message.hasImages)
            const SizedBox(height: 8),
          if (message.hasImages) _ImagesGrid(urls: message.imageUrls!),
        ],
      ),
    );
  }
}

class _ImagesGrid extends StatelessWidget {
  final List<String> urls;
  const _ImagesGrid({required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.length == 1) {
      return _roundedImage(urls.first);
    }
    // Grid for multiple images
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: urls.length,
      itemBuilder: (context, index) => _roundedImage(urls[index]),
    );
  }

  Widget _roundedImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 1,
        child: Image.network(url, fit: BoxFit.cover),
      ),
    );
  }
}

class _TimerBubble extends StatelessWidget {
  final ValueNotifier<Duration> elapsed;
  const _TimerBubble({required this.elapsed});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: elapsed,
      builder: (context, d, _) {
        final secs = d.inSeconds.toString().padLeft(2, '0');
        final centis = ((d.inMilliseconds % 1000) / 10)
            .floor()
            .toString()
            .padLeft(2, '0');
        final time = '($secs:$centis s:ms)';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        );
      },
    );
  }
}

class _PendingTimer {
  final Stopwatch _sw = Stopwatch();
  final ValueNotifier<Duration> elapsed = ValueNotifier(Duration.zero);
  Timer? _timer;

  void start() {
    _sw.start();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      elapsed.value = _sw.elapsed;
    });
  }

  void stop() {
    _timer?.cancel();
    _sw.stop();
    elapsed.value = _sw.elapsed;
  }

  void dispose() {
    _timer?.cancel();
  }
}

class _ModelPicker extends StatelessWidget {
  final String current;
  const _ModelPicker({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = const [
      'gemini-2.5-flash-lite',
      'gemini-2.5-flash',
      'gemini-2.5-pro',
    ];
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
            const ListTile(
              leading: Icon(Icons.memory_outlined),
              title: Text('Choose model'),
              subtitle: Text('Applies to this and future chats'),
            ),
            const Divider(height: 1),
            for (final m in options)
              RadioListTile<String>(
                value: m,
                groupValue: current,
                title: Text(m),
                onChanged: (v) => Navigator.of(context).pop(v),
              ),
          ],
        ),
      ),
    );
  }
}
