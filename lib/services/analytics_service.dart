import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  FirebaseAnalyticsObserver? _observer;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver? get observer => _observer;

  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
    _observer = FirebaseAnalyticsObserver(analytics: _analytics);

    await _analytics.setAnalyticsCollectionEnabled(!kDebugMode);

    if (kDebugMode) {
      debugPrint('[Analytics] Initialized (collection disabled in debug)');
    }
  }

  // Generic event logging
  Future<void> logEvent(String name, {Map<String, Object>? params}) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: params,
      );
      if (kDebugMode) {
        debugPrint('[Analytics] Event: $name, params: $params');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging event $name: $e');
      }
    }
  }

  // App lifecycle events
  Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  Future<void> logAppClose() async {
    await logEvent('app_close');
  }

  // Messaging events
  Future<void> logMessageSent({String? messageType, int? length}) async {
    await logEvent('message_sent', params: {
      if (messageType != null) 'message_type': messageType,
      if (length != null) 'message_length': length,
    });
  }

  Future<void> logMessageReceived({String? messageType}) async {
    await logEvent('message_received', params: {
      if (messageType != null) 'message_type': messageType,
    });
  }

  // Call events
  Future<void> logCallStarted({String? callType}) async {
    await logEvent('call_started', params: {
      if (callType != null) 'call_type': callType,
    });
  }

  Future<void> logCallEnded({required int durationSeconds, String? callType}) async {
    await logEvent('call_ended', params: {
      'duration_seconds': durationSeconds,
      if (callType != null) 'call_type': callType,
    });
  }

  // Subscription events
  Future<void> logSubscriptionViewed({String? planId}) async {
    await logEvent('subscription_viewed', params: {
      if (planId != null) 'plan_id': planId,
    });
  }

  Future<void> logSubscriptionStarted({required String planId, double? price}) async {
    await logEvent('subscription_started', params: {
      'plan_id': planId,
      if (price != null) 'price': price,
    });
  }

  Future<void> logSubscriptionCompleted({
    required String planId,
    required double price,
    required String currency,
  }) async {
    await logEvent('subscription_completed', params: {
      'plan_id': planId,
      'price': price,
      'currency': currency,
    });
  }

  Future<void> logSubscriptionCancelled({required String planId, String? reason}) async {
    await logEvent('subscription_cancelled', params: {
      'plan_id': planId,
      if (reason != null) 'cancel_reason': reason,
    });
  }

  // Paywall events
  Future<void> logPaywallShown({String? trigger, String? placement}) async {
    await logEvent('paywall_shown', params: {
      if (trigger != null) 'trigger': trigger,
      if (placement != null) 'placement': placement,
    });
  }

  Future<void> logPaywallDismissed({String? placement}) async {
    await logEvent('paywall_dismissed', params: {
      if (placement != null) 'placement': placement,
    });
  }

  Future<void> logPaywallUpgraded({required String planId, String? placement}) async {
    await logEvent('paywall_upgraded', params: {
      'plan_id': planId,
      if (placement != null) 'placement': placement,
    });
  }

  // Trial events
  Future<void> logTrialStarted({required String planId, int? trialDays}) async {
    await logEvent('trial_started', params: {
      'plan_id': planId,
      if (trialDays != null) 'trial_days': trialDays,
    });
  }

  Future<void> logTrialConverted({required String planId}) async {
    await logEvent('trial_converted', params: {
      'plan_id': planId,
    });
  }

  Future<void> logTrialExpired({required String planId}) async {
    await logEvent('trial_expired', params: {
      'plan_id': planId,
    });
  }

  // Ad events
  Future<void> logAdShown({required String adType, String? placement}) async {
    await logEvent('ad_shown', params: {
      'ad_type': adType,
      if (placement != null) 'placement': placement,
    });
  }

  Future<void> logAdClicked({required String adType, String? placement}) async {
    await logEvent('ad_clicked', params: {
      'ad_type': adType,
      if (placement != null) 'placement': placement,
    });
  }

  Future<void> logRewardedAdCompleted({required String rewardType, int? rewardAmount}) async {
    await logEvent('rewarded_ad_completed', params: {
      'reward_type': rewardType,
      if (rewardAmount != null) 'reward_amount': rewardAmount,
    });
  }

  // Feature usage
  Future<void> logFeatureUsed({required String featureName, Map<String, dynamic>? extra}) async {
    await logEvent('feature_used', params: {
      'feature_name': featureName,
      if (extra != null) ...extra,
    });
  }

  // Daily check-in and mood
  Future<void> logDailyCheckinCompleted({String? mood, int? streakDays}) async {
    await logEvent('daily_checkin_completed', params: {
      if (mood != null) 'mood': mood,
      if (streakDays != null) 'streak_days': streakDays,
    });
  }

  Future<void> logMoodSelected({required String mood}) async {
    await logEvent('mood_selected', params: {
      'mood': mood,
    });
  }

  // Onboarding
  Future<void> logOnboardingCompleted({int? durationSeconds, int? stepsCompleted}) async {
    await logEvent('onboarding_completed', params: {
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (stepsCompleted != null) 'steps_completed': stepsCompleted,
    });
  }

  Future<void> logOnboardingSkipped({required int stepSkippedAt}) async {
    await logEvent('onboarding_skipped', params: {
      'step_skipped_at': stepSkippedAt,
    });
  }

  // User properties
  Future<void> setUserProperties({
    String? tier,
    int? daysActive,
    int? totalMessages,
  }) async {
    try {
      if (tier != null) {
        await _analytics.setUserProperty(name: 'user_tier', value: tier);
      }
      if (daysActive != null) {
        await _analytics.setUserProperty(
          name: 'days_active',
          value: daysActive.toString(),
        );
      }
      if (totalMessages != null) {
        await _analytics.setUserProperty(
          name: 'total_messages',
          value: totalMessages.toString(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error setting user properties: $e');
      }
    }
  }

  Future<void> setUserId(String uid) async {
    try {
      await _analytics.setUserId(id: uid);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error setting user ID: $e');
      }
    }
  }

  // Screen tracking
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging screen view: $e');
      }
    }
  }

  // Revenue tracking
  Future<void> logRevenue({
    required double amount,
    required String currency,
    required String productId,
    int? quantity,
    String? transactionId,
  }) async {
    try {
      await _analytics.logPurchase(
        currency: currency,
        value: amount,
        items: [
          AnalyticsEventItem(
            itemId: productId,
            itemName: productId,
            quantity: quantity ?? 1,
          ),
        ],
      );

      // Also log as custom event for more flexibility
      await logEvent('revenue_event', params: {
        'amount': amount,
        'currency': currency,
        'product_id': productId,
        if (quantity != null) 'quantity': quantity,
        if (transactionId != null) 'transaction_id': transactionId,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Analytics] Error logging revenue: $e');
      }
    }
  }

  // Conversion funnel helpers
  Future<void> logFunnelStep({
    required String funnelName,
    required int step,
    required String stepName,
    Map<String, dynamic>? params,
  }) async {
    await logEvent('funnel_step', params: {
      'funnel_name': funnelName,
      'step': step,
      'step_name': stepName,
      if (params != null) ...params,
    });
  }
}
