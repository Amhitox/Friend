import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'daily_screen.dart';
import '../widgets/bottom_nav.dart';

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
    _currentIndex = widget.initialIndex == 1 ? 1 : 0;
  }

  void _setTab(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _onNavTap(int navIndex) {
    if (navIndex == 0 || navIndex == 1) {
      _setTab(navIndex);
      return;
    }

    if (navIndex == 2) {
      Navigator.of(context).pushNamed('/new-chat');
      return;
    }

    if (navIndex == 3) {
      Navigator.of(context).pushNamed('/chat');
      return;
    }

    if (navIndex == 4) {
      Navigator.of(context).pushNamed('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          _setTab(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(onDailyTap: () => _setTab(1)),
            const DailyScreen(showBackButton: false),
          ],
        ),
        bottomNavigationBar: DostokBottomNav(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}
