/// Configuration class that defines the AI companion's personality traits.
///
/// Unlike other models in this app, [AIPersonality] is not persisted via Hive.
/// It serves as a runtime configuration that shapes how the AI communicates --
/// its humor, empathy, formality, interests, and dialect preferences. The
/// factory constructor [AIPersonality.defaultPersonality] provides sensible
/// defaults modeled after a warm, funny Moroccan friend.
class AIPersonality {
  /// The greeting style used when starting conversations.
  ///
  /// Examples: "Salam! Labas?", "Ahlan ya sahbi!", "Hey, kidayra?"
  final String greetingStyle;

  /// How humorous the AI should be, on a 0-10 scale.
  /// 0 = completely serious, 10 = always cracking jokes.
  final int humorLevel;

  /// How empathetic the AI should be, on a 0-10 scale.
  /// 0 = neutral/factual, 10 = deeply understanding and supportive.
  final int empathyLevel;

  /// How formal the AI's language should be, on a 0-10 scale.
  /// 0 = very casual/slang-heavy, 10 = highly formal and polished.
  final int formalityLevel;

  /// A list of topics and interests the AI is enthusiastic about.
  ///
  /// Used to steer conversations and generate relevant responses.
  final List<String> interests;

  /// The preferred Moroccan Darija dialect flavor.
  ///
  /// Can specify a city or region (e.g., "casablanca", "fes", "rif")
  /// to fine-tune vocabulary and expressions.
  final String darijaDialectPreference;

  const AIPersonality({
    required this.greetingStyle,
    required this.humorLevel,
    required this.empathyLevel,
    required this.formalityLevel,
    required this.interests,
    required this.darijaDialectPreference,
  });

  /// Creates a default AI personality modeled after a warm, funny Moroccan friend.
  ///
  /// The defaults lean casual, humorous, and empathetic -- like chatting with
  /// a close friend from Casablanca who loves food, music, and good stories.
  factory AIPersonality.defaultPersonality() {
    return const AIPersonality(
      greetingStyle: 'Salam! Labas 3lik? Kidayra/ridayr?',
      humorLevel: 7,
      empathyLevel: 8,
      formalityLevel: 2,
      interests: [
        'moroccan_cuisine',
        'gnawa_music',
        'football',
        'moroccan_cinema',
        'travel',
        'street_food',
        'comedy',
        'storytelling',
      ],
      darijaDialectPreference: 'casablanca',
    );
  }

  /// Creates a copy of this personality with the given fields replaced
  /// by new values.
  AIPersonality copyWith({
    String? greetingStyle,
    int? humorLevel,
    int? empathyLevel,
    int? formalityLevel,
    List<String>? interests,
    String? darijaDialectPreference,
  }) {
    return AIPersonality(
      greetingStyle: greetingStyle ?? this.greetingStyle,
      humorLevel: humorLevel ?? this.humorLevel,
      empathyLevel: empathyLevel ?? this.empathyLevel,
      formalityLevel: formalityLevel ?? this.formalityLevel,
      interests: interests ?? this.interests,
      darijaDialectPreference:
          darijaDialectPreference ?? this.darijaDialectPreference,
    );
  }

  @override
  String toString() =>
      'AIPersonality(humor: $humorLevel, empathy: $empathyLevel, '
      'formality: $formalityLevel, dialect: $darijaDialectPreference)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AIPersonality &&
          runtimeType == other.runtimeType &&
          greetingStyle == other.greetingStyle &&
          humorLevel == other.humorLevel &&
          empathyLevel == other.empathyLevel &&
          formalityLevel == other.formalityLevel &&
          darijaDialectPreference == other.darijaDialectPreference;

  @override
  int get hashCode => Object.hash(
        greetingStyle,
        humorLevel,
        empathyLevel,
        formalityLevel,
        darijaDialectPreference,
      );
}
