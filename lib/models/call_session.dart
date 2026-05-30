import 'package:hive/hive.dart';

part 'call_session.g.dart';

/// Represents a voice call session between the user and the AI.
///
/// Tracks timing, direction (incoming/outgoing), and a transcript of the
/// conversation. The transcript is stored as a list of strings, where each
/// entry is a line of dialogue (prefixed with speaker labels).
/// Persisted via Hive.
@HiveType(typeId: 4)
class CallSession {
  /// Unique identifier for this call session (UUID string).
  @HiveField(0)
  final String id;

  /// The date and time when the call started.
  @HiveField(1)
  final DateTime startTime;

  /// The date and time when the call ended. Null if the call is still active.
  @HiveField(2)
  final DateTime? endTime;

  /// The total duration of the call in seconds.
  @HiveField(3)
  final int durationSeconds;

  /// Whether the call was initiated by the user (false) or by the AI (true).
  @HiveField(4)
  final bool wasIncoming;

  /// A transcript of the call, where each entry is a line of dialogue
  /// (e.g., "User: Labas?  |  AI: Labas, labas, kulshi mezyan!").
  @HiveField(5)
  final List<String> transcript;

  const CallSession({
    required this.id,
    required this.startTime,
    this.endTime,
    this.durationSeconds = 0,
    this.wasIncoming = false,
    this.transcript = const [],
  });

  /// Creates a copy of this call session with the given fields replaced
  /// by new values.
  ///
  /// Useful for ending an active call (setting [endTime] and
  /// [durationSeconds]) or appending to the transcript without mutating
  /// the original instance.
  CallSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    int? durationSeconds,
    bool? wasIncoming,
    List<String>? transcript,
  }) {
    return CallSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      wasIncoming: wasIncoming ?? this.wasIncoming,
      transcript: transcript ?? this.transcript,
    );
  }

  /// Whether the call is currently active (has not ended yet).
  bool get isActive => endTime == null;

  /// Returns a formatted duration string (e.g., "02:34" or "1:05:22").
  String get formattedDuration {
    final d = durationSeconds;
    final hours = d ~/ 3600;
    final minutes = (d % 3600) ~/ 60;
    final seconds = d % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(1, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  String toString() =>
      'CallSession(id: $id, active: $isActive, duration: $formattedDuration, transcriptLines: ${transcript.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallSession && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
