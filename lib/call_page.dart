import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data/live_service.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late final LiveService _live;
  CallState _state = CallState.idle;
  Duration _elapsed = Duration.zero;
  StreamSubscription? _s1;
  StreamSubscription? _s2;
  StreamSubscription? _s3;
  TalkPhase _phase = TalkPhase.listening;

  @override
  void initState() {
    super.initState();
    _live = LiveService();
  }

  @override
  void dispose() {
    _s1?.cancel();
    _s2?.cancel();
    _s3?.cancel();
    _live.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _s1?.cancel();
    _s2?.cancel();
    _s3?.cancel();
    _s1 = _live.state.listen((s) => setState(() => _state = s));
    _s2 = _live.elapsed.listen((d) => setState(() => _elapsed = d));
    _s3 = _live.phase.listen((p) => setState(() => _phase = p));
    // Request mic permission, then connect
    _ensureMicAndConnect();
  }

  Future<void> _ensureMicAndConnect() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;
    if (status.isGranted) {
      unawaited(_live.connect());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Microphone permission is required for calls.'),
        ),
      );
    }
  }

  String _elapsedLabel() {
    final mm = (_elapsed.inMinutes).toString().padLeft(2, '0');
    final ss = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Live call'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1D9BF0).withValues(alpha: 0.12),
              child: const Icon(Icons.smart_toy_outlined, size: 44),
            ),
            const SizedBox(height: 12),
            Text(
              _state == CallState.live
                  ? 'Talking to Gemini'
                  : _state == CallState.connecting
                  ? 'Connecting…'
                  : _state == CallState.ended
                  ? 'Call ended'
                  : 'Ready',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            if (_state != CallState.ended)
              Text(
                'Duration ${_elapsedLabel()}',
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (_state == CallState.live) _phaseBadge(),
            const Spacer(),
            _controls(theme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _phaseBadge() {
    late final String text;
    late final IconData icon;
    late final Color color;
    switch (_phase) {
      case TalkPhase.listening:
        text = 'Speak now';
        icon = Icons.record_voice_over_outlined;
        color = Colors.greenAccent.withValues(alpha: 0.2);
        break;
      case TalkPhase.thinking:
        text = 'Thinking…';
        icon = Icons.hourglass_top_outlined;
        color = Colors.amber.withValues(alpha: 0.2);
        break;
      case TalkPhase.speaking:
        text = 'Responding…';
        icon = Icons.graphic_eq_outlined;
        color = Colors.blueAccent.withValues(alpha: 0.2);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
      ),
    );
  }

  Widget _controls(ThemeData theme) {
    final isLive = _state == CallState.live || _state == CallState.connecting;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _roundButton(
            icon: _live.muted ? Icons.mic_off : Icons.mic,
            label: _live.muted ? 'Unmute' : 'Mute',
            onTap: isLive ? () => setState(() => _live.toggleMute()) : null,
          ),
          _roundButton(
            icon: _live.speakerOn ? Icons.volume_up : Icons.volume_mute,
            label: _live.speakerOn ? 'Speaker' : 'Earpiece',
            onTap: isLive ? () => setState(() => _live.toggleSpeaker()) : null,
          ),
          _roundButton(
            icon: Icons.call_end,
            label: 'End',
            color: Colors.redAccent,
            onTap: isLive
                ? () async {
                    await _live.disconnect();
                    if (mounted) Navigator.of(context).maybePop();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String label,
    Color? color,
    VoidCallback? onTap,
  }) {
    final base = color ?? const Color(0xFF1D9BF0);
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (onTap != null ? base : Colors.grey.shade800),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }
}
