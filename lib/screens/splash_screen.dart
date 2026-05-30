import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';

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

    // Subtle breathing pulse for the logo circle
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    // Let the splash breathe for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Determine destination: onboarding (first launch) or home
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    if (!mounted) return;

    final destination =
        (hasSeenOnboarding && userProvider.isInitialized) ? '/home' : '/onboarding';

    Navigator.of(context).pushReplacementNamed(destination);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00695C), // deep teal
              Color(0xFF00897B), // teal
              Color(0xFF26A69A), // lighter teal
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // ---- Animated logo circle ----
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
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFB2DFDB),
                        Color(0xFF4DB6AC),
                        Color(0xFF00897B),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00695C).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'د',
                      style: GoogleFonts.cairo(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.4, 0.4),
                      end: const Offset(1.0, 1.0),
                      duration: 900.ms,
                      curve: Curves.elasticOut,
                    ),
              ),

              const SizedBox(height: 32),

              // ---- App name ----
              Text(
                'Dostok',
                style: GoogleFonts.cairo(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.15),
                      offset: const Offset(0, 3),
                      blurRadius: 8,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 700.ms)
                  .slideY(
                    begin: 0.3,
                    end: 0.0,
                    delay: 400.ms,
                    duration: 700.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const SizedBox(height: 10),

              // ---- Subtitle ----
              Text(
                'صديقك اللي كيهضر معاك بالدارجة',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.85),
                ),
                textDirection: TextDirection.rtl,
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms)
                  .slideY(
                    begin: 0.4,
                    end: 0.0,
                    delay: 700.ms,
                    duration: 600.ms,
                    curve: Curves.easeOutCubic,
                  ),

              const Spacer(flex: 3),

              // ---- Loading dots ----
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  )
                      .animate(
                        onComplete: (controller) => controller.repeat(reverse: true),
                      )
                      .fadeIn(
                        delay: Duration(milliseconds: 1000 + i * 150),
                        duration: 400.ms,
                      )
                      .scale(
                        begin: const Offset(0.6, 0.6),
                        end: const Offset(1.2, 1.2),
                        delay: Duration(milliseconds: 1100 + i * 150),
                        duration: 600.ms,
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
