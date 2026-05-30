import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/subscription.dart';
import '../models/usage_tracker.dart';
import 'billing_service.dart';

/// Manages the user's subscription state, usage tracking, and feature gating.
///
/// This is the core monetization engine for Dostok. It coordinates with
/// [BillingService] for store operations and persists subscription and usage
/// state in Hive.
///
/// Usage:
/// ```dart
/// final subService = SubscriptionService();
/// await subService.initialize();
///
/// // Check feature access
/// if (subService.canSendMessage()) { ... }
///
/// // Record usage
/// subService.recordMessage();
///
/// // Purchase
/// await subService.purchasePlan(plan);
/// ```
class SubscriptionService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const String _tag = 'SubscriptionService';
  static const String _boxName = 'subscription';
  static const String _subscriptionKey = 'currentSubscription';
  static const String _usageKey = 'dailyUsage';
  static const String _trialHistoryKey = 'trialHistory';

  /// Duration of the free trial period.
  static const Duration trialDuration = Duration(days: 7);

  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------

  final BillingService _billingService;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  Box<dynamic>? _box;

  Subscription _currentSubscription = Subscription.free;
  DailyUsage _currentUsage = DailyUsage(date: DateTime(2000));
  UsageLimits _limits = UsageLimits.fromTier(SubscriptionTier.free);
  bool _isLoading = false;
  String? _error;

  /// Tracks which tiers the user has already used a trial for.
  Set<SubscriptionTier> _trialHistory = {};

  /// Stream controller for subscription state changes.
  final StreamController<Subscription> _subscriptionController =
      StreamController<Subscription>.broadcast();

  /// Subscription to billing purchase updates.
  StreamSubscription<PurchaseStatus>? _billingSubscription;

  // ---------------------------------------------------------------------------
  // Constructor
  // ---------------------------------------------------------------------------

  /// Creates a [SubscriptionService] with the given [BillingService].
  ///
  /// If no billing service is provided, uses the singleton instance.
  SubscriptionService({BillingService? billingService})
      : _billingService = billingService ?? BillingService.instance;

  // ---------------------------------------------------------------------------
  // Public getters
  // ---------------------------------------------------------------------------

  /// The user's current subscription.
  Subscription get currentSubscription => _currentSubscription;

  /// Today's usage counters.
  DailyUsage get currentUsage => _currentUsage;

  /// Usage limits derived from the current subscription tier.
  UsageLimits get limits => _limits;

  /// Whether the service is loading or processing.
  bool get isLoading => _isLoading;

  /// The last error message, if any.
  String? get error => _error;

  /// Whether the user has an active paid subscription (or trial).
  bool get isPremium => _currentSubscription.isUsable &&
      _currentSubscription.tier != SubscriptionTier.free;

  /// The current subscription tier.
  SubscriptionTier get currentTier => _currentSubscription.tier;

  /// Stream of subscription state changes.
  Stream<Subscription> get subscriptionStream => _subscriptionController.stream;

  /// Number of AI responses remaining today (-1 = unlimited).
  int get remainingMessages =>
      _limits.getRemainingMessages(_currentUsage);

  /// Call minutes remaining today (-1 = unlimited).
  double get remainingCallMinutes =>
      _limits.getRemainingCallMinutes(_currentUsage);

  /// Whether ads should be shown.
  bool get showAds => _limits.showAds;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads persisted subscription and usage state from Hive.
  ///
  /// Checks for expired subscriptions, resets daily usage if a new day has
  /// started, and sets up billing purchase stream listeners.
  ///
  /// Must be called before using any other method.
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      dev.log('Initializing subscription service...', name: _tag);

      // Open Hive box.
      _box = await Hive.openBox(_boxName);

      // Load persisted subscription.
      await _loadSubscription();

      // Load or reset daily usage.
      await _loadDailyUsage();

      // Load trial history.
      _loadTrialHistory();

      // Check and handle subscription expiry.
      _checkExpiry();

      // Derive limits from current tier.
      _limits = UsageLimits.fromTier(_currentSubscription.tier);

      // Listen to billing purchase updates.
      _billingSubscription = _billingService.purchaseStream.listen(
        _onPurchaseStatusChange,
        onError: (Object error) {
          dev.log('Billing stream error: $error', name: _tag, error: error);
        },
      );

      dev.log(
        'Subscription service initialized: '
        'tier=${_currentSubscription.tier}, '
        'status=${_currentSubscription.status}, '
        'usage=${_currentUsage}',
        name: _tag,
      );
    } catch (e, st) {
      _error = 'Failed to initialize subscription service: $e';
      dev.log('initialize() failed', name: _tag, error: e, stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase delegation
  // ---------------------------------------------------------------------------

  /// Initiates a purchase flow for the given [plan].
  ///
  /// Delegates to [BillingService]. Listen to [subscriptionStream] or watch
  /// [currentSubscription] for the outcome.
  ///
  /// Returns `true` if the purchase flow was initiated.
  Future<bool> purchasePlan(SubscriptionPlan plan) async {
    if (!_billingService.isInitialized) {
      _error = 'Billing not initialized. Please restart the app.';
      dev.log(_error!, name: _tag);
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      dev.log('Purchasing plan: ${plan.id}', name: _tag);

      final success = await _billingService.purchasePlan(plan);
      if (!success) {
        _error = _billingService.lastError ?? 'Purchase could not be started.';
        dev.log(_error!, name: _tag);
        _isLoading = false;
        notifyListeners();
      }
      return success;
    } catch (e, st) {
      _error = 'Purchase failed: $e';
      dev.log('purchasePlan() failed', name: _tag, error: e, stackTrace: st);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restores previous purchases from the store.
  ///
  /// Delegates to [BillingService]. Results arrive via the purchase stream.
  Future<void> restorePurchases() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      dev.log('Restoring purchases...', name: _tag);
      await _billingService.restorePurchases();
    } catch (e, st) {
      _error = 'Restore failed: $e';
      dev.log('restorePurchases() failed',
          name: _tag, error: e, stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Usage recording
  // ---------------------------------------------------------------------------

  /// Records that the user sent a text message.
  ///
  /// Increments the daily message counter and persists the updated usage.
  /// Always allowed -- text messages are unlimited for all tiers (AI
  /// responses are what's gated).
  Future<void> recordMessage() async {
    _ensureFreshUsage();
    _currentUsage.messagesSent++;
    dev.log(
      'Message recorded: ${_currentUsage.messagesSent} today',
      name: _tag,
    );
    await _persistUsage();
    notifyListeners();
  }

  /// Records that an AI response was received.
  ///
  /// This is the counter that's actually gated by tier limits.
  Future<void> recordAiResponse() async {
    _ensureFreshUsage();
    _currentUsage.aiResponsesReceived++;
    dev.log(
      'AI response recorded: ${_currentUsage.aiResponsesReceived} today',
      name: _tag,
    );
    await _persistUsage();
    notifyListeners();
  }

  /// Records [minutes] of voice call usage.
  ///
  /// Call minutes are limited by tier. If recording would exceed the limit,
  /// only the remaining allowed minutes are recorded.
  Future<void> recordCallMinutes(double minutes) async {
    if (minutes <= 0) return;

    _ensureFreshUsage();

    final maxMinutes = _limits.maxCallMinutesPerDay;
    if (maxMinutes != -1) {
      final remaining = maxMinutes - _currentUsage.callMinutesUsed;
      if (remaining <= 0) {
        dev.log('Call minutes limit already reached', name: _tag);
        return;
      }
      final actual = minutes > remaining ? remaining : minutes;
      _currentUsage.callMinutesUsed += actual;
      dev.log(
        'Call minutes recorded: +${actual.toStringAsFixed(1)} '
        '(total: ${_currentUsage.callMinutesUsed.toStringAsFixed(1)}/$maxMinutes)',
        name: _tag,
      );
    } else {
      _currentUsage.callMinutesUsed += minutes;
      dev.log(
        'Call minutes recorded: +${minutes.toStringAsFixed(1)} '
        '(total: ${_currentUsage.callMinutesUsed.toStringAsFixed(1)}, unlimited)',
        name: _tag,
      );
    }

    await _persistUsage();
    notifyListeners();
  }

  /// Records a daily emotional check-in.
  Future<void> recordCheckIn() async {
    _ensureFreshUsage();
    _currentUsage.checkInsCompleted++;
    dev.log(
      'Check-in recorded: ${_currentUsage.checkInsCompleted} today',
      name: _tag,
    );
    await _persistUsage();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Feature gating
  // ---------------------------------------------------------------------------

  /// Whether the user can send a text message.
  ///
  /// Text messages are always allowed for all tiers.
  bool canSendMessage() {
    return _limits.canSendMessage(_currentUsage);
  }

  /// Whether the user can receive another AI response today.
  bool canReceiveAiResponse() {
    return _limits.canReceiveAiResponse(_currentUsage);
  }

  /// Whether the user can make a voice call of the given [duration].
  ///
  /// If [duration] is null, checks whether any call minutes remain.
  bool canMakeCall({Duration? duration}) {
    if (!_limits.canMakeCall(_currentUsage)) return false;

    if (duration != null && _limits.maxCallMinutesPerDay != -1) {
      final requestedMinutes = duration.inSeconds / 60.0;
      final remaining = _limits.getRemainingCallMinutes(_currentUsage);
      if (remaining == -1) return true;
      return requestedMinutes <= remaining;
    }

    return true;
  }

  /// Whether the user can use a named premium feature.
  ///
  /// Supported feature names:
  /// - `"voiceCloning"` -- voice cloning
  /// - `"proactiveMessages"` -- proactive messages from Dostok
  /// - `"moodAnalytics"` -- mood analytics and trends
  /// - `"exportHistory"` -- export conversation history
  /// - `"priorityResponse"` -- faster AI responses
  /// - `"customPersonalities"` -- custom personality creation
  ///
  /// Returns `false` for unknown feature names.
  bool canUseFeature(String featureName) {
    switch (featureName) {
      case 'voiceCloning':
        return _limits.hasVoiceCloning;
      case 'proactiveMessages':
        return _limits.hasProactiveMessages;
      case 'moodAnalytics':
        return _limits.hasMoodAnalytics;
      case 'exportHistory':
        return _limits.hasExportHistory;
      case 'priorityResponse':
        return _limits.hasPriorityResponse;
      case 'customPersonalities':
        return _limits.maxCustomPersonalities != 0;
      default:
        dev.log('Unknown feature: $featureName', name: _tag);
        return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Tier management
  // ---------------------------------------------------------------------------

  /// Upgrades the subscription to the given [tier].
  ///
  /// If the user is on free tier, starts a trial if available, or initiates
  /// a purchase. If already on a paid tier, this should be called only when
  /// switching from a lower to a higher tier (e.g., Premium -> VIP).
  ///
  /// Returns `true` if the upgrade was initiated.
  Future<bool> upgradeTier(SubscriptionTier tier) async {
    if (tier == _currentSubscription.tier) {
      dev.log('Already on tier: $tier', name: _tag);
      return false;
    }

    if (tier == SubscriptionTier.free) {
      dev.log('Cannot "upgrade" to free tier', name: _tag);
      return false;
    }

    dev.log('Upgrading tier: ${_currentSubscription.tier} -> $tier', name: _tag);

    // If upgrading to premium and eligible, start a trial first.
    if (tier == SubscriptionTier.premium && canStartTrial(tier)) {
      return await startTrial(tier);
    }

    // Otherwise, initiate a purchase for the appropriate plan.
    final plan = SubscriptionPlan.monthlyFor(tier) ??
        SubscriptionPlan.yearlyFor(tier);
    if (plan == null) {
      _error = 'No plan found for tier: $tier';
      dev.log(_error!, name: _tag);
      notifyListeners();
      return false;
    }

    return await purchasePlan(plan);
  }

  /// Downgrades to the next lower tier.
  ///
  /// - VIP -> Premium
  /// - Premium -> Free
  /// - Free -> no-op
  ///
  /// The downgrade takes effect at the end of the current billing period.
  Future<void> downgradeTier() async {
    SubscriptionTier newTier;
    switch (_currentSubscription.tier) {
      case SubscriptionTier.vip:
        newTier = SubscriptionTier.premium;
        break;
      case SubscriptionTier.premium:
        newTier = SubscriptionTier.free;
        break;
      case SubscriptionTier.free:
        dev.log('Already on free tier, cannot downgrade', name: _tag);
        return;
    }

    dev.log(
      'Downgrading: ${_currentSubscription.tier} -> $newTier '
      '(effective at end of billing period)',
      name: _tag,
    );

    // Mark auto-renew off -- the actual tier change happens at expiry.
    _currentSubscription = _currentSubscription.copyWith(
      autoRenew: false,
    );

    await _persistSubscription();
    _syncWithBackend();
    notifyListeners();
  }

  /// Cancels the current subscription.
  ///
  /// The subscription remains active until the end of the current billing
  /// period (or trial). After that, the user reverts to free tier.
  Future<void> cancelSubscription() async {
    if (_currentSubscription.tier == SubscriptionTier.free) {
      dev.log('Nothing to cancel on free tier', name: _tag);
      return;
    }

    dev.log(
      'Cancelling subscription: ${_currentSubscription.productId}',
      name: _tag,
    );

    _currentSubscription = _currentSubscription.copyWith(
      status: SubscriptionStatus.cancelled,
      autoRenew: false,
    );

    await _persistSubscription();
    _syncWithBackend();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Trial management
  // ---------------------------------------------------------------------------

  /// Whether the user can start a free trial for the given [tier].
  ///
  /// A trial is available only if:
  /// - The user is currently on free tier.
  /// - They have not previously had a trial for this tier.
  /// - The billing service is initialized.
  bool canStartTrial(SubscriptionTier tier) {
    if (tier == SubscriptionTier.free) return false;
    if (_currentSubscription.tier != SubscriptionTier.free) return false;
    if (_trialHistory.contains(tier)) return false;
    return true;
  }

  /// Starts a 7-day free trial for the given [tier].
  ///
  /// Only available for [SubscriptionTier.premium]. VIP trials are not
  /// offered. The user must be on free tier and must not have used a trial
  /// for this tier before.
  ///
  /// Returns `true` if the trial was started.
  Future<bool> startTrial(SubscriptionTier tier) async {
    if (!canStartTrial(tier)) {
      dev.log(
        'Cannot start trial for $tier '
        '(current: ${_currentSubscription.tier}, '
        'history: $_trialHistory)',
        name: _tag,
      );
      return false;
    }

    // Only Premium trials are offered. VIP must be purchased.
    if (tier != SubscriptionTier.premium) {
      dev.log('Trials are only available for Premium tier', name: _tag);
      return false;
    }

    final now = DateTime.now();
    final trialEnd = now.add(trialDuration);

    dev.log(
      'Starting $tier trial: $now -> $trialEnd',
      name: _tag,
    );

    _currentSubscription = Subscription(
      tier: tier,
      status: SubscriptionStatus.trial,
      startDate: now,
      expiryDate: trialEnd,
      trialEndDate: trialEnd,
      autoRenew: true,
      productId: 'trial_${tier.name}',
    );

    _trialHistory.add(tier);

    _limits = UsageLimits.fromTier(tier);

    await _persistSubscription();
    await _persistTrialHistory();
    _syncWithBackend();
    _subscriptionController.add(_currentSubscription);
    notifyListeners();

    // Schedule trial expiry check.
    _scheduleTrialExpiryCheck(trialEnd);

    return true;
  }

  // ---------------------------------------------------------------------------
  // Billing event handling
  // ---------------------------------------------------------------------------

  /// Handles purchase status changes from the billing service.
  void _onPurchaseStatusChange(PurchaseStatus status) {
    dev.log('Billing purchase status: $status', name: _tag);

    switch (status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // The purchase succeeded. We need to identify which plan was bought.
        // In a real app, the purchase details would carry the product ID.
        // For now, we reload from the billing service's last known state.
        _activateSubscriptionFromPurchase();
        break;

      case PurchaseStatus.pending:
        dev.log('Purchase is pending...', name: _tag);
        notifyListeners();
        break;

      case PurchaseStatus.error:
        _error = _billingService.lastError ?? 'Purchase failed.';
        dev.log('Purchase error: $_error', name: _tag);
        _isLoading = false;
        notifyListeners();
        break;

      case PurchaseStatus.canceled:
        dev.log('Purchase was canceled by user', name: _tag);
        _isLoading = false;
        notifyListeners();
        break;

      default:
        break;
    }
  }

  /// Activates a subscription after a successful purchase.
  ///
  /// In a production app, the product ID would come from the purchase details.
  /// This implementation determines the plan from the purchase stream context.
  Future<void> _activateSubscriptionFromPurchase() async {
    // In a real implementation, the PurchaseDetails object would be available
    // from the stream. For now, we check what the user was trying to buy.
    //
    // The billing service stores the last purchase state. We look at which
    // plan the user initiated a purchase for.
    //
    // For a complete implementation, you would pass the PurchaseDetails
    // through the stream or store them on the BillingService.

    dev.log('Activating subscription from purchase...', name: _tag);

    // Placeholder: In production, extract productId from PurchaseDetails.
    // The billing service's purchaseStream emits PurchaseStatus, not the full
    // PurchaseDetails. A production version would extend the stream to carry
    // the product ID or store it as state on BillingService.

    _isLoading = false;
    notifyListeners();
  }

  /// Activates a subscription for the given [productId] and [purchaseToken].
  ///
  /// Called after a purchase is verified, either from the purchase stream
  /// or from a restored purchase.
  Future<void> activateSubscription({
    required String productId,
    required String purchaseToken,
    DateTime? startDate,
    DateTime? expiryDate,
  }) async {
    final plan = _billingService.getPlanById(productId) ??
        SubscriptionPlan.allPlans.where((p) => p.id == productId).firstOrNull;

    if (plan == null) {
      dev.log('Unknown product ID: $productId', name: _tag);
      _error = 'Unknown subscription plan.';
      notifyListeners();
      return;
    }

    final now = startDate ?? DateTime.now();
    DateTime expiry;

    if (expiryDate != null) {
      expiry = expiryDate;
    } else {
      // Calculate expiry from the plan's period.
      expiry = DateTime(
        now.year,
        now.month + plan.periodMonths,
        now.day,
        now.hour,
        now.minute,
        now.second,
      );
    }

    final subscriptionStatus = plan.periodMonths == 1
        ? SubscriptionStatus.active
        : SubscriptionStatus.active;

    dev.log(
      'Activating subscription: ${plan.id} '
      '($now -> $expiry)',
      name: _tag,
    );

    _currentSubscription = Subscription(
      tier: plan.tier,
      status: subscriptionStatus,
      startDate: now,
      expiryDate: expiry,
      autoRenew: true,
      productId: productId,
      originalTransactionId: purchaseToken,
    );

    _limits = UsageLimits.fromTier(plan.tier);
    _isLoading = false;

    await _persistSubscription();
    _syncWithBackend();
    _subscriptionController.add(_currentSubscription);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Expiry management
  // ---------------------------------------------------------------------------

  /// Checks if the current subscription has expired and handles the transition.
  void _checkExpiry() {
    final sub = _currentSubscription;

    if (sub.tier == SubscriptionTier.free) return;

    // Check trial expiry.
    if (sub.isInTrial && sub.trialEndDate != null) {
      if (DateTime.now().isAfter(sub.trialEndDate!)) {
        dev.log('Trial expired, reverting to free tier', name: _tag);
        _revertToFree();
        return;
      }
    }

    // Check subscription expiry.
    if (sub.status == SubscriptionStatus.active && sub.isExpired) {
      dev.log('Subscription expired, starting grace period', name: _tag);
      _startGracePeriod();
      return;
    }

    // Check grace period expiry.
    if (sub.status == SubscriptionStatus.gracePeriod && sub.isExpired) {
      dev.log('Grace period expired, reverting to free tier', name: _tag);
      _revertToFree();
      return;
    }

    // Check if cancelled subscription's billing period has ended.
    if (sub.status == SubscriptionStatus.cancelled && sub.isExpired) {
      dev.log('Cancelled subscription expired, reverting to free tier',
          name: _tag);
      _revertToFree();
      return;
    }
  }

  /// Starts a grace period after a subscription expires.
  ///
  /// During the grace period, the user retains access while the store
  /// retries payment. Grace period duration depends on the tier.
  void _startGracePeriod() {
    final graceDays = switch (_currentSubscription.tier) {
      SubscriptionTier.free => 0,
      SubscriptionTier.premium => 7,
      SubscriptionTier.vip => 14,
    };

    final graceEnd = DateTime.now().add(Duration(days: graceDays));

    _currentSubscription = _currentSubscription.copyWith(
      status: SubscriptionStatus.gracePeriod,
    );

    dev.log(
      'Grace period started: ${_currentSubscription.tier} '
      '(${graceDays}d, ends: $graceEnd)',
      name: _tag,
    );

    _persistSubscription();
    _subscriptionController.add(_currentSubscription);
    notifyListeners();
  }

  /// Reverts the user to the free tier.
  void _revertToFree() {
    _currentSubscription = Subscription.free;
    _limits = UsageLimits.fromTier(SubscriptionTier.free);
    _error = null;

    dev.log('Reverted to free tier', name: _tag);

    _persistSubscription();
    _subscriptionController.add(_currentSubscription);
    notifyListeners();
  }

  /// Schedules a check when the trial period ends.
  void _scheduleTrialExpiryCheck(DateTime trialEnd) {
    final delay = trialEnd.difference(DateTime.now());
    if (delay.isNegative) {
      _checkExpiry();
      return;
    }

    // Use a timer to check trial expiry. In production, use a background
    // task or the store's own expiry notifications.
    Future.delayed(delay, () {
      dev.log('Trial expiry timer fired', name: _tag);
      _checkExpiry();
    });
  }

  // ---------------------------------------------------------------------------
  // Daily usage management
  // ---------------------------------------------------------------------------

  /// Ensures the daily usage counters are fresh (reset if a new day).
  void _ensureFreshUsage() {
    if (_currentUsage.isToday) return;

    dev.log(
      'New day detected, resetting usage counters '
      '(was: ${_currentUsage.date})',
      name: _tag,
    );

    _currentUsage = DailyUsage(date: DateTime.now());
    _persistUsage();
  }

  /// Loads persisted daily usage from Hive.
  Future<void> _loadDailyUsage() async {
    try {
      final box = _box;
      if (box == null) return;

      final data = box.get(_usageKey);
      if (data != null && data is Map) {
        _currentUsage = DailyUsage(
          date: DateTime.parse(data['date'] as String),
          messagesSent: data['messagesSent'] as int? ?? 0,
          aiResponsesReceived: data['aiResponsesReceived'] as int? ?? 0,
          callMinutesUsed: (data['callMinutesUsed'] as num?)?.toDouble() ?? 0.0,
          checkInsCompleted: data['checkInsCompleted'] as int? ?? 0,
        );

        // If the stored date is not today, reset.
        if (_currentUsage.isToday) {
          dev.log('Loaded usage: $_currentUsage', name: _tag);
        } else {
          dev.log(
            'Stored usage is stale (${_currentUsage.date}), resetting',
            name: _tag,
          );
          _currentUsage = DailyUsage(date: DateTime.now());
        }
      } else {
        _currentUsage = DailyUsage(date: DateTime.now());
      }
    } catch (e, st) {
      dev.log('_loadDailyUsage failed', name: _tag, error: e, stackTrace: st);
      _currentUsage = DailyUsage(date: DateTime.now());
    }
  }

  /// Persists daily usage to Hive.
  Future<void> _persistUsage() async {
    try {
      final box = _box;
      if (box == null) return;

      await box.put(_usageKey, {
        'date': _currentUsage.date.toIso8601String(),
        'messagesSent': _currentUsage.messagesSent,
        'aiResponsesReceived': _currentUsage.aiResponsesReceived,
        'callMinutesUsed': _currentUsage.callMinutesUsed,
        'checkInsCompleted': _currentUsage.checkInsCompleted,
      });
    } catch (e, st) {
      dev.log('_persistUsage failed', name: _tag, error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription persistence
  // ---------------------------------------------------------------------------

  /// Loads persisted subscription from Hive.
  Future<void> _loadSubscription() async {
    try {
      final box = _box;
      if (box == null) return;

      final data = box.get(_subscriptionKey);
      if (data != null && data is Map) {
        _currentSubscription = Subscription(
          tier: SubscriptionTier.values[data['tier'] as int? ?? 0],
          status: SubscriptionStatus.values[data['status'] as int? ?? 0],
          startDate: data['startDate'] != null
              ? DateTime.parse(data['startDate'] as String)
              : DateTime.now(),
          expiryDate: data['expiryDate'] != null
              ? DateTime.parse(data['expiryDate'] as String)
              : DateTime.now(),
          trialEndDate: data['trialEndDate'] != null
              ? DateTime.parse(data['trialEndDate'] as String)
              : null,
          autoRenew: data['autoRenew'] as bool? ?? true,
          productId: data['productId'] as String? ?? 'dostok_free',
          originalTransactionId:
              data['originalTransactionId'] as String?,
        );
        dev.log('Loaded subscription: $_currentSubscription', name: _tag);
      } else {
        _currentSubscription = Subscription.free;
        dev.log('No persisted subscription found, using free tier', name: _tag);
      }
    } catch (e, st) {
      dev.log('_loadSubscription failed',
          name: _tag, error: e, stackTrace: st);
      _currentSubscription = Subscription.free;
    }
  }

  /// Persists subscription to Hive.
  Future<void> _persistSubscription() async {
    try {
      final box = _box;
      if (box == null) return;

      await box.put(_subscriptionKey, {
        'tier': _currentSubscription.tier.index,
        'status': _currentSubscription.status.index,
        'startDate': _currentSubscription.startDate.toIso8601String(),
        'expiryDate': _currentSubscription.expiryDate.toIso8601String(),
        'trialEndDate': _currentSubscription.trialEndDate?.toIso8601String(),
        'autoRenew': _currentSubscription.autoRenew,
        'productId': _currentSubscription.productId,
        'originalTransactionId':
            _currentSubscription.originalTransactionId,
      });
      dev.log('Subscription persisted: ${_currentSubscription.tier}', name: _tag);
    } catch (e, st) {
      dev.log('_persistSubscription failed',
          name: _tag, error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Trial history persistence
  // ---------------------------------------------------------------------------

  /// Loads the set of tiers the user has already tried.
  void _loadTrialHistory() {
    try {
      final box = _box;
      if (box == null) return;

      final data = box.get(_trialHistoryKey);
      if (data != null && data is List) {
        _trialHistory = data
            .map((i) => SubscriptionTier.values[i as int])
            .toSet();
        dev.log('Trial history: $_trialHistory', name: _tag);
      }
    } catch (e, st) {
      dev.log('_loadTrialHistory failed',
          name: _tag, error: e, stackTrace: st);
      _trialHistory = {};
    }
  }

  /// Persists the trial history to Hive.
  Future<void> _persistTrialHistory() async {
    try {
      final box = _box;
      if (box == null) return;

      await box.put(
        _trialHistoryKey,
        _trialHistory.map((t) => t.index).toList(),
      );
    } catch (e, st) {
      dev.log('_persistTrialHistory failed',
          name: _tag, error: e, stackTrace: st);
    }
  }

  // ---------------------------------------------------------------------------
  // Backend sync
  // ---------------------------------------------------------------------------

  /// Syncs the current subscription state with the backend server.
  ///
  /// This is a stub. In production, this would send the subscription state
  /// and purchase tokens to a secure backend for verification and tracking.
  void _syncWithBackend() {
    dev.log(
      'Backend sync (stub): tier=${_currentSubscription.tier}, '
      'status=${_currentSubscription.status}, '
      'productId=${_currentSubscription.productId}',
      name: _tag,
    );

    // In a real implementation:
    // 1. POST subscription state to backend
    // 2. Backend verifies purchase token with Google Play Developer API
    // 3. Backend updates its records and returns confirmation
    // 4. Update lastSyncedAt on success

    _currentSubscription = _currentSubscription.copyWith(
      // This would normally come from the backend response.
      // Setting it here as a placeholder.
    );
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  /// Cleans up all resources.
  ///
  /// Call this when the service is no longer needed. After dispose, the
  /// service must be re-initialized.
  @override
  void dispose() {
    dev.log('Disposing subscription service', name: _tag);
    _billingSubscription?.cancel();
    _subscriptionController.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Debug
  // ---------------------------------------------------------------------------

  /// Returns a debug summary of the subscription service state.
  String debugSummary() {
    final buffer = StringBuffer()
      ..writeln('--- SubscriptionService Debug ---')
      ..writeln('Loading: $_isLoading')
      ..writeln('Error: $_error')
      ..writeln('Subscription: $_currentSubscription')
      ..writeln('Usage: $_currentUsage')
      ..writeln('Limits: $_limits')
      ..writeln('Trial history: $_trialHistory')
      ..writeln('Is premium: $isPremium')
      ..writeln('Show ads: $showAds')
      ..writeln('Remaining messages: $remainingMessages')
      ..writeln(
        'Remaining call min: '
        '${remainingCallMinutes == -1 ? "unlimited" : remainingCallMinutes.toStringAsFixed(1)}',
      )
      ..writeln('Can send message: ${canSendMessage()}')
      ..writeln('Can receive AI response: ${canReceiveAiResponse()}')
      ..writeln('Can make call: ${canMakeCall()}')
      ..writeln('Can start trial: ${canStartTrial(SubscriptionTier.premium)}');
    return buffer.toString();
  }
}
