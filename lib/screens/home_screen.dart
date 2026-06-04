import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_colors.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const _HomeBody(),
      bottomNavigationBar: DostokBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 2 || index == 3) {
            Navigator.pushNamed(context, '/chat');
          }
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // ── Greeting ──
            Text(
              _greeting(),
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "I'm here whenever you need me.",
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            const Spacer(),

            // ── Orb ──
            Center(
              child: Container(
                width: 160,
                height: 160,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.dreamyBg,
                ),
                child: Center(
                  child: Text(
                    'D',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 64,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary.withOpacity(0.9),
                    ),
                  ),
                ),
              )
                  .animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1.0, 1.0),
                    end: const Offset(1.05, 1.05),
                    duration: 2400.ms,
                    curve: Curves.easeInOut,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.05, 1.05),
                    end: const Offset(1.0, 1.0),
                    duration: 2400.ms,
                    curve: Curves.easeInOut,
                  ),
            ),

            const SizedBox(height: 48),

            // ── Primary Action ──
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Chat with Dostok',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Secondary Action ──
            Center(
              child: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/call'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.call_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Voice Call',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(flex: 2),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
