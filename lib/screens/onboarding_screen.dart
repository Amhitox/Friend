import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';

/// A warm, single-screen onboarding for Dostok.
///
/// No feature carousel. No bullet points. Just a quiet, dreamy
/// introduction and a single question: "What should I call you?"
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  bool _isSaving = false;
  String? _nameError;
  bool _hasFocused = false;

  late final AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus && !_hasFocused) {
        setState(() => _hasFocused = true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    _orbController.dispose();
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
      stepsCompleted: 1,
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.dreamyBg,
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Gap(40),
                  _buildOrb(),
                  const Gap(48),
                  const Text(
                    "Hi, I'm Dostok",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 800.ms)
                      .slideY(begin: 0.25, end: 0, delay: 300.ms, duration: 800.ms, curve: Curves.easeOutCubic),
                  const Gap(8),
                  const Text(
                    'Your AI companion.',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 700.ms)
                      .slideY(begin: 0.15, end: 0, delay: 500.ms, duration: 700.ms, curve: Curves.easeOutCubic),
                  const Gap(56),
                  _buildNameField()
                      .animate()
                      .fadeIn(delay: 800.ms, duration: 700.ms)
                      .slideY(begin: 0.2, end: 0, delay: 800.ms, duration: 700.ms, curve: Curves.easeOutCubic),
                  if (_nameError != null) ...[
                    const Gap(10),
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
                  const Gap(28),
                  _buildLetsGoButton()
                      .animate()
                      .fadeIn(delay: 1000.ms, duration: 600.ms)
                      .slideY(begin: 0.15, end: 0, delay: 1000.ms, duration: 600.ms, curve: Curves.easeOutCubic),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrb() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        final breathe = 1.0 + 0.04 * math.sin(_orbController.value * 2 * math.pi);
        return Transform.scale(
          scale: breathe,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.orbGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                  blurRadius: 60,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'D',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
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

  Widget _buildNameField() {
    final isFocused = _nameFocus.hasFocus;
    final borderColor = _nameError != null
        ? AppColors.error
        : isFocused
            ? AppColors.primary
            : Colors.transparent;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor,
          width: isFocused ? 2 : 1.5,
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
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
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'What should I call you?',
          hintStyle: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 18,
          ),
        ),
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
      ),
    );
  }

  Widget _buildLetsGoButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _completeOnboarding,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: _isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Let's go",
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Gap(8),
                  Icon(Icons.arrow_forward_rounded, size: 22),
                ],
              ),
      ),
    );
  }
}

