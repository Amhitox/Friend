import 'package:hive/hive.dart';

part 'subscription.g.dart';

/// Represents the available subscription tiers for Dostok.
///
/// Each tier unlocks progressively more features and higher usage limits.
/// The [free] tier provides basic access, [premium] unlocks most features,
/// and [vip] gives unrestricted access to everything.
@HiveType(typeId: 8)
enum SubscriptionTier {
  /// Basic access with limited AI responses and call minutes.
  @HiveField(0)
  free,

  /// Unlimited messages, custom personalities, mood analytics, and more.
  @HiveField(1)
  premium,

  /// Full access including voice cloning, proactive messages, and no ads.
  @HiveField(2)
  vip,
}

/// Represents the current state of a user's subscription.
///
/// A subscription can be [active] and fully functional, [expired] after its
/// end date, in a [trial] period, [cancelled] by the user but still usable
/// until the billing period ends, or in a [gracePeriod] after a failed
/// payment retry.
@HiveType(typeId: 9)
enum SubscriptionStatus {
  /// Subscription is current and all features are accessible.
  @HiveField(0)
  active,

  /// Subscription has passed its expiry date and features are locked.
  @HiveField(1)
  expired,

  /// User is in a free trial period before being charged.
  @HiveField(2)
  trial,

  /// User cancelled but the subscription remains usable until the period ends.
  @HiveField(3)
  cancelled,

  /// Payment failed; the store is retrying before fully expiring the subscription.
  @HiveField(4)
  gracePeriod,
}

/// Defines a purchasable subscription plan with its pricing, features, and
/// display metadata.
///
/// Plans are the catalog items shown to users. Each plan maps to a
/// [SubscriptionTier] and a billing period. Use the static constants
/// ([SubscriptionPlan.freePlan], [SubscriptionPlan.premiumMonthly], etc.)
/// to access the canonical plan definitions.
///
/// Example:
/// ```dart
/// final plans = SubscriptionPlan.allPlans;
/// for (final plan in plans) {
///   print('${plan.name}: ${plan.price} ${plan.currency}/${plan.periodMonths}mo');
/// }
/// ```
class SubscriptionPlan {
  /// Unique identifier for this plan, typically matching the Google Play
  /// product ID.
  final String id;

  /// The subscription tier this plan belongs to.
  final SubscriptionTier tier;

  /// Human-readable plan name displayed in the UI.
  final String name;

  /// A short description of what the plan offers.
  final String description;

  /// Price in the specified [currency].
  final double price;

  /// ISO 4217 currency code (e.g. "MAD" for Moroccan Dirham).
  final String currency;

  /// Billing period duration in months. Common values are 1 (monthly),
  /// 3 (quarterly), or 12 (yearly).
  final int periodMonths;

  /// List of feature descriptions included in this plan.
  final List<String> features;

  /// Optional badge label shown in the UI (e.g. "Popular", "Best Value").
  /// Null if no badge should be displayed.
  final String? badge;

  /// Percentage savings compared to the monthly equivalent, if applicable.
  /// Null for the free tier and monthly plans where no discount applies.
  final int? savingsPercent;

  /// Creates a [SubscriptionPlan] with the given properties.
  const SubscriptionPlan({
    required this.id,
    required this.tier,
    required this.name,
    required this.description,
    required this.price,
    this.currency = 'MAD',
    required this.periodMonths,
    required this.features,
    this.badge,
    this.savingsPercent,
  });

  // ---------------------------------------------------------------------------
  // Static plan constants
  // ---------------------------------------------------------------------------

  /// Free tier plan — no cost, limited to basic features.
  static const SubscriptionPlan freePlan = SubscriptionPlan(
    id: 'dostok_free',
    tier: SubscriptionTier.free,
    name: 'Free',
    description:
        'Get started with Dostok. Limited AI responses and call minutes, '
        'but unlimited text messages to explore the app.',
    price: 0,
    currency: 'MAD',
    periodMonths: 1,
    features: [
      'Unlimited text messages',
      '20 AI responses per day',
      '0 call minutes',
      'Basic personality only',
    ],
  );

  /// Premium monthly plan — billed every month.
  static const SubscriptionPlan premiumMonthly = SubscriptionPlan(
    id: 'dostok_premium_monthly',
    tier: SubscriptionTier.premium,
    name: 'Premium Monthly',
    description:
        'Unlock unlimited conversations, custom personalities, and deeper '
        'insights into your emotional well-being.',
    price: 49,
    currency: 'MAD',
    periodMonths: 1,
    features: [
      'Unlimited messages & AI responses',
      '30 call minutes per day',
      'Custom personality creation',
      'Priority response speed',
      'Daily emotional check-ins',
      'Mood analytics & trends',
    ],
    badge: 'Popular',
  );

  /// Premium yearly plan — billed annually with savings.
  static const SubscriptionPlan premiumYearly = SubscriptionPlan(
    id: 'dostok_premium_yearly',
    tier: SubscriptionTier.premium,
    name: 'Premium Yearly',
    description:
        'All Premium features at a discounted annual rate. Save compared '
        'to monthly billing.',
    price: 399,
    currency: 'MAD',
    periodMonths: 12,
    features: [
      'Unlimited messages & AI responses',
      '30 call minutes per day',
      'Custom personality creation',
      'Priority response speed',
      'Daily emotional check-ins',
      'Mood analytics & trends',
    ],
    badge: 'Best Value',
    savingsPercent: 32,
  );

  /// VIP monthly plan — billed every month.
  static const SubscriptionPlan vipMonthly = SubscriptionPlan(
    id: 'dostok_vip_monthly',
    tier: SubscriptionTier.vip,
    name: 'VIP Monthly',
    description:
        'The ultimate Dostok experience. Voice cloning, proactive messages, '
        'and everything Premium offers — with no ads ever.',
    price: 99,
    currency: 'MAD',
    periodMonths: 1,
    features: [
      'Everything in Premium',
      '120 call minutes per day',
      'Multiple custom personalities',
      'Voice cloning',
      'Proactive messages from your friend',
      'Export conversation history',
      'No ads — ever',
    ],
  );

  /// VIP yearly plan — billed annually with savings.
  static const SubscriptionPlan vipYearly = SubscriptionPlan(
    id: 'dostok_vip_yearly',
    tier: SubscriptionTier.vip,
    name: 'VIP Yearly',
    description:
        'Full VIP access at the best per-month price. Pay once a year and '
        'enjoy everything without interruptions.',
    price: 799,
    currency: 'MAD',
    periodMonths: 12,
    features: [
      'Everything in Premium',
      '120 call minutes per day',
      'Multiple custom personalities',
      'Voice cloning',
      'Proactive messages from your friend',
      'Export conversation history',
      'No ads — ever',
    ],
    badge: 'Best Value',
    savingsPercent: 33,
  );

  /// All available plans in display order.
  static const List<SubscriptionPlan> allPlans = [
    freePlan,
    premiumMonthly,
    premiumYearly,
    vipMonthly,
    vipYearly,
  ];

  /// Returns only the plans that require payment (price > 0).
  static List<SubscriptionPlan> get paidPlans =>
      allPlans.where((p) => p.price > 0).toList();

  /// Returns a copy of this plan with the given fields replaced.
  SubscriptionPlan copyWith({
    String? id,
    SubscriptionTier? tier,
    String? name,
    String? description,
    double? price,
    String? currency,
    int? periodMonths,
    List<String>? features,
    String? badge,
    int? savingsPercent,
    String? priceString,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      tier: tier ?? this.tier,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      periodMonths: periodMonths ?? this.periodMonths,
      features: features ?? this.features,
      badge: badge ?? this.badge,
      savingsPercent: savingsPercent ?? this.savingsPercent,
    );
  }

  /// Returns the yearly plan for the given [tier], or null if none exists.
  static SubscriptionPlan? yearlyFor(SubscriptionTier tier) {
    try {
      return allPlans.firstWhere(
        (p) => p.tier == tier && p.periodMonths == 12,
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the monthly plan for the given [tier], or null if none exists.
  static SubscriptionPlan? monthlyFor(SubscriptionTier tier) {
    try {
      return allPlans.firstWhere(
        (p) => p.tier == tier && p.periodMonths == 1,
      );
    } catch (_) {
      return null;
    }
  }

  /// Computes the effective monthly price for comparison purposes.
  double get pricePerMonth => periodMonths > 0 ? price / periodMonths : 0;

  @override
  String toString() =>
      'SubscriptionPlan($id, $name, $price $currency/$periodMonths mo)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a user's active subscription state.
///
/// This is the persisted model that tracks which plan the user is on, their
/// current status, and the relevant dates for billing and trial logic.
/// Stored in Hive with [typeId] 10.
///
/// Example:
/// ```dart
/// final sub = Subscription(
///   tier: SubscriptionTier.premium,
///   status: SubscriptionStatus.active,
///   startDate: DateTime.now(),
///   expiryDate: DateTime.now().add(Duration(days: 30)),
///   autoRenew: true,
///   productId: 'dostok_premium_monthly',
/// );
///
/// if (sub.isExpired) {
///   // Prompt user to renew
/// } else if (sub.isInTrial) {
///   // Show trial banner
/// }
/// ```
@HiveType(typeId: 10)
class Subscription {
  /// The subscription tier the user is currently on.
  @HiveField(0)
  final SubscriptionTier tier;

  /// Current lifecycle status of the subscription.
  @HiveField(1)
  final SubscriptionStatus status;

  /// Date when the subscription started or was last renewed.
  @HiveField(2)
  final DateTime startDate;

  /// Date when the current billing period ends.
  ///
  /// After this date, if not renewed, the subscription transitions to
  /// [SubscriptionStatus.expired].
  @HiveField(3)
  final DateTime expiryDate;

  /// End date of the free trial, if the user is or was in a trial.
  ///
  /// Null when the subscription was never in a trial state.
  @HiveField(4)
  final DateTime? trialEndDate;

  /// Whether the subscription is set to automatically renew.
  ///
  /// When false, the subscription will transition to
  /// [SubscriptionStatus.cancelled] at the end of the current period.
  @HiveField(5)
  final bool autoRenew;

  /// Google Play product ID for this subscription.
  ///
  /// Used to verify purchases and manage billing through the Play Store API.
  @HiveField(6)
  final String productId;

  /// Original transaction ID from the first purchase.
  ///
  /// Preserved across renewals to track the subscription lineage.
  @HiveField(7)
  final String? originalTransactionId;

  /// Creates a [Subscription] instance.
  const Subscription({
    required this.tier,
    required this.status,
    required this.startDate,
    required this.expiryDate,
    this.trialEndDate,
    this.autoRenew = true,
    required this.productId,
    this.originalTransactionId,
  });

  /// Default free-tier subscription.
  static final Subscription free = Subscription(
    tier: SubscriptionTier.free,
    status: SubscriptionStatus.active,
    startDate: DateTime(2000),
    expiryDate: DateTime(2099),
    productId: 'dostok_free',
  );

  // ---------------------------------------------------------------------------
  // Computed properties
  // ---------------------------------------------------------------------------

  /// Whether the subscription has passed its [expiryDate].
  ///
  /// Returns true only when the current time is after [expiryDate] AND the
  /// status is [SubscriptionStatus.expired]. A cancelled subscription that
  /// is still within its billing period is not considered expired.
  bool get isExpired =>
      status == SubscriptionStatus.expired ||
      (status != SubscriptionStatus.trial && DateTime.now().isAfter(expiryDate));

  /// Whether the user is currently in a free trial period.
  bool get isInTrial =>
      status == SubscriptionStatus.trial &&
      trialEndDate != null &&
      DateTime.now().isBefore(trialEndDate!);

  /// Number of full days remaining until [expiryDate].
  ///
  /// Returns 0 if the subscription has already expired. For trial
  /// subscriptions, returns the days remaining in the trial if that date
  /// is sooner than [expiryDate].
  int get daysRemaining {
    final now = DateTime.now();
    final effectiveEnd =
        isInTrial && trialEndDate!.isBefore(expiryDate) ? trialEndDate! : expiryDate;
    if (now.isAfter(effectiveEnd)) return 0;
    return effectiveEnd.difference(now).inDays;
  }

  /// Whether the subscription is currently usable (active, in trial, or
  /// cancelled but still within the billing period).
  bool get isUsable =>
      status == SubscriptionStatus.active ||
      status == SubscriptionStatus.trial ||
      (status == SubscriptionStatus.cancelled && !isExpired) ||
      status == SubscriptionStatus.gracePeriod;

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a copy of this subscription with the given fields replaced.
  ///
  /// Unspecified fields retain their current values.
  Subscription copyWith({
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? trialEndDate,
    bool? autoRenew,
    String? productId,
    String? originalTransactionId,
  }) {
    return Subscription(
      tier: tier ?? this.tier,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      autoRenew: autoRenew ?? this.autoRenew,
      productId: productId ?? this.productId,
      originalTransactionId: originalTransactionId ?? this.originalTransactionId,
    );
  }

  @override
  String toString() =>
      'Subscription(tier: $tier, status: $status, expiry: $expiryDate, '
      'autoRenew: $autoRenew)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          tier == other.tier &&
          status == other.status &&
          startDate == other.startDate &&
          expiryDate == other.expiryDate &&
          trialEndDate == other.trialEndDate &&
          autoRenew == other.autoRenew &&
          productId == other.productId &&
          originalTransactionId == other.originalTransactionId;

  @override
  int get hashCode => Object.hash(
        tier,
        status,
        startDate,
        expiryDate,
        trialEndDate,
        autoRenew,
        productId,
        originalTransactionId,
      );
}
