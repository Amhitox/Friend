import 'dart:async';

/// Represents the possible states of a voice call.
enum CallState {
  /// No call is active.
  idle,

  /// A call is being initiated.
  connecting,

  /// A call is in progress.
  active,

  /// The call is muted.
  muted,

  /// The call has ended.
  ended,
}

/// A single entry in the call transcript.
class TranscriptEntry {
  final String speaker; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;

  TranscriptEntry({
    required this.speaker,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Service that manages voice call sessions with Dostok.
///
/// Tracks call state, duration, mute status, and collects a transcript
/// of the conversation that occurred during the call.
class CallService {
  CallState _state = CallState.idle;
  bool _isMuted = false;
  Duration _duration = Duration.zero;
  Timer? _durationTimer;
  DateTime? _callStartTime;

  final List<TranscriptEntry> _transcript = [];

  final StreamController<CallState> _stateController =
      StreamController<CallState>.broadcast();

  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();

  /// Stream of call state changes.
  ///
  /// Listen to this to react to state transitions (connecting, active, ended).
  Stream<CallState> get stateStream => _stateController.stream;

  /// Stream of call duration updates.
  ///
  /// Emits the current duration every second while a call is active.
  Stream<Duration> get durationStream => _durationController.stream;

  /// The current call state.
  CallState get state => _state;

  /// Whether the call is currently muted.
  bool get isMuted => _isMuted;

  /// The current duration of the call.
  Duration get duration => _duration;

  /// A read-only view of the call transcript.
  List<TranscriptEntry> get transcript => List.unmodifiable(_transcript);

  /// Whether a call is currently active or connecting.
  bool get isActive =>
      _state == CallState.active || _state == CallState.connecting;

  /// Starts a new voice call.
  ///
  /// Initiates the call, transitions through connecting state, and begins
  /// tracking duration. Clears any previous transcript.
  ///
  /// Returns true if the call started successfully.
  Future<bool> startCall() async {
    try {
      if (isActive) {
        return false;
      }

      _transcript.clear();
      _duration = Duration.zero;
      _isMuted = false;

      _updateState(CallState.connecting);

      // Simulate connection delay.
      await Future.delayed(const Duration(seconds: 1));

      _callStartTime = DateTime.now();
      _updateState(CallState.active);
      _startDurationTimer();

      return true;
    } catch (e) {
      _updateState(CallState.idle);
      return false;
    }
  }

  /// Ends the current voice call.
  ///
  /// Stops the duration timer, marks the call as ended, and preserves
  /// the transcript for later retrieval.
  ///
  /// Returns true if the call ended successfully.
  Future<bool> endCall() async {
    try {
      if (_state == CallState.idle) {
        return false;
      }

      _stopDurationTimer();
      _updateState(CallState.ended);
      _callStartTime = null;

      return true;
    } catch (e) {
      _updateState(CallState.idle);
      return false;
    }
  }

  /// Toggles the mute state of the current call.
  ///
  /// Returns the new mute state (true = muted, false = unmuted).
  /// Returns null if no call is active.
  bool? toggleMute() {
    if (!isActive) return null;

    _isMuted = !_isMuted;
    _updateState(_isMuted ? CallState.muted : CallState.active);
    return _isMuted;
  }

  /// Adds an entry to the call transcript.
  ///
  /// [speaker] should be 'user' or 'assistant'.
  /// [text] is the recognized or generated speech content.
  ///
  /// This is typically called by the STT and TTS services during an active
  /// call to build a record of the conversation.
  void addTranscriptEntry({
    required String speaker,
    required String text,
  }) {
    _transcript.add(TranscriptEntry(
      speaker: speaker,
      text: text,
    ));
  }

  /// Returns the formatted call duration as "MM:SS" or "HH:MM:SS".
  String getFormattedDuration() {
    final hours = _duration.inHours;
    final minutes = _duration.inMinutes.remainder(60);
    final seconds = _duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Returns the full transcript as a single formatted string.
  ///
  /// Each line is formatted as "Speaker: text".
  String getTranscriptText() {
    return _transcript
        .map((entry) => '${entry.speaker}: ${entry.text}')
        .join('\n');
  }

  /// Starts a timer that updates the call duration every second.
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_callStartTime != null) {
        _duration = DateTime.now().difference(_callStartTime!);
        if (!_durationController.isClosed) {
          _durationController.add(_duration);
        }
      }
    });
  }

  /// Stops the duration timer.
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// Updates the internal state and notifies listeners.
  void _updateState(CallState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  /// Disposes of all resources, streams, and timers.
  ///
  /// Call this when the service is no longer needed.
  void dispose() {
    _stopDurationTimer();
    _stateController.close();
    _durationController.close();
    _state = CallState.idle;
  }
}
