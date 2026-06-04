import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A selectable topic chip for filtering or onboarding.
///
/// Renders a pill-shaped chip that toggles between a selected
/// (purple background + white text) and unselected
/// (light purple background + purple text) state.
///
/// Usage:
/// ```dart
/// TopicChip(
///   label: 'Daily',
///   isSelected: true,
///   onTap: () => setState(() => selected = !selected),
/// )
/// ```
class TopicChip extends StatelessWidget {
  /// The label text displayed inside the chip.
  final String label;

  /// Whether the chip is currently selected.
  final bool isSelected;

  /// Callback when the chip is tapped.
  final VoidCallback? onTap;

  const TopicChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
