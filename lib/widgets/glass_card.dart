import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A reusable frosted-glass card widget for the Dostok app.
///
/// Wraps [child] in a rounded container with subtle shadow and
/// optional background color. The content is clipped to the border radius.
///
/// Usage:
/// ```dart
/// GlassCard(
///   child: Padding(
///     padding: EdgeInsets.all(16),
///     child: Text('Hello'),
///   ),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// The content to display inside the card.
  final Widget child;

  /// Border radius of the card.
  final double borderRadius;

  /// Padding applied inside the card.
  final EdgeInsets padding;

  /// Shadow effects behind the card.
  final List<BoxShadow> shadows;

  /// Optional background color (defaults to white).
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.shadows = AppColors.cardShadow,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
