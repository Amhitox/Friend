import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A custom bottom navigation bar for the Dostok app.
///
/// Features a themed container with rounded top corners, four standard
/// navigation items, and a floating circular center button.
class DostokBottomNav extends StatelessWidget {
  /// The currently selected index (0-4).
  final int currentIndex;

  /// Called when any nav item (including the center FAB) is tapped.
  final ValueChanged<int> onTap;

  const DostokBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.surfaceFor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.isDark(context)
                    ? Colors.black.withValues(alpha: 0.45)
                    : AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
                spreadRadius: -4,
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildItem(context, Icons.home_outlined, 'Home', 0),
                _buildItem(context, Icons.calendar_today_outlined, 'Daily', 1),
                const SizedBox(width: 56), // Space for center FAB
                _buildItem(context, Icons.chat_bubble_outline, 'Chat', 3),
                _buildItem(context, Icons.settings_outlined, 'Settings', 4),
              ],
            ),
          ),
        ),
        Positioned(
          top: -28,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(2),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = currentIndex == index;
    final color =
        isSelected ? AppColors.primary : AppColors.textSecondaryFor(context);

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 64,
        height: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
