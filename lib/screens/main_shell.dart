import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'daily_screen.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import '../widgets/bottom_nav.dart';

/// Root shell for the four main tabs.
///
/// Uses an [IndexedStack] so each tab maintains its state when switched away.
/// The bottom navigation is always visible and reflects the active tab.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  /// Maps bottom-nav indices (0-4) to the four tab screens in [IndexedStack].
  int _mapNavIndexToTab(int navIndex) {
    switch (navIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Daily
      case 2:
      case 3:
        return 2; // Chat (center FAB or Chat icon)
      case 4:
        return 3; // Settings
      default:
        return 0;
    }
  }

  /// Reverse-maps a tab index to the bottom-nav index for active indication.
  int _mapTabToNavIndex(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 0; // Home
      case 1:
        return 1; // Daily
      case 2:
        return 3; // Chat -> show Chat icon as active
      case 3:
        return 4; // Settings
      default:
        return 0;
    }
  }

  void _onNavTap(int navIndex) {
    final tabIndex = _mapNavIndexToTab(navIndex);
    setState(() => _currentIndex = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          DailyScreen(),
          ChatScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: DostokBottomNav(
        currentIndex: _mapTabToNavIndex(_currentIndex),
        onTap: _onNavTap,
      ),
    );
  }
}
