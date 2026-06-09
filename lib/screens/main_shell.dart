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

  void _onNavTap(int navIndex) {
    if (navIndex == 0 || navIndex == 1) {
      setState(() => _currentIndex = navIndex);
      return;
    }

    if (navIndex == 2 || navIndex == 3) {
      Navigator.of(context).pushNamed('/chat');
      return;
    }

    if (navIndex == 4) {
      Navigator.of(context).pushNamed('/settings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          HomeScreen(),
          DailyScreen(),
        ],
      ),
      bottomNavigationBar: DostokBottomNav(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
