import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../services/feature_gate.dart';
import '../theme/app_colors.dart';

/// Wraps any widget and conditionally locks it behind a feature gate.
///
/// When the feature is available the child renders normally. When locked
/// the child is shown with a blur overlay and a lock icon; tapping opens
/// the upgrade prompt. An optional teaser mode shows the child without
/// blur but disables interaction.
///
/// Usage:
/// ```dart
/// FeatureLock(
///   feature: FeatureGate.voiceCalls,
///   tier: currentTier,
///   child: CallButton(onPressed: () { ... }),
/// )
///
/// FeatureLock(
///   feature: FeatureGate.moodAnalytics,
///   tier: currentTier,
///   teaser: true,
///   child: MoodChart(data: moodData),
/// )
/// ```
class FeatureLock extends StatefulWidget {
  /// The feature identifier from [FeatureGate] constants.
  final String feature;

  /// The user's current subscription tier.
  final SubscriptionTier tier;

  /// The widget to wrap.
  final Widget child;

  /// If true, the child is visible but non-interactive (no blur overlay).
  /// Defaults to false (blur + lock icon).
  final bool teaser;

  /// Whether the lock overlay is disabled (e.g. during free trial).
  /// When true, the child is always shown normally.
  final bool forceUnlocked;

  /// Optional callback invoked when the user taps the locked overlay.
  /// If null, defaults to [FeatureGate.showUpgradePrompt].
  final VoidCallback? onLockedTap;

  /// Optional tooltip text shown on long-press of the lock icon.
  /// Defaults to a Darija message.
  final String? tooltip;

  const FeatureLock({
    super.key,
    required this.feature,
    required this.tier,
    required this.child,
    this.teaser = false,
    this.forceUnlocked = false,
    this.onLockedTap,
    this.tooltip,
  });

  @override
  State<FeatureLock> createState() => _FeatureLockState();
}

class _FeatureLockState extends State<FeatureLock>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  bool _wasLocked = false;

  bool get _isLocked =>
      !widget.forceUnlocked &&
      _tierIndex(widget.tier) < _tierIndex(FeatureGate.getFeatureTier(widget.feature));

  @override
  void initState() {
    super.initState();
    _wasLocked = _isLocked;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: _wasLocked ? 1.0 : 0.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(FeatureLock oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nowLocked = _isLocked;
    if (nowLocked != _wasLocked) {
      _wasLocked = nowLocked;
      if (nowLocked) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = _isLocked;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: Directionality.of(context),
      child: Stack(
        children: [
          // Child widget -- always rendered for smooth transition
          AnimatedOpacity(
            opacity: locked && !widget.teaser ? 0.3 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: locked,
              child: widget.child,
            ),
          ),

          // Lock overlay (not shown in teaser mode)
          if (locked && !widget.teaser)
            Positioned.fill(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: GestureDetector(
                      onTap: _handleLockedTap,
                      child: Container(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(0.35),
                        child: Center(
                          child: _buildLockIcon(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Teaser: lock icon in the corner
          if (locked && widget.teaser)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: _handleLockedTap,
                child: _buildMiniLock(context),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lock icon (full overlay)
  // ---------------------------------------------------------------------------

  Widget _buildLockIcon(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tier = FeatureGate.getFeatureTier(widget.feature);
    final isVip = tier == SubscriptionTier.vip;
    final color = isVip ? const Color(0xFF7C4DFF) : AppColors.secondary;

    return Tooltip(
      message: widget.tooltip ?? 'Hadi Premium. Chri bach tfta7ha!',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVip ? Icons.diamond_outlined : Icons.lock_outline,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isVip ? 'VIP' : 'Premium',
              style: theme.textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap bach tfta7',
            style: theme.textTheme.labelSmall?.copyWith(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mini lock (teaser mode)
  // ---------------------------------------------------------------------------

  Widget _buildMiniLock(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tier = FeatureGate.getFeatureTier(widget.feature);
    final isVip = tier == SubscriptionTier.vip;
    final color = isVip ? const Color(0xFF7C4DFF) : AppColors.secondary;

    return Tooltip(
      message: widget.tooltip ?? 'Hadi Premium. Chri bach tfta7ha!',
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: (isDark ? Colors.black : Colors.white).withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          isVip ? Icons.diamond_outlined : Icons.lock_outline,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Tap handler
  // ---------------------------------------------------------------------------

  void _handleLockedTap() {
    if (widget.onLockedTap != null) {
      widget.onLockedTap!();
    } else {
      FeatureGate.showUpgradePrompt(context, widget.feature);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
}
