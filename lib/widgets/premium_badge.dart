import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/subscription.dart';
import '../theme/app_colors.dart';

/// A badge widget that visually communicates the user's subscription tier.
///
/// Designed to be placed inline next to feature labels, on cards, or in
/// navigation items. The badge adapts to light/dark themes and supports
/// RTL layouts.
///
/// Usage:
/// ```dart
/// PremiumBadge(tier: SubscriptionTier.premium)
/// PremiumBadge(tier: SubscriptionTier.vip, showLabel: true, size: 24)
/// ```
class PremiumBadge extends StatefulWidget {
  /// The subscription tier to represent.
  final SubscriptionTier tier;

  /// Icon size in logical pixels. The badge scales proportionally.
  final double size;

  /// Whether to show a text label next to the icon.
  final bool showLabel;

  /// Optional override for the label text. Defaults to tier name in Darija.
  final String? labelText;

  const PremiumBadge({
    super.key,
    required this.tier,
    this.size = 18,
    this.showLabel = false,
    this.labelText,
  });

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (widget.tier == SubscriptionTier.vip) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(PremiumBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tier == SubscriptionTier.vip &&
        oldWidget.tier != SubscriptionTier.vip) {
      _shimmerController.repeat();
    } else if (widget.tier != SubscriptionTier.vip &&
        oldWidget.tier == SubscriptionTier.vip) {
      _shimmerController.stop();
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.tier) {
      case SubscriptionTier.free:
        return _buildFreeBadge(context);
      case SubscriptionTier.premium:
        return _buildPremiumBadge(context);
      case SubscriptionTier.vip:
        return _buildVipBadge(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Free tier: small chip
  // ---------------------------------------------------------------------------

  Widget _buildFreeBadge(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!widget.showLabel) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.labelText ?? 'Free',
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Premium tier: gold star
  // ---------------------------------------------------------------------------

  Widget _buildPremiumBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: widget.size,
            color: AppColors.secondary,
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 4),
            Text(
              widget.labelText ?? 'Premium',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIP tier: diamond with shimmer
  // ---------------------------------------------------------------------------

  Widget _buildVipBadge(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _DiamondShimmerPainter(
                  progress: _shimmerController.value,
                  baseColor: const Color(0xFF7C4DFF),
                ),
              );
            },
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 4),
            Text(
              widget.labelText ?? 'VIP',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF7C4DFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Custom painter that draws a diamond shape with a moving shimmer highlight.
class _DiamondShimmerPainter extends CustomPainter {
  final double progress;
  final Color baseColor;

  _DiamondShimmerPainter({
    required this.progress,
    required this.baseColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Diamond path (rotated square)
    final diamondPath = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius, center.dy)
      ..close();

    // Base fill
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(diamondPath, basePaint);

    // Shimmer sweep
    final shimmerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + 2.0 * progress, -1.0),
        end: Alignment(-1.0 + 2.0 * progress + 0.3, 1.0),
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.45),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.srcATop;
    canvas.drawPath(diamondPath, shimmerPaint);
  }

  @override
  bool shouldRepaint(_DiamondShimmerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.baseColor != baseColor;
  }
}
