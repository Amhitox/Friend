import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small pill-shaped button for cards and inline actions.
///
/// Displays an optional icon alongside a text label inside a rounded
/// capsule. Supports filled (default) and outlined variants.
///
/// Usage:
/// ```dart
/// PillButton(
///   label: 'Start',
///   icon: Icons.arrow_forward,
///   onTap: () => print('Tapped'),
/// )
/// ```
class PillButton extends StatelessWidget {
  /// The button text label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Callback when the button is tapped.
  final VoidCallback? onTap;

  /// Background color for the filled variant.
  final Color backgroundColor;

  /// Foreground color for icon and text.
  final Color foregroundColor;

  /// Whether to render an outlined button instead of filled.
  final bool isOutlined;

  /// Border radius of the pill.
  final double borderRadius;

  const PillButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.isOutlined = false,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isOutlined ? Colors.transparent : backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isOutlined ? Border.all(color: backgroundColor, width: 1.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: isOutlined ? backgroundColor : foregroundColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isOutlined ? backgroundColor : foregroundColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
