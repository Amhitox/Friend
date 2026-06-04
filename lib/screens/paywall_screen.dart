import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';

import '../models/subscription.dart';
import '../services/billing_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';

/// Main paywall / upgrade screen for the Dostok app.
///
/// Shows plan comparison (Premium vs VIP), a feature comparison table,
/// social proof, and persuasive CTA buttons. Supports monthly/yearly toggle
/// and handles the full purchase flow with loading, success, and error states.
///
/// Navigation arguments (optional):
/// - `highlightFeature` (String): feature ID to scroll to and highlight.
///
/// Usage:
/// ```dart
/// Navigator.pushNamed(context, '/paywall');
/// Navigator.pushNamed(context, '/paywall', arguments: {'highlightFeature': 'voice_calls'});
/// ```
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// Whether the yearly plan is shown (true) or monthly (false).
  bool _isYearly = true;

  /// Currently selected plan tier.
  SubscriptionTier _selectedTier = SubscriptionTier.premium;

  /// Whether a purchase flow is in progress.
  bool _isPurchasing = false;

  /// Whether purchase succeeded (for celebration state).
  bool _purchaseSuccess = false;

  /// Current error message, if any.
  String? _errorMessage;

  /// Stream subscription for billing status updates.
  StreamSubscription<PurchaseStatus>? _billingSub;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const _goldLight = Color(0xFFFFD54F);
  static const _goldDark = Color(0xFFC77DFF);
  static const _purpleLight = Color(0xFFB388FF);
  static const _purpleDark = Color(0xFF7C4DFF);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _listenToBilling();
  }

  @override
  void dispose() {
    _billingSub?.cancel();
    super.dispose();
  }

  void _listenToBilling() {
    final billing = BillingService.instance;
    _billingSub = billing.purchaseStream.listen(_onPurchaseStatus);
  }

  void _onPurchaseStatus(PurchaseStatus status) {
    if (!mounted) return;

    switch (status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        setState(() {
          _isPurchasing = false;
          _purchaseSuccess = true;
          _errorMessage = null;
        });
        _showSuccessCelebration();
        break;

      case PurchaseStatus.pending:
        setState(() {
          _isPurchasing = true;
          _errorMessage = null;
        });
        break;

      case PurchaseStatus.error:
        setState(() {
          _isPurchasing = false;
          _errorMessage = 'L-machkil f l-paiement. Jrb m3a l-mra jaya.';
        });
        break;

      case PurchaseStatus.canceled:
        setState(() {
          _isPurchasing = false;
          _errorMessage = null;
        });
        break;

      default:
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Purchase logic
  // ---------------------------------------------------------------------------

  SubscriptionPlan get _selectedPlan {
    final plans = SubscriptionPlan.paidPlans;
    final tier = _selectedTier;
    final period = _isYearly ? 12 : 1;

    try {
      return plans.firstWhere(
        (p) => p.tier == tier && p.periodMonths == period,
      );
    } catch (_) {
      return plans.firstWhere((p) => p.tier == tier);
    }
  }

  Future<void> _handlePurchase() async {
    if (_isPurchasing || _purchaseSuccess) return;

    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    final subService = context.read<SubscriptionService>();
    final plan = _selectedPlan;

    final success = await subService.purchasePlan(plan);

    if (!success && mounted) {
      setState(() {
        _isPurchasing = false;
        _errorMessage = subService.error ??
            'Maqdrnach nbdaw l-paiement. Jrb m3a l-mra jaya.';
      });
    }
  }

  Future<void> _handleRestore() async {
    setState(() {
      _isPurchasing = true;
      _errorMessage = null;
    });

    final subService = context.read<SubscriptionService>();
    await subService.restorePurchases();

    if (mounted) {
      setState(() => _isPurchasing = false);

      if (subService.isPremium) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rja3na l-abonnement dyalek!',
              style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  void _showSuccessCelebration() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(context, isDark),
      body: _purchaseSuccess
          ? _buildSuccessState(context)
          : _buildMainContent(context, isDark),
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isDark) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.close_rounded,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, color: _goldDark, size: 24),
          const Gap(6),
          Text(
            'Dostok Premium',
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _goldDark,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  // ---------------------------------------------------------------------------
  // Main content (scrollable)
  // ---------------------------------------------------------------------------

  Widget _buildMainContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Gap(8),
                _buildHeaderSection(context, isDark),
                const Gap(28),
                _buildPlanToggle(context, isDark),
                const Gap(16),
                _buildPlanCards(context, isDark),
                const Gap(28),
                _buildFeatureTable(context, isDark),
                const Gap(28),
                _buildSocialProof(context, isDark),
                const Gap(12),
                if (_errorMessage != null) ...[
                  _buildErrorBanner(context),
                  const Gap(12),
                ],
                const Gap(8),
              ],
            ),
          ),
        ),
        // Sticky bottom CTA
        _buildBottomCta(context, isDark),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Header: animated avatar + tagline
  // ---------------------------------------------------------------------------

  Widget _buildHeaderSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Premium glow avatar
        _buildPremiumAvatar()
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.7, 0.7),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
        const Gap(20),
        // Tagline
        Text(
          'Khlli Dostok ykoun s7abek l-7a9i9i!',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            height: 1.3,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 500.ms),
        const Gap(10),
        Text(
          'Ftah kol features w tla3 m3a Dostok l-level li jaya!',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildPremiumAvatar() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldLight, _goldDark, Color(0xFF9D4EDD)],
        ),
        boxShadow: [
          BoxShadow(
            color: _goldDark.withOpacity(0.4),
            blurRadius: 24,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: _purpleDark.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primaryDark,
            ],
          ),
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 48,
          color: Colors.white,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 800.ms,
          duration: 1800.ms,
          color: Colors.white.withOpacity(0.3),
        );
  }

  // ---------------------------------------------------------------------------
  // Monthly / Yearly toggle
  // ---------------------------------------------------------------------------

  Widget _buildPlanToggle(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.06)
            : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleOption(
              context,
              label: 'Chhar',
              isSelected: !_isYearly,
              isDark: isDark,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              context,
              label: '3am',
              isSelected: _isYearly,
              isDark: isDark,
              badge: 'Wfr 32%',
              onTap: () => setState(() => _isYearly = true),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms);
  }

  Widget _buildToggleOption(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ),
            ),
            if (badge != null) ...[
              const Gap(6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Plan cards
  // ---------------------------------------------------------------------------

  Widget _buildPlanCards(BuildContext context, bool isDark) {
    final premiumPlan = _isYearly
        ? SubscriptionPlan.premiumYearly
        : SubscriptionPlan.premiumMonthly;
    final vipPlan = _isYearly
        ? SubscriptionPlan.vipYearly
        : SubscriptionPlan.vipMonthly;

    return Row(
      children: [
        Expanded(
          child: _buildPlanCard(
            context,
            isDark: isDark,
            plan: premiumPlan,
            isSelected: _selectedTier == SubscriptionTier.premium,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_goldLight, _goldDark],
            ),
            badgeLabel: 'Popular',
            badgeColor: _goldDark,
            delay: 0,
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildPlanCard(
            context,
            isDark: isDark,
            plan: vipPlan,
            isSelected: _selectedTier == SubscriptionTier.vip,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_purpleLight, _purpleDark],
            ),
            badgeLabel: 'Best Value',
            badgeColor: _purpleDark,
            delay: 100,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required bool isDark,
    required SubscriptionPlan plan,
    required bool isSelected,
    required LinearGradient gradient,
    required String badgeLabel,
    required Color badgeColor,
    required int delay,
  }) {
    final monthlyPrice = plan.pricePerMonth.toStringAsFixed(0);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTier = plan.tier;
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(isSelected ? 1.0 : 0.97),
        transformAlignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected ? gradient : null,
            color: isSelected
                ? null
                : (isDark ? AppColors.surfaceDark : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (isDark ? AppColors.dividerDark : AppColors.divider),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.25)
                            : badgeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(fontFamily: 'Cairo', 
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : badgeColor,
                        ),
                      ),
                    ),
                    const Gap(12),
                    // Tier name
                    Text(
                      plan.tier == SubscriptionTier.premium ? 'Premium' : 'VIP',
                      style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                    ),
                    const Gap(8),
                    // Price
                    Text(
                      '$monthlyPrice MAD',
                      style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                      ),
                    ),
                    Text(
                      _isYearly
                          ? '/ chhar (m3a l-3am)'
                          : '/ chhar',
                      style: TextStyle(fontFamily: 'Cairo', 
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withOpacity(0.8)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary),
                      ),
                    ),
                    if (_isYearly) ...[
                      const Gap(4),
                      Text(
                        '${plan.price} MAD/3am',
                        style: TextStyle(fontFamily: 'Cairo', 
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white.withOpacity(0.7)
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                          decoration: TextDecoration.lineThrough,
                          decorationColor: isSelected
                              ? Colors.white.withOpacity(0.7)
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary),
                        ),
                      ),
                    ],
                    const Gap(14),
                    // Features
                    ...plan.features.take(4).map(
                          (f) => _buildPlanFeature(
                            f,
                            isSelected: isSelected,
                            isDark: isDark,
                          ),
                        ),
                  ],
                ),
              ),
              // Selection checkmark
              Positioned(
                top: 12,
                right: 12,
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: badgeColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 600 + delay),
          duration: 500.ms,
        )
        .slideY(
          begin: 0.12,
          end: 0,
          delay: Duration(milliseconds: 600 + delay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildPlanFeature(
    String feature, {
    required bool isSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: isSelected
                ? Colors.white.withOpacity(0.9)
                : AppColors.success,
          ),
          const Gap(8),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Feature comparison table
  // ---------------------------------------------------------------------------

  Widget _buildFeatureTable(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '9arn m3a Free',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 900.ms, duration: 400.ms),
        const Gap(14),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              _buildTableHeader(isDark),
              const Divider(height: 1, thickness: 0.5),
              // Feature rows
              _featureRow('Rassayil bla hd', free: false, premium: true, vip: true, isDark: isDark),
              _featureRow('20 jawab AI/nhar', free: true, premium: false, vip: false, isDark: isDark, freeLabel: '20/nhar'),
              _featureRow('Mkimat Sout', free: false, premium: '30min/nhar', vip: '120min/nhar', isDark: isDark),
              _featureRow('Chakhsiya khassek', free: false, premium: true, vip: true, isDark: isDark),
              _featureRow('Tahlil mood', free: false, premium: true, vip: true, isDark: isDark),
              _featureRow('Jawab bsir3a', free: false, premium: true, vip: true, isDark: isDark),
              _featureRow('Nskhal sotek', free: false, premium: false, vip: true, isDark: isDark),
              _featureRow('Rassayil mn Dostok', free: false, premium: false, vip: true, isDark: isDark),
              _featureRow('Bla i3lanat', free: false, premium: false, vip: true, isDark: isDark),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 1000.ms, duration: 500.ms)
            .slideY(begin: 0.08, end: 0, delay: 1000.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Feature',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Free',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, size: 14, color: _goldDark),
                const Gap(3),
                Text(
                  'Premium',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _goldDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.diamond_rounded, size: 14, color: _purpleDark),
                const Gap(3),
                Text(
                  'VIP',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _purpleDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(
    String name, {
    required dynamic free,
    required dynamic premium,
    required dynamic vip,
    required bool isDark,
    String? freeLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (isDark ? AppColors.dividerDark : AppColors.divider).withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              name,
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(child: _buildCell(free, isDark: isDark, label: freeLabel)),
          Expanded(child: _buildCell(premium, isDark: isDark, highlight: true)),
          Expanded(child: _buildCell(vip, isDark: isDark, highlight: true)),
        ],
      ),
    );
  }

  Widget _buildCell(dynamic value, {required bool isDark, bool highlight = false, String? label}) {
    if (value is bool) {
      return Center(
        child: Icon(
          value ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 18,
          color: value
              ? AppColors.success
              : (isDark ? Colors.white24 : Colors.black12),
        ),
      );
    }
    if (value is String) {
      return Center(
        child: Text(
          value,
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: highlight
                ? AppColors.success
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ---------------------------------------------------------------------------
  // Social proof
  // ---------------------------------------------------------------------------

  Widget _buildSocialProof(BuildContext context, bool isDark) {
    return Column(
      children: [
        // User count
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_rounded, size: 20, color: _goldDark),
            const Gap(8),
            Text(
              '10,000+ Moroccan users trust Dostok Premium',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 1200.ms, duration: 400.ms),
        const Gap(12),
        // Star rating
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.star_rounded,
                size: 22,
                color: _goldDark,
              ),
            ),
          ),
        ),
        const Gap(4),
        Text(
          '4.8/5 (2,300+ rating)',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        )
            .animate()
            .fadeIn(delay: 1300.ms, duration: 400.ms),
        const Gap(16),
        // Testimonials
        _buildTestimonial(
          context,
          isDark: isDark,
          quote:
              '""Dostok Premium bdlt bih. Daba kangol liya ga3 l-hwayj li knbgha w kangolo f Darija!""',
          author: 'Amina, Casa',
          delay: 1400,
        ),
        const Gap(10),
        _buildTestimonial(
          context,
          isDark: isDark,
          quote:
              '""L-mkimat Sout kan3rafha m3a s7abi. Dostok kayt3allem mni!""',
          author: 'Youssef, Rabat',
          delay: 1500,
        ),
      ],
    );
  }

  Widget _buildTestimonial(
    BuildContext context, {
    required bool isDark,
    required String quote,
    required String author,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.04)
            : _goldDark.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _goldDark.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quote,
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Icon(Icons.person_rounded, size: 14, color: _goldDark),
              const Gap(6),
              Text(
                author,
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _goldDark,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        );
  }

  // ---------------------------------------------------------------------------
  // Error banner
  // ---------------------------------------------------------------------------

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 20, color: AppColors.error),
          const Gap(10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shake(hz: 4, duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // Bottom CTA
  // ---------------------------------------------------------------------------

  Widget _buildBottomCta(BuildContext context, bool isDark) {
    final subService = context.watch<SubscriptionService>();
    final canTrial = subService.canStartTrial(SubscriptionTier.premium);
    final plan = _selectedPlan;
    final priceLabel = _isYearly
        ? '${plan.price} MAD/3am'
        : '${plan.price} MAD/chhar';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _buildPrimaryCta(canTrial, priceLabel),
          ),
          const Gap(10),
          // Restore purchases
          TextButton(
            onPressed: _isPurchasing ? null : _handleRestore,
            child: Text(
              'Rja3 l-achra',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          ),
          // Reassurance + links
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Lghi ay w9t. La iltizam.',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: navigate to terms
                },
                child: Text(
                  'Shurut',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: navigate to privacy
                },
                child: Text(
                  'Khssousiya',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1600.ms, duration: 400.ms)
        .slideY(begin: 0.15, end: 0, delay: 1600.ms, duration: 400.ms);
  }

  Widget _buildPrimaryCta(bool canTrial, String priceLabel) {
    return _PulsingCtaButton(
      isPurchasing: _isPurchasing,
      onPressed: _handlePurchase,
      child: canTrial
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill_rounded, size: 22),
                const Gap(8),
                Text(
                  'Jrreb 7 jours gratuitement',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.workspace_premium_rounded, size: 20),
                const Gap(8),
                Text(
                  'Subscribe daba - $priceLabel',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Success celebration
  // ---------------------------------------------------------------------------

  Widget _buildSuccessState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_goldLight, _goldDark],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _goldDark.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 60,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.elasticOut,
                ),
            const Gap(32),
            Text(
              'Mabrouk!',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: _goldDark,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0, delay: 300.ms, duration: 500.ms),
            const Gap(12),
            Text(
              'Dostok Premium mcha m3ak!\nKol features fta7o lik.',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 500.ms),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Bda tst3ml Premium!',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0, delay: 700.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Pulsing CTA button widget
// =============================================================================

/// An elevated button with a gentle scale pulse animation to draw attention.
class _PulsingCtaButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isPurchasing;

  const _PulsingCtaButton({
    required this.child,
    required this.onPressed,
    required this.isPurchasing,
  });

  @override
  State<_PulsingCtaButton> createState() => _PulsingCtaButtonState();
}

class _PulsingCtaButtonState extends State<_PulsingCtaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.03), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.03, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPurchasing ? 1.0 : _scaleAnimation.value,
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isPurchasing ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textOnSecondary,
          elevation: 6,
          shadowColor: AppColors.secondary.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: widget.isPurchasing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : widget.child,
      ),
    );
  }
}
