import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Represents the lifecycle of a voice call with the Dostok AI.
enum CallState {
  /// No active call; the UI shows a call button.
  idle,

  /// The call is being established (ringing / connecting animation).
  connecting,

  /// The call is live and both sides can hear each other.
  active,

  /// The call has ended; the UI may show a summary or callback option.
  ended,
}

/// Manages voice-call state for the Dostok AI friend.
///
/// Tracks call lifecycle ([CallState]), duration, mute/speaker toggles, and
/// persists call history statistics to Hive. Widgets consume this provider
/// to render the call screen, duration timer, and control buttons.
class CallProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _totalCallsKey = 'totalCalls';
  static const String _totalCallSecondsKey = 'totalCallSeconds';

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  CallState _currentState = CallState.idle;
  Duration _callDuration = Duration.zero;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  String? _error;

  Timer? _durationTimer;
  Timer? _connectingTimeout;
  DateTime? _callStartTime;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The current lifecycle state of the call.
  CallState get currentState => _currentState;

  /// Elapsed duration of the active call.
  Duration get callDuration => _callDuration;

  /// Whether the microphone is muted.
  bool get isMuted => _isMuted;

  /// Whether speaker mode is on.
  bool get isSpeakerOn => _isSpeakerOn;

  /// A human-readable formatted duration string (mm:ss or hh:mm:ss).
  String get formattedDuration {
    final h = _callDuration.inHours;
    final m = _callDuration.inMinutes.remainder(60);
    final s = _callDuration.inSeconds.remainder(60);
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// The last error message, if any.
  String? get error => _error;

  /// Whether a call is currently connecting or active.
  bool get isInCall =>
      _currentState == CallState.connecting ||
      _currentState == CallState.active;

  // ---------------------------------------------------------------------------
  // Call lifecycle
  // ---------------------------------------------------------------------------

  /// Initiates a new voice call with the AI.
  ///
  /// Transitions: idle/ended -> connecting -> active.
  /// If connecting takes more than 10 seconds without transitioning to active,
  /// the call is automatically ended with a timeout error.
  Future<void> startCall() async {
    if (isInCall) return;

    _error = null;
    _currentState = CallState.connecting;
    _callDuration = Duration.zero;
    _isMuted = false;
    _isSpeakerOn = false;
    notifyListeners();

    try {
      // Simulate connection delay (replace with real WebRTC / SIP setup).
      _connectingTimeout = Timer(const Duration(seconds: 10), () {
        if (_currentState == CallState.connecting) {
          _error = 'Connection timed out. Please try again.';
          endCall();
        }
      });

      await Future.delayed(const Duration(seconds: 2));

      // If the timeout already fired, bail out.
      if (_currentState != CallState.connecting) return;

      _connectingTimeout?.cancel();
      _connectingTimeout = null;

      _currentState = CallState.active;
      _callStartTime = DateTime.now();
      _startDurationTimer();
      notifyListeners();
    } catch (e, st) {
      dev.log('CallProvider.startCall failed', error: e, stackTrace: st);
      _error = 'Failed to connect. Please try again.';
      _currentState = CallState.ended;
      notifyListeners();
    }
  }

  /// Ends the current call and persists call statistics.
  ///
  /// Transitions: connecting/active -> ended.
  Future<void> endCall() async {
    if (!isInCall) return;

    _connectingTimeout?.cancel();
    _connectingTimeout = null;
    _stopDurationTimer();

    _currentState = CallState.ended;
    notifyListeners();

    // Persist call statistics.
    await _saveCallStats();

    dev.log('Call ended. Duration: ${formattedDuration}');
  }

  /// Resets the provider back to idle so a new call can be placed.
  void resetCall() {
    _currentState = CallState.idle;
    _callDuration = Duration.zero;
    _isMuted = false;
    _isSpeakerOn = false;
    _error = null;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // In-call controls
  // ---------------------------------------------------------------------------

  /// Toggles microphone mute on/off during an active call.
  void toggleMute() {
    if (_currentState != CallState.active) return;
    _isMuted = !_isMuted;
    notifyListeners();
    dev.log('Microphone ${_isMuted ? "muted" : "unmuted"}');
  }

  /// Toggles speaker mode on/off during an active call.
  void toggleSpeaker() {
    if (_currentState != CallState.active) return;
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
    dev.log('Speaker ${_isSpeakerOn ? "on" : "off"}');
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  /// Returns the total number of calls the user has made (persisted).
  Future<int> get totalCalls async {
    final box = await Hive.openBox(_boxName);
    return (box.get(_totalCallsKey) as int?) ?? 0;
  }

  /// Returns the total call duration in seconds (persisted).
  Future<int> get totalCallSeconds async {
    final box = await Hive.openBox(_boxName);
    return (box.get(_totalCallSecondsKey) as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_callStartTime != null) {
        _callDuration = DateTime.now().difference(_callStartTime!);
        notifyListeners();
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _saveCallStats() async {
    try {
      final box = await Hive.openBox(_boxName);
      final currentCalls = (box.get(_totalCallsKey) as int?) ?? 0;
      final currentSeconds = (box.get(_totalCallSecondsKey) as int?) ?? 0;
      await box.put(_totalCallsKey, currentCalls + 1);
      await box.put(
        _totalCallSecondsKey,
        currentSeconds + _callDuration.inSeconds,
      );
    } catch (e, st) {
      dev.log('CallProvider._saveCallStats failed', error: e, stackTrace: st);
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _connectingTimeout?.cancel();
    super.dispose();
  }
}
