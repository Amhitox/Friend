import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// The user's preferred language for conversation.
///
/// Determines how the AI adapts its responses, mixing Darija, Modern Standard
/// Arabic, French, or a combination as preferred by the user.
@HiveType(typeId: 5)
enum PreferredLanguage {
  /// Moroccan Darija (primary conversational dialect).
  @HiveField(0)
  darija,

  /// Modern Standard Arabic (formal / written Arabic).
  @HiveField(1)
  arabic,

  /// French (commonly used in Morocco alongside Darija).
  @HiveField(2)
  french,

  /// A natural mix of Darija, Arabic, and French as spoken in everyday
  /// Moroccan conversation.
  @HiveField(3)
  mixed,
}

/// Stores the user's profile and personalization preferences.
///
/// The profile tracks both static preferences (language, avatar) and dynamic
/// relationship metrics (humor, empathy, formality levels) that evolve as the
/// AI learns the user's communication style over time. Persisted via Hive.
@HiveType(typeId: 2)
class UserProfile {
  /// The user's display name.
  @HiveField(0)
  final String name;

  /// The language the user prefers for conversations.
  @HiveField(1)
  final PreferredLanguage preferredLanguage;

  /// How much humor the user appreciates in AI responses, on a 0-10 scale.
  /// 0 = serious only, 10 = very humorous.
  @HiveField(2)
  final int humorLevel;

  /// How empathetic the AI should be, on a 0-10 scale.
  /// 0 = neutral/factual, 10 = highly empathetic and emotionally supportive.
  @HiveField(3)
  final int empathyLevel;

  /// How formal the conversation style should be, on a 0-10 scale.
  /// 0 = very casual/slang, 10 = highly formal and respectful.
  @HiveField(4)
  final int formalityLevel;

  /// The closeness of the user-AI relationship, on a 0-100 scale.
  /// Increases over time with more interactions.
  @HiveField(5)
  final int relationshipLevel;

  /// Total number of messages exchanged between the user and the AI.
  @HiveField(6)
  final int totalMessages;

  /// The number of distinct days the user has interacted with the AI.
  @HiveField(7)
  final int daysActive;

  /// The date of the user's first interaction with the AI.
  @HiveField(8)
  final DateTime firstInteractionDate;

  /// Optional file path to the user's chosen avatar image.
  @HiveField(9)
  final String? avatarPath;

  const UserProfile({
    required this.name,
    this.preferredLanguage = PreferredLanguage.mixed,
    this.humorLevel = 5,
    this.empathyLevel = 5,
    this.formalityLevel = 3,
    this.relationshipLevel = 0,
    this.totalMessages = 0,
    this.daysActive = 0,
    required this.firstInteractionDate,
    this.avatarPath,
  });

  /// Creates a copy of this profile with the given fields replaced by new values.
  ///
  /// Useful for incrementally updating relationship metrics or changing
  /// preferences without mutating the original instance.
  UserProfile copyWith({
    String? name,
    PreferredLanguage? preferredLanguage,
    int? humorLevel,
    int? empathyLevel,
    int? formalityLevel,
    int? relationshipLevel,
    int? totalMessages,
    int? daysActive,
    DateTime? firstInteractionDate,
    String? avatarPath,
  }) {
    return UserProfile(
      name: name ?? this.name,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      humorLevel: humorLevel ?? this.humorLevel,
      empathyLevel: empathyLevel ?? this.empathyLevel,
      formalityLevel: formalityLevel ?? this.formalityLevel,
      relationshipLevel: relationshipLevel ?? this.relationshipLevel,
      totalMessages: totalMessages ?? this.totalMessages,
      daysActive: daysActive ?? this.daysActive,
      firstInteractionDate: firstInteractionDate ?? this.firstInteractionDate,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  @override
  String toString() =>
      'UserProfile(name: $name, language: $preferredLanguage, relationship: $relationshipLevel)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          firstInteractionDate == other.firstInteractionDate;

  @override
  int get hashCode => Object.hash(name, firstInteractionDate);
}
