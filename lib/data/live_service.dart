import 'dart:async';

/// A lightweight stub for a Gemini Live (WebRTC) session.
/// This simulates connect/disconnect and call timer without audio I/O.
class LiveService {
  final _stateCtrl = StreamController<CallState>.broadcast();
  final _elapsedCtrl = StreamController<Duration>.broadcast();
  final _phaseCtrl = StreamController<TalkPhase>.broadcast();

  Stream<CallState> get state => _stateCtrl.stream;
  Stream<Duration> get elapsed => _elapsedCtrl.stream;
  Stream<TalkPhase> get phase => _phaseCtrl.stream;

  Timer? _tick;
  DateTime? _start;
  bool _muted = false;
  bool _speaker = true;

  bool get muted => _muted;
  bool get speakerOn => _speaker;

  Future<void> connect({
    String model = 'gemini-2.5-flash-preview-native-audio-dialog',
  }) async {
    // Simulate signaling + WebRTC setup.
    _stateCtrl.add(CallState.connecting);
    await Future.delayed(const Duration(milliseconds: 900));
    _start = DateTime.now();
    _stateCtrl.add(CallState.live);
    _tick?.cancel();
    _tick = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_start != null) {
        _elapsedCtrl.add(DateTime.now().difference(_start!));
      }
    });
    // Start cyclic phases: listening -> thinking -> speaking -> listening...
    _runPhases();
  }

  void toggleMute() {
    _muted = !_muted;
  }

  void toggleSpeaker() {
    _speaker = !_speaker;
  }

  Future<void> disconnect() async {
    _tick?.cancel();
    _tick = null;
    _phaseTimer?.cancel();
    _stateCtrl.add(CallState.ended);
  }

  void dispose() {
    _tick?.cancel();
    _phaseTimer?.cancel();
    _stateCtrl.close();
    _elapsedCtrl.close();
    _phaseCtrl.close();
  }

  // Phase simulation
  Timer? _phaseTimer;
  void _runPhases() {
    _phaseTimer?.cancel();
    TalkPhase current = TalkPhase.listening;
    _phaseCtrl.add(current);
    Duration durFor(TalkPhase p) {
      switch (p) {
        case TalkPhase.listening:
          return const Duration(seconds: 3);
        case TalkPhase.thinking:
          return const Duration(milliseconds: 1500);
        case TalkPhase.speaking:
          return const Duration(seconds: 3);
      }
    }

    void next() {
      if (_start == null) return; // not live
      if (current == TalkPhase.listening) {
        current = TalkPhase.thinking;
      } else if (current == TalkPhase.thinking) {
        current = TalkPhase.speaking;
      } else {
        current = TalkPhase.listening;
      }
      _phaseCtrl.add(current);
      _phaseTimer = Timer(durFor(current), next);
    }

    _phaseTimer = Timer(durFor(current), next);
  }
}

enum CallState { idle, connecting, live, ended }

enum TalkPhase { listening, thinking, speaking }
