import 'package:hive/hive.dart';

part 'conversation.g.dart';

/// The overall emotional mood of a conversation.
///
/// Derived from message content and sentiment analysis, this helps the AI
/// tailor its responses to match or gently shift the conversation tone.
@HiveType(typeId: 6)
enum ConversationMood {
  /// Positive, upbeat conversation.
  @HiveField(0)
  happy,

  /// Somber, melancholic, or the user is feeling down.
  @HiveField(1)
  sad,

  /// No strong emotional direction; everyday or informational chat.
  @HiveField(2)
  neutral,

  /// High-energy, enthusiastic, or excited conversation.
  @HiveField(3)
  excited,
}

/// Represents a single conversation thread between the user and the AI.
///
/// A conversation groups related messages together with metadata such as
/// title, mood, and a summary. Messages are referenced by their IDs rather
/// than embedded directly to keep the conversation object lightweight.
/// Persisted via Hive.
@HiveType(typeId: 3)
class Conversation {
  /// Unique identifier for this conversation (UUID string).
  @HiveField(0)
  final String id;

  /// A human-readable title for the conversation, either auto-generated
  /// or set by the user.
  @HiveField(1)
  final String title;

  /// Ordered list of message IDs belonging to this conversation.
  @HiveField(2)
  final List<String> messageIds;

  /// The date and time when this conversation was started.
  @HiveField(3)
  final DateTime createdAt;

  /// The date and time of the most recent activity in this conversation.
  @HiveField(4)
  final DateTime updatedAt;

  /// The detected or inferred emotional mood of the conversation.
  @HiveField(5)
  final ConversationMood mood;

  /// An optional AI-generated summary of the conversation so far.
  @HiveField(6)
  final String summary;

  const Conversation({
    required this.id,
    required this.title,
    this.messageIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.mood = ConversationMood.neutral,
    this.summary = '',
  });

  /// Creates a copy of this conversation with the given fields replaced
  /// by new values.
  ///
  /// Useful for appending new messages, updating the mood, or refreshing
  /// the summary without mutating the original instance.
  Conversation copyWith({
    String? id,
    String? title,
    List<String>? messageIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    ConversationMood? mood,
    String? summary,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messageIds: messageIds ?? this.messageIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      mood: mood ?? this.mood,
      summary: summary ?? this.summary,
    );
  }

  /// The number of messages in this conversation.
  int get messageCount => messageIds.length;

  @override
  String toString() =>
      'Conversation(id: $id, title: $title, messages: $messageCount, mood: $mood)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
