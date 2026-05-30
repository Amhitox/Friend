import 'package:hive/hive.dart';

import 'subscription.dart';

part 'usage_tracker.g.dart';

/// Tracks a user's feature consumption for a single calendar day.
///
/// An instance of [DailyUsage] is created or loaded at the start of each day
/// and persisted in Hive. Counters are incremented as the user sends messages,
/// makes calls, and completes check-ins. At midnight the tracker resets.
///
/// Stored in Hive with [typeId] 11.
///
/// Example:
/// ```dart
/// final usage = DailyUsage(date: DateTime.now());
/// usage.messagesSent++;
/// usage.aiResponsesReceived++;
/// usage.callMinutesUsed += 2.5;
/// ```
@HiveType(typeId: 11)
class DailyUsage {
  /// The calendar date this usage record covers (time portion ignored).
  @HiveField(0)
  final DateTime date;

  /// Total text messages the user has sent today.
  @HiveField(1)
  int messagesSent;

  /// Total AI-generated responses the user has received today.
  ///
  /// This counter is the one gated by the free-tier daily limit.
  @HiveField(2)
  int aiResponsesReceived;

  /// Total call minutes consumed today (fractional for precision).
  @HiveField(3)
  double callMinutesUsed;

  /// Number of daily emotional check-ins completed today.
  @HiveField(4)
  int checkInsCompleted;

  /// Creates a [DailyUsage] for the given [date].
  ///
  /// All counters default to zero.
  DailyUsage({
    required this.date,
    this.messagesSent = 0,
    this.aiResponsesReceived = 0,
    this.callMinutesUsed = 0.0,
    this.checkInsCompleted = 0,
  });

  /// Whether this usage record corresponds to today's date.
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Resets all counters to their initial values.
  ///
  /// Call this at the start of a new day or when creating a fresh tracker.
  void reset() {
    messagesSent = 0;
    aiResponsesReceived = 0;
    callMinutesUsed = 0.0;
    checkInsCompleted = 0;
  }

  @override
  String toString() =>
      'DailyUsage(date: $date, msgs: $messagesSent, ai: $aiResponsesReceived, '
      'calls: ${callMinutesUsed.toStringAsFixed(1)}m, checkIns: $checkInsCompleted)';
}

/// Defines the feature limits and capabilities for a subscription tier.
///
/// Each [SubscriptionTier] maps to a specific set of [UsageLimits] that
/// control how many messages, call minutes, and which premium features a
/// user can access. Use [UsageLimits.fromTier] to obtain the correct limits
/// for a given tier.
///
/// Example:
/// ```dart
/// final limits = UsageLimits.fromTier(SubscriptionTier.premium);
/// if (limits.canSendMessage(usage)) {
///   // Allow sending
/// } else {
///   // Show paywall
/// }
/// ```
class UsageLimits {
  /// Maximum AI responses allowed per day. -1 means unlimited.
  final int maxAiResponsesPerDay;

  /// Maximum call minutes allowed per day. -1 means unlimited.
  final double maxCallMinutesPerDay;

  /// Maximum number of custom personalities the user can create. -1 means
  /// unlimited.
  final int maxCustomPersonalities;

  /// Whether the user can use voice cloning features.
  final bool hasVoiceCloning;

  /// Whether the user receives proactive messages from their AI friend.
  final bool hasProactiveMessages;

  /// Whether the user has access to mood analytics and trends.
  final bool hasMoodAnalytics;

  /// Whether the user can export their conversation history.
  final bool hasExportHistory;

  /// Whether the user receives priority (faster) AI responses.
  final bool hasPriorityResponse;

  /// Whether ads are shown to the user.
  final bool showAds;

  /// Creates [UsageLimits] with explicit values for every feature gate.
  const UsageLimits({
    required this.maxAiResponsesPerDay,
    required this.maxCallMinutesPerDay,
    required this.maxCustomPersonalities,
    required this.hasVoiceCloning,
    required this.hasProactiveMessages,
    required this.hasMoodAnalytics,
    required this.hasExportHistory,
    required this.hasPriorityResponse,
    required this.showAds,
  });

  // ---------------------------------------------------------------------------
  // Tier-specific factories
  // ---------------------------------------------------------------------------

  /// Returns the [UsageLimits] corresponding to the given [tier].
  ///
  /// This is the single source of truth for feature gating across the app.
  static UsageLimits fromTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return _freeLimits;
      case SubscriptionTier.premium:
        return _premiumLimits;
      case SubscriptionTier.vip:
        return _vipLimits;
    }
  }

  static const UsageLimits _freeLimits = UsageLimits(
    maxAiResponsesPerDay: 20,
    maxCallMinutesPerDay: 0,
    maxCustomPersonalities: 0,
    hasVoiceCloning: false,
    hasProactiveMessages: false,
    hasMoodAnalytics: false,
    hasExportHistory: false,
    hasPriorityResponse: false,
    showAds: true,
  );

  static const UsageLimits _premiumLimits = UsageLimits(
    maxAiResponsesPerDay: -1,
    maxCallMinutesPerDay: 30,
    maxCustomPersonalities: 1,
    hasVoiceCloning: false,
    hasProactiveMessages: false,
    hasMoodAnalytics: true,
    hasExportHistory: false,
    hasPriorityResponse: true,
    showAds: true,
  );

  static const UsageLimits _vipLimits = UsageLimits(
    maxAiResponsesPerDay: -1,
    maxCallMinutesPerDay: 120,
    maxCustomPersonalities: -1,
    hasVoiceCloning: true,
    hasProactiveMessages: true,
    hasMoodAnalytics: true,
    hasExportHistory: true,
    hasPriorityResponse: true,
    showAds: false,
  );

  // ---------------------------------------------------------------------------
  // Helper methods
  // ---------------------------------------------------------------------------

  /// Checks whether the user can send another message given their [usage].
  ///
  /// Text messages are always unlimited (the free tier allows unlimited
  /// text, only AI responses are gated). This method therefore always
  /// returns `true`.
  ///
  /// For AI-response gating, use [canReceiveAiResponse] instead.
  bool canSendMessage(DailyUsage usage) {
    // Text messages are unlimited for all tiers.
    return true;
  }

  /// Checks whether the user can receive another AI response given their
  /// [usage].
  ///
  /// Returns `true` if the tier has unlimited AI responses
  /// ([maxAiResponsesPerDay] == -1) or if today's count is still below the
  /// limit.
  bool canReceiveAiResponse(DailyUsage usage) {
    if (maxAiResponsesPerDay == -1) return true;
    return usage.aiResponsesReceived < maxAiResponsesPerDay;
  }

  /// Checks whether the user can initiate or continue a call given their
  /// [usage].
  ///
  /// Returns `true` if the tier has unlimited call minutes
  /// ([maxCallMinutesPerDay] == -1) or if the remaining allowance is greater
  /// than zero.
  bool canMakeCall(DailyUsage usage) {
    if (maxCallMinutesPerDay == -1) return true;
    return usage.callMinutesUsed < maxCallMinutesPerDay;
  }

  /// Returns the number of AI responses remaining today, or -1 if unlimited.
  int getRemainingMessages(DailyUsage usage) {
    if (maxAiResponsesPerDay == -1) return -1;
    final remaining = maxAiResponsesPerDay - usage.aiResponsesReceived;
    return remaining.clamp(0, maxAiResponsesPerDay);
  }

  /// Returns the number of call minutes remaining today, or -1 if unlimited.
  double getRemainingCallMinutes(DailyUsage usage) {
    if (maxCallMinutesPerDay == -1) return -1;
    final remaining = maxCallMinutesPerDay - usage.callMinutesUsed;
    return remaining.clamp(0.0, maxCallMinutesPerDay);
  }

  /// Whether the user has hit their daily AI response limit.
  bool isAiResponseLimitReached(DailyUsage usage) =>
      !canReceiveAiResponse(usage);

  /// Whether the user has hit their daily call minute limit.
  bool isCallLimitReached(DailyUsage usage) => !canMakeCall(usage);

  @override
  String toString() =>
      'UsageLimits(ai: $maxAiResponsesPerDay/day, calls: '
      '${maxCallMinutesPerDay == -1 ? "unlimited" : "${maxCallMinutesPerDay}m/day"}, '
      'ads: $showAds)';
}
