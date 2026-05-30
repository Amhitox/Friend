import 'package:hive/hive.dart';

part 'message.g.dart';

/// Represents the type of message content.
///
/// Used to distinguish between different message formats
/// such as plain text, voice recordings, images, or system notifications.
@HiveType(typeId: 1)
enum MessageType {
  /// Standard text message.
  @HiveField(0)
  text,

  /// Voice/audio message with an associated audio file.
  @HiveField(1)
  audio,

  /// Image message (photo, sticker, etc.).
  @HiveField(2)
  image,

  /// System-generated message (e.g., "User joined", conversation prompts).
  @HiveField(3)
  system,
}

/// Represents a single message in a conversation between the user and the AI.
///
/// Messages are persisted via Hive for fast local storage. Each message
/// tracks its content, origin (user or AI), timestamp, and optional media
/// attachments like audio recordings.
@HiveType(typeId: 0)
class Message {
  /// Unique identifier for this message (UUID string).
  @HiveField(0)
  final String id;

  /// The text content of the message. For audio/image messages this may
  /// contain a transcription or caption.
  @HiveField(1)
  final String content;

  /// Whether this message was sent by the user (true) or by the AI (false).
  @HiveField(2)
  final bool isFromUser;

  /// The date and time when this message was created.
  @HiveField(3)
  final DateTime timestamp;

  /// The type of message (text, audio, image, or system).
  @HiveField(4)
  final MessageType type;

  /// Optional file path to an audio recording, used when [type] is
  /// [MessageType.audio].
  @HiveField(5)
  final String? audioPath;

  /// Whether this message has been read by the recipient.
  @HiveField(6)
  final bool isRead;

  const Message({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.audioPath,
    this.isRead = false,
  });

  /// Creates a copy of this message with the given fields replaced by new values.
  ///
  /// Useful for marking a message as read or updating content without
  /// mutating the original instance.
  Message copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    MessageType? type,
    String? audioPath,
    bool? isRead,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      audioPath: audioPath ?? this.audioPath,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() =>
      'Message(id: $id, isFromUser: $isFromUser, type: $type, content: ${content.length > 30 ? '${content.substring(0, 30)}...' : content})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
