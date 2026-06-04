import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'glass_card.dart';
import 'pill_button.dart';

/// A quick-action card for the home screen grid.
///
/// Displays a white card with an icon container, title, subtitle,
/// and a pill-shaped button at the bottom. Uses [GlassCard] internally.
///
/// Usage:
/// ```dart
/// ActionCard(
///   icon: Icons.chat_bubble_outline,
///   title: 'Chat',
///   subtitle: 'Start a new conversation',
///   buttonLabel: 'Start',
///   onTap: () {
///     // Handle tap
///   },
/// )
/// ```
class ActionCard extends StatelessWidget {
  /// The icon to display in the header.
  final IconData icon;

  /// The card title.
  final String title;

  /// The card subtitle.
  final String subtitle;

  /// The label for the bottom pill button.
  final String buttonLabel;

  /// Callback when the pill button is tapped.
  final VoidCallback? onTap;

  /// Whether the button is primary (filled) or secondary (outlined).
  final bool isPrimary;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    this.onTap,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(
            label: buttonLabel,
            icon: Icons.arrow_forward,
            onTap: onTap,
            isOutlined: !isPrimary,
          ),
        ],
      ),
    );
  }
}
