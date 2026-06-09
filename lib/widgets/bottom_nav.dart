import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A custom bottom navigation bar for the Dostok app.
///
/// Features a white container with rounded top corners, four standard
/// navigation items, and a floating circular center button.
///
/// Usage:
/// ```dart
/// DostokBottomNav(
///   currentIndex: 0,
///   onTap: (index) => setState(() => _currentIndex = index),
/// )
/// ```
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
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ?? Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
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
                _buildItem(Icons.home_outlined, 'Home', 0),
                _buildItem(Icons.calendar_today_outlined, 'Daily', 1),
                const SizedBox(width: 56), // Space for center FAB
                _buildItem(Icons.chat_bubble_outline, 'Chat', 3),
                _buildItem(Icons.settings_outlined, 'Settings', 4),
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
              onTap: () => onTap(2),
              child: Container(
                width: 56,
                height: 56,
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
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: () => onTap(index),
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
    );
  }
}
