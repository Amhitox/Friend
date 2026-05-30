import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../models/usage_tracker.dart';

/// Central feature gating service for the Dostok app.
///
/// Maps every gated feature to a minimum [SubscriptionTier] and provides
/// methods to check access, compute remaining quotas, build Darija gate
/// messages, and drive upgrade prompts. All methods are static so callers
/// do not need a service instance -- pass in the current [Subscription],
/// [DailyUsage], and [UsageLimits] from the relevant provider.
///
/// Usage:
/// ```dart
/// if (FeatureGate.canUse(FeatureGate.voiceCalls, tier: tier, usage: usage, limits: limits)) {
///   // start call
/// } else {
///   FeatureGate.showUpgradePrompt(context, FeatureGate.voiceCalls);
/// }
/// ```
abstract final class FeatureGate {
  // ---------------------------------------------------------------------------
  // Feature constants
  // ---------------------------------------------------------------------------

  /// Unlimited AI-powered message responses (free tier has a daily cap).
  static const String unlimitedMessages = 'unlimited_messages';

  /// Voice call functionality (requires call minutes).
  static const String voiceCalls = 'voice_calls';

  /// Ability to create a custom AI personality.
  static const String customPersonality = 'custom_personality';

  /// AI-initiated proactive messages (VIP only).
  static const String proactiveMessages = 'proactive_messages';

  /// Mood analytics and emotional trend tracking.
  static const String moodAnalytics = 'mood_analytics';

  /// Voice cloning feature (VIP only).
  static const String voiceCloning = 'voice_cloning';

  /// Export conversation history to file.
  static const String exportHistory = 'export_history';

  /// Faster AI response speed.
  static const String priorityResponse = 'priority_response';

  /// Ad-free experience.
  static const String noAds = 'no_ads';

  /// Multiple custom AI personalities.
  static const String multiplePersonalities = 'multiple_personalities';

  /// Daily emotional check-in prompts.
  static const String dailyCheckins = 'daily_checkins';

  /// All feature identifiers for iteration.
  static const List<String> allFeatures = [
    unlimitedMessages,
    voiceCalls,
    customPersonality,
    proactiveMessages,
    moodAnalytics,
    voiceCloning,
    exportHistory,
    priorityResponse,
    noAds,
    multiplePersonalities,
    dailyCheckins,
  ];

  // ---------------------------------------------------------------------------
  // Feature -> minimum tier mapping
  // ---------------------------------------------------------------------------

  static const Map<String, SubscriptionTier> _featureTiers = {
    unlimitedMessages: SubscriptionTier.free,
    voiceCalls: SubscriptionTier.premium,
    customPersonality: SubscriptionTier.premium,
    proactiveMessages: SubscriptionTier.vip,
    moodAnalytics: SubscriptionTier.premium,
    voiceCloning: SubscriptionTier.vip,
    exportHistory: SubscriptionTier.vip,
    priorityResponse: SubscriptionTier.premium,
    noAds: SubscriptionTier.vip,
    multiplePersonalities: SubscriptionTier.vip,
    dailyCheckins: SubscriptionTier.premium,
  };

  // ---------------------------------------------------------------------------
  // Feature -> human-readable label (Darija + French mix)
  // ---------------------------------------------------------------------------

  static const Map<String, String> _featureLabels = {
    unlimitedMessages: 'Rassayil bla hd',
    voiceCalls: 'Mkimat Sout',
    customPersonality: 'Chakhsiya khassek',
    proactiveMessages: 'Rassayil mn sadiqek',
    moodAnalytics: 'Tahlil mood dyalek',
    voiceCloning: 'Nskhal sotek',
    exportHistory: 'Kharraj al-moujawalat',
    priorityResponse: 'Jawab b sir3a',
    noAds: 'Bla i3lanat',
    multiplePersonalities: 'Chakhsiyat ktar',
    dailyCheckins: 'Check-in nihari',
  };

  // ---------------------------------------------------------------------------
  // canUse
  // ---------------------------------------------------------------------------

  /// Returns `true` if the user can access [feature] right now.
  ///
  /// Checks both the subscription tier and, for metered features (messages,
  /// calls), the daily usage against the [limits].
  static bool canUse(
    String feature, {
    required SubscriptionTier tier,
    required DailyUsage usage,
    required UsageLimits limits,
  }) {
    final requiredTier = _featureTiers[feature];
    if (requiredTier == null) return true; // unknown feature -> allow

    // Tier check: VIP > Premium > Free
    if (_tierIndex(tier) < _tierIndex(requiredTier)) return false;

    // Metered features: also check daily quota
    switch (feature) {
      case unlimitedMessages:
        return limits.canReceiveAiResponse(usage);
      case voiceCalls:
        return limits.canMakeCall(usage);
      default:
        return true;
    }
  }

  // ---------------------------------------------------------------------------
  // getRemainingQuota
  // ---------------------------------------------------------------------------

  /// Returns the remaining quota for [feature].
  ///
  /// For metered features this is a count (messages) or minutes (calls).
  /// For boolean features returns -1 (unlimited) or 0 (locked).
  /// For unlimited tiers returns -1.
  static num getRemainingQuota(
    String feature, {
    required SubscriptionTier tier,
    required DailyUsage usage,
    required UsageLimits limits,
  }) {
    final requiredTier = _featureTiers[feature];
    if (requiredTier == null) return -1;

    if (_tierIndex(tier) < _tierIndex(requiredTier)) return 0;

    switch (feature) {
      case unlimitedMessages:
        return limits.getRemainingMessages(usage);
      case voiceCalls:
        return limits.getRemainingCallMinutes(usage);
      default:
        return -1; // boolean feature, available
    }
  }

  // ---------------------------------------------------------------------------
  // gateMessage
  // ---------------------------------------------------------------------------

  /// Returns a Darija gate message explaining that [feature] requires an
  /// upgrade. If the feature is not gated, returns `null`.
  static String? gateMessage(String feature) {
    final requiredTier = _featureTiers[feature];
    if (requiredTier == null) return null;

    final label = _featureLabels[feature] ?? feature;
    switch (requiredTier) {
      case SubscriptionTier.free:
        return null; // free features are not gated
      case SubscriptionTier.premium:
        return 'Chri Premium bach t9der tsta3mel "$label". '
            'Dir upgrade daba w jarrab kolchi!';
      case SubscriptionTier.vip:
        return 'Hadi khassa VIP. Chri VIP bach tfta7 "$label" '
            'w bzf features akhra!';
    }
  }

  /// Returns a Darija message for when a metered feature's daily quota is
  /// exhausted.
  static String quotaExhaustedMessage(String feature) {
    switch (feature) {
      case unlimitedMessages:
        return 'Slafti kol rassayil dyalek l-yum! '
            'Chri Premium bach tkon rassayil bla hd.';
      case voiceCalls:
        return 'Daz w9t l-mkimat dyalek l-yum. '
            'Chri Premium bach tzid dkhal l-mkimat.';
      default:
        return 'Slafti limit dyalek l-yum. '
            'Dir upgrade bach tkml.';
    }
  }

  // ---------------------------------------------------------------------------
  // showUpgradePrompt
  // ---------------------------------------------------------------------------

  /// Navigates to the paywall screen.
  ///
  /// The route name is assumed to be `/paywall`. Adjust if the app uses a
  /// different route. The [feature] is passed as a query argument so the
  /// paywall can highlight the relevant benefit.
  static void showUpgradePrompt(BuildContext context, String feature) {
    Navigator.of(context).pushNamed(
      '/paywall',
      arguments: {'highlightFeature': feature},
    );
  }

  /// Shows a bottom sheet with an upgrade prompt instead of navigating.
  ///
  /// Useful for inline gating where a full-screen navigation would be
  /// disruptive.
  static void showUpgradeBottomSheet(BuildContext context, String feature) {
    final label = _featureLabels[feature] ?? feature;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Hadi khassa abonnement',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                gateMessage(feature) ??
                    'Dir upgrade bach tfta7 "$label".',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    showUpgradePrompt(context, feature);
                  },
                  child: const Text('Chri daba'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mba3d'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // isNearLimit
  // ---------------------------------------------------------------------------

  /// Returns `true` if the user has consumed more than [threshold] of their
  /// daily quota for [feature].
  ///
  /// Useful for showing "almost at limit" warnings. [threshold] defaults to
  /// 0.8 (80%). Returns `false` for unlimited or boolean features.
  static bool isNearLimit(
    String feature, {
    required SubscriptionTier tier,
    required DailyUsage usage,
    required UsageLimits limits,
    double threshold = 0.8,
  }) {
    switch (feature) {
      case unlimitedMessages:
        if (limits.maxAiResponsesPerDay == -1) return false;
        final used = usage.aiResponsesReceived;
        final max = limits.maxAiResponsesPerDay;
        return max > 0 && (used / max) >= threshold;
      case voiceCalls:
        if (limits.maxCallMinutesPerDay == -1) return false;
        final used = usage.callMinutesUsed;
        final max = limits.maxCallMinutesPerDay;
        return max > 0 && (used / max) >= threshold;
      default:
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // getFeatureTier
  // ---------------------------------------------------------------------------

  /// Returns the minimum [SubscriptionTier] required to use [feature].
  ///
  /// Returns [SubscriptionTier.free] if the feature is not gated or unknown.
  static SubscriptionTier getFeatureTier(String feature) {
    return _featureTiers[feature] ?? SubscriptionTier.free;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Numeric index for tier comparison (free=0, premium=1, vip=2).
  static int _tierIndex(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.premium:
        return 1;
      case SubscriptionTier.vip:
        return 2;
    }
  }

  /// Returns the human-readable label for [feature].
  static String getFeatureLabel(String feature) {
    return _featureLabels[feature] ?? feature;
  }

  /// Returns usage as a ratio (0.0 -- 1.0) for metered features, or null
  /// for boolean/unlimited features.
  static double? getUsageRatio(
    String feature, {
    required DailyUsage usage,
    required UsageLimits limits,
  }) {
    switch (feature) {
      case unlimitedMessages:
        if (limits.maxAiResponsesPerDay == -1) return null;
        return usage.aiResponsesReceived / limits.maxAiResponsesPerDay;
      case voiceCalls:
        if (limits.maxCallMinutesPerDay == -1) return null;
        return usage.callMinutesUsed / limits.maxCallMinutesPerDay;
      default:
        return null;
    }
  }
}
