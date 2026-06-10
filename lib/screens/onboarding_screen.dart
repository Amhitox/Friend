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
  bool _nameFieldFocused = false;

  late final AnimationController _orbController;
  late final AnimationController _rotateController;
  late final AnimationController _blinkController;

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

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _nameFocus.addListener(_onFocusChange);
    _startBlinkingLoop();
  }

  void _onFocusChange() {
    setState(() => _nameFieldFocused = _nameFocus.hasFocus);
  }

  void _startBlinkingLoop() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _blinkController.forward();
      if (!mounted) return;
      await _blinkController.reverse();
      if (!mounted) return;
      // Randomize next blink between 3-4.5 seconds
      final next = 3000 + (math.Random().nextDouble() * 1500).toInt();
      Future.delayed(Duration(milliseconds: next), _startBlinkingLoop);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.removeListener(_onFocusChange);
    _nameFocus.dispose();
    _orbController.dispose();
    _rotateController.dispose();
    _blinkController.dispose();
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
          child: Stack(
            children: [
              // Ambient floating particles behind everything
              Positioned.fill(
                child: _buildParticles(),
              ),
              PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildWelcomePage(),
                  _buildNamePage(keyboardInset),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Ambient Particles
  // ─────────────────────────────────────────────
  Widget _buildParticles() {
    return const Stack(
      children: [
        _FloatingParticle(
            initialTop: 0.15, initialLeft: 0.20, size: 5, drift: 1.0),
        _FloatingParticle(
            initialTop: 0.45, initialLeft: 0.75, size: 4, drift: 0.8),
        _FloatingParticle(
            initialTop: 0.70, initialLeft: 0.30, size: 5, drift: 1.2),
        _FloatingParticle(
            initialTop: 0.85, initialLeft: 0.65, size: 4, drift: 0.9),
      ],
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
          const Gap(40),
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
          ),
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
          ),
          const Gap(16),
          // Warm two-line text with heart
          Column(
            children: [
              Text(
                "I'm here for conversations...",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(6),
              Icon(
                Icons.favorite,
                size: 14,
                color: AppColors.primary,
              ),
              const Gap(6),
              Text(
                'late nights, and quiet moments.',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const Gap(20),
          // Page indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
              const Gap(8),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
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
            Icons.arrow_forward_rounded,
            size: 24,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveX(
                begin: 0,
                end: 6,
                duration: 1.2.seconds,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 700.ms);
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
          ),
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
          ),
          const Gap(32),
          _buildNameField(),
          const Gap(20),
          _buildLetsGoButton(),
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
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Friendly Face
  // ─────────────────────────────────────────────
  Widget _buildFace({required double diameter, required double eyeOffsetY}) {
    final eyeSize = diameter * 0.06;
    final pupilSize = eyeSize * 0.4;
    final eyeSpacing = diameter * 0.16;
    final smileWidth = diameter * 0.22;
    final smileHeight = diameter * 0.08;
    final blushSize = diameter * 0.10;

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final blinkScale = 1.0 - (_blinkController.value * 0.9);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Left eye
            Positioned(
              top: diameter * 0.38 + eyeOffsetY,
              left: diameter * 0.5 - eyeSpacing * 0.5 - eyeSize * 0.5,
              child: Transform.scale(
                scaleY: blinkScale,
                child: Container(
                  width: eyeSize,
                  height: eyeSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Left pupil
            Positioned(
              top: diameter * 0.38 + eyeOffsetY + eyeSize * 0.35,
              left: diameter * 0.5 -
                  eyeSpacing * 0.5 -
                  eyeSize * 0.5 +
                  eyeSize * 0.35,
              child: Container(
                width: pupilSize,
                height: pupilSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3D2C7A),
                ),
              ),
            ),
            // Right eye
            Positioned(
              top: diameter * 0.38 + eyeOffsetY,
              left: diameter * 0.5 + eyeSpacing * 0.5 - eyeSize * 0.5,
              child: Transform.scale(
                scaleY: blinkScale,
                child: Container(
                  width: eyeSize,
                  height: eyeSize,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Right pupil
            Positioned(
              top: diameter * 0.38 + eyeOffsetY + eyeSize * 0.35,
              left: diameter * 0.5 +
                  eyeSpacing * 0.5 -
                  eyeSize * 0.5 +
                  eyeSize * 0.35,
              child: Container(
                width: pupilSize,
                height: pupilSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF3D2C7A),
                ),
              ),
            ),
            // Smile
            Positioned(
              top: diameter * 0.52 + eyeOffsetY,
              child: Container(
                width: smileWidth,
                height: smileHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(smileHeight * 0.5),
                    bottomRight: Radius.circular(smileHeight * 0.5),
                  ),
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            // Left blush
            Positioned(
              top: diameter * 0.48 + eyeOffsetY,
              left: diameter * 0.5 - eyeSpacing - blushSize * 0.3,
              child: Container(
                width: blushSize,
                height: blushSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Right blush
            Positioned(
              top: diameter * 0.48 + eyeOffsetY,
              left: diameter * 0.5 + eyeSpacing - blushSize * 0.7,
              child: Container(
                width: blushSize,
                height: blushSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────
  // Orbs
  // ─────────────────────────────────────────────
  Widget _buildLargeOrb() {
    const diameter = 160.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_orbController, _rotateController]),
      builder: (context, child) {
        final breathe =
            1.0 + 0.04 * math.sin(_orbController.value * 2 * math.pi);
        return Transform.scale(
          scale: breathe,
          child: SizedBox(
            width: diameter,
            height: diameter,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Deep radial sphere
                Container(
                  width: diameter,
                  height: diameter,
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
                    width: diameter,
                    height: diameter,
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
                  width: diameter,
                  height: diameter,
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
                // Face
                _buildFace(diameter: diameter, eyeOffsetY: 0),
              ],
            ),
          ),
        );
      },
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
          final breathe =
              1.0 + 0.03 * math.sin(_orbController.value * 2 * math.pi);
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
                // Face with animated eye offset when focused
                TweenAnimationBuilder<double>(
                  tween: Tween(
                    end: _nameFieldFocused ? 2.5 : 0.0,
                  ),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  builder: (context, eyeOffset, child) {
                    return _buildFace(
                      diameter: targetSize,
                      eyeOffsetY: eyeOffset,
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
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
            _nameError ?? '',
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ).animate(target: 1).shake(hz: 4, duration: 350.ms),
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

// ─────────────────────────────────────────────
// Floating Particle
// ─────────────────────────────────────────────
class _FloatingParticle extends StatefulWidget {
  final double initialTop;
  final double initialLeft;
  final double size;
  final double drift;

  const _FloatingParticle({
    required this.initialTop,
    required this.initialLeft,
    required this.size,
    required this.drift,
  });

  @override
  State<_FloatingParticle> createState() => _FloatingParticleState();
}

class _FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final driftX = math.sin(t * 2 * math.pi * widget.drift) * 12;
        final driftY = -t * 40; // float upward slowly
        final fade = 0.06 + 0.02 * math.sin(t * 2 * math.pi);

        return Positioned(
          top: MediaQuery.of(context).size.height * widget.initialTop + driftY,
          left: MediaQuery.of(context).size.width * widget.initialLeft + driftX,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: fade.clamp(0.04, 0.08)),
            ),
          ),
        );
      },
    );
  }
}
