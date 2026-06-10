import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 0.98, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final results = await Future.wait<Object?>([
      Future.delayed(const Duration(milliseconds: 1700)).then((_) => null),
      SharedPreferences.getInstance(),
      userProvider.loadUser().then((_) => null),
    ]);

    if (!mounted) return;

    final prefs = results[1] as SharedPreferences;
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final destination = (hasSeenOnboarding && userProvider.isInitialized)
        ? '/home'
        : '/onboarding';

    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimaryFor(context);
    final textSecondary = AppColors.textSecondaryFor(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundFor(context),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.dreamyBgFor(context),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _pulseScale,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseScale.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.orbGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'D',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 360.ms,
                      curve: Curves.easeOutBack,
                    ),
              ),
              const SizedBox(height: 32),
              Text(
                'Dostok',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 120.ms, duration: 260.ms).slideY(
                    begin: 0.3,
                    end: 0.0,
                    delay: 120.ms,
                    duration: 260.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const SizedBox(height: 10),
              Text(
                'Your AI companion, always here.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ).animate().fadeIn(delay: 220.ms, duration: 240.ms).slideY(
                    begin: 0.4,
                    end: 0.0,
                    delay: 220.ms,
                    duration: 240.ms,
                    curve: Curves.easeOutCubic,
                  ),
              const Spacer(flex: 3),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.45),
                    ),
                  )
                      .animate(
                        onComplete: (controller) =>
                            controller.repeat(reverse: true),
                      )
                      .fadeIn(
                        delay: Duration(milliseconds: 260 + i * 80),
                        duration: 180.ms,
                      )
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.2, 1.2),
                        delay: Duration(milliseconds: 300 + i * 80),
                        duration: 220.ms,
                        curve: Curves.easeInOut,
                      );
                }),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
