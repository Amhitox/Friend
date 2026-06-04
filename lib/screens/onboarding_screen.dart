import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';

/// A warm, two-page onboarding that feels like meeting a friend.
///
/// Page 1 — quiet introduction. Page 2 — a single gentle question.
/// No feature carousel. No bullet points. Just warmth, intention, and presence.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  bool _isSaving = false;
  String? _nameError;

  late final AnimationController _orbController;
  late final AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _orbController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name');
      _nameFocus.requestFocus();
      return;
    }

    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initializeUser(name);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    AnalyticsService().logOnboardingCompleted(
      durationSeconds: 0,
      stepsCompleted: 2,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.dreamyBg,
        ),
        child: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildWelcomePage(),
              _buildNamePage(keyboardInset),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Page 1 — The Welcome
  // ─────────────────────────────────────────────
  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          _buildLargeOrb(),
          const Gap(48),
          Text(
            'Hi there',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 900.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 200.ms,
                  duration: 900.ms,
                  curve: Curves.easeOutCubic),
          const Gap(6),
          Text(
            "I'm Dostok",
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 900.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 600.ms,
                  duration: 900.ms,
                  curve: Curves.easeOutCubic),
          const Gap(12),
          Text(
            'Your companion for conversations, late nights, and quiet moments.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 900.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 900.ms,
                  duration: 900.ms,
                  curve: Curves.easeOutCubic),
          const Spacer(),
          _buildContinueCue(),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildContinueCue() {
    return GestureDetector(
      onTap: () => _goToPage(1),
      child: Column(
        children: [
          Text(
            'Continue',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const Gap(4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 24,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: 6, duration: 1.2.seconds, curve: Curves.easeInOut),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1400.ms, duration: 700.ms);
  }

  // ─────────────────────────────────────────────
  // Page 2 — Getting to Know You
  // ─────────────────────────────────────────────
  Widget _buildNamePage(double keyboardInset) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.only(
        left: 36,
        right: 36,
        top: keyboardInset > 0 ? 24 : 64,
        bottom: 24,
      ),
      child: Column(
        children: [
          _buildSmallOrb(keyboardInset),
          const Gap(40),
          Text(
            'What should I call you?',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 100.ms, duration: 700.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 100.ms,
                  duration: 700.ms,
                  curve: Curves.easeOutCubic),
          const Gap(8),
          Text(
            'You can use a nickname or your real name.',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 700.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 300.ms,
                  duration: 700.ms,
                  curve: Curves.easeOutCubic),
          const Gap(32),
          _buildNameField()
              .animate()
              .fadeIn(delay: 500.ms, duration: 700.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.2,
                  end: 0,
                  delay: 500.ms,
                  duration: 700.ms,
                  curve: Curves.easeOutCubic),
          const Gap(20),
          _buildLetsGoButton()
              .animate()
              .fadeIn(delay: 700.ms, duration: 600.ms, curve: Curves.easeOut)
              .slideY(
                  begin: 0.15,
                  end: 0,
                  delay: 700.ms,
                  duration: 600.ms,
                  curve: Curves.easeOutCubic),
          const Spacer(),
          Text(
            'This is just between us 💜',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 900.ms, duration: 600.ms),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Orbs
  // ─────────────────────────────────────────────
  Widget _buildLargeOrb() {
    return AnimatedBuilder(
      animation: Listenable.merge([_orbController, _rotateController]),
      builder: (context, child) {
        final breathe = 1.0 + 0.04 * math.sin(_orbController.value * 2 * math.pi);
        return Transform.scale(
          scale: breathe,
          child: SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Deep radial sphere
                Container(
                  width: 160,
                  height: 160,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.25, -0.35),
                      radius: 0.9,
                      colors: [
                        Color(0xFFE0D4FF),
                        Color(0xFFC4B5FD),
                        Color(0xFFA78BFA),
                        Color(0xFF8B5CF6),
                        Color(0xFF7C3AED),
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
                // Rotating sweep gradient for life
                Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.0),
                          AppColors.secondary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                // Specular highlight (glassiness)
                Positioned(
                  top: 28,
                  left: 36,
                  child: Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.55),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                // Soft inner glow shadow
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        blurRadius: 60,
                        spreadRadius: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 900.ms)
        .scale(
          begin: const Offset(0.7, 0.7),
          end: const Offset(1.0, 1.0),
          duration: 900.ms,
          curve: Curves.easeOutBack,
        );
  }

  Widget _buildSmallOrb(double keyboardInset) {
    final targetSize = keyboardInset > 0 ? 72.0 : 100.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      width: targetSize,
      height: targetSize,
      child: AnimatedBuilder(
        animation: Listenable.merge([_orbController, _rotateController]),
        builder: (context, child) {
          final breathe = 1.0 + 0.03 * math.sin(_orbController.value * 2 * math.pi);
          return Transform.scale(
            scale: breathe,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: targetSize,
                  height: targetSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment(-0.25, -0.35),
                      radius: 0.9,
                      colors: [
                        Color(0xFFE0D4FF),
                        Color(0xFFC4B5FD),
                        Color(0xFFA78BFA),
                        Color(0xFF8B5CF6),
                        Color(0xFF7C3AED),
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotateController.value * 2 * math.pi,
                  child: Container(
                    width: targetSize,
                    height: targetSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.0),
                          AppColors.secondary.withValues(alpha: 0.35),
                          AppColors.primary.withValues(alpha: 0.15),
                          AppColors.secondary.withValues(alpha: 0.0),
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: targetSize * 0.18,
                  left: targetSize * 0.22,
                  child: Container(
                    width: targetSize * 0.28,
                    height: targetSize * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(targetSize * 0.09),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.5),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: targetSize,
                  height: targetSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    )
        .animate()
        .fadeIn(duration: 700.ms);
  }

  // ─────────────────────────────────────────────
  // Name field
  // ─────────────────────────────────────────────
  Widget _buildNameField() {
    final isFocused = _nameFocus.hasFocus;
    final borderColor = _nameError != null
        ? AppColors.error
        : isFocused
            ? AppColors.primary
            : Colors.transparent;

    Widget field = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            )
          else
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocus,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _completeOnboarding(),
        style: const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Alex, Sam, Your name...',
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
      ),
    );

    if (_nameError != null) {
      field = field
          .animate(target: 1)
          .shake(hz: 4, duration: 350.ms, curve: Curves.easeInOut);
    }

    return Column(
      children: [
        field,
        if (_nameError != null) ...[
          const Gap(8),
          Text(
            _nameError!,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .shake(hz: 4, duration: 350.ms),
        ],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Let's go button
  // ─────────────────────────────────────────────
  Widget _buildLetsGoButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text(
                "Let's go",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
