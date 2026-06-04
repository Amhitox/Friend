import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../models/subscription.dart';
import '../services/subscription_service.dart';
import '../theme/app_colors.dart';

/// Trial offer screen shown after onboarding for first-time users.
///
/// Presents a 7-day free Premium trial with a clear list of included features,
/// social proof, and two clear paths: start the trial or continue with Free.
/// The screen is always skippable -- it never blocks the user from proceeding.
///
/// Returns `true` via Navigator.pop if the user started a trial,
/// `false` if they chose to continue with Free.
///
/// Usage:
/// ```dart
/// final startedTrial = await Navigator.push<bool>(
///   context,
///   MaterialPageRoute(builder: (_) => const TrialScreen()),
/// );
/// ```
class TrialScreen extends StatefulWidget {
  const TrialScreen({super.key});

  @override
  State<TrialScreen> createState() => _TrialScreenState();
}

class _TrialScreenState extends State<TrialScreen> {
  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  bool _isStarting = false;

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const _goldLight = Color(0xFFFFD54F);
  static const _goldDark = Color(0xFFC77DFF);
  static const _warmBg = Color(0xFFF7F5FF);

  /// Features included in the Premium trial, with icon + Darija label.
  static const _trialFeatures = <({IconData icon, String label, String desc})>[
    (
      icon: Icons.chat_bubble_rounded,
      label: 'Rassayil bla hd',
      desc: 'Hadser m3a Dostok bla ma t7ssb',
    ),
    (
      icon: Icons.call_rounded,
      label: '30 dq dial mkimat/nhar',
      desc: 'Kallem m3a Dostok f telefon',
    ),
    (
      icon: Icons.psychology_rounded,
      label: 'Chakhsiya khassek',
      desc: 'Khl9 Dostok b chakhsiya li3jbek',
    ),
    (
      icon: Icons.mood_rounded,
      label: 'Tahlil mood',
      desc: '3raf kifach mood dyalek tbdel',
    ),
    (
      icon: Icons.speed_rounded,
      label: 'Jawab bsir3a',
      desc: 'Dostok kayjewbek b tor9a',
    ),
    (
      icon: Icons.notifications_active_rounded,
      label: 'Check-in nihari',
      desc: 'Dostok kaytsalak kol nhar',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Trial logic
  // ---------------------------------------------------------------------------

  Future<void> _startTrial() async {
    if (_isStarting) return;

    setState(() => _isStarting = true);

    final subService = context.read<SubscriptionService>();
    final success = await subService.startTrial(SubscriptionTier.premium);

    if (!mounted) return;

    setState(() => _isStarting = false);

    if (success) {
      _showTrialStartedSheet();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            subService.error ?? 'Maqdrnach nbdaw l-trial. Jrb m3a l-mra jaya.',
            style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _continueFree() {
    Navigator.of(context).pop(false);
  }

  void _showTrialStartedSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(28, 40, 28, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti-style icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_goldLight, _goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _goldDark.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.celebration_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
              const Gap(24),
              Text(
                'Bda l-trial!',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 400.ms),
              const Gap(10),
              Text(
                '7 jours Premium bla ma tsrf f centime.\nKol features fta7o lik daba!',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 350.ms, duration: 400.ms),
              const Gap(28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldDark,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: _goldDark.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Bda tst3ml Premium!',
                    style: TextStyle(fontFamily: 'Cairo', 
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms)
                  .slideY(begin: 0.1, end: 0, delay: 500.ms, duration: 400.ms),
              const Gap(12),
              Text(
                'Ghadi ntsakkr lik 3la had l-3ard mlli l-trial ytssali.',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : _warmBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip
            _buildTopBar(context, isDark),
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const Gap(8),
                    _buildHeroSection(context, isDark),
                    const Gap(32),
                    _buildFeatureList(context, isDark),
                    const Gap(28),
                    _buildNoCreditCardNote(context, isDark),
                    const Gap(20),
                    _buildSocialProof(context, isDark),
                    const Gap(16),
                  ],
                ),
              ),
            ),
            // Sticky bottom buttons
            _buildBottomButtons(context, isDark),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top bar
  // ---------------------------------------------------------------------------

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              size: 22,
            ),
            onPressed: _continueFree,
          ),
          const Spacer(),
          // Skip button
          TextButton(
            onPressed: _continueFree,
            child: Text(
              'Kml b Free',
              style: TextStyle(fontFamily: 'Cairo', 
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hero section
  // ---------------------------------------------------------------------------

  Widget _buildHeroSection(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Animated avatar with premium glow
        _buildTrialAvatar()
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              duration: 700.ms,
              curve: Curves.elasticOut,
            ),
        const Gap(28),
        // Welcome text
        Text(
          'Ahlan bik f Dostok!',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.15, end: 0, delay: 200.ms, duration: 500.ms),
        const Gap(10),
        // Trial offer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_goldLight, _goldDark],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _goldDark.withOpacity(0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded, size: 20, color: Colors.white),
              const Gap(8),
              Text(
                'Jrreb Premium mokan 7 jours!',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 500.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.0, 1.0),
              delay: 400.ms,
              duration: 400.ms,
              curve: Curves.easeOutBack,
            ),
        const Gap(14),
        Text(
          'Kol features li f Premium mftohin lik mokan 7 jours. Bda daba!',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 550.ms, duration: 500.ms),
      ],
    );
  }

  Widget _buildTrialAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_goldLight, _goldDark, Color(0xFF9D4EDD)],
        ),
        boxShadow: [
          BoxShadow(
            color: _goldDark.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.9),
              AppColors.primaryDark,
            ],
          ),
        ),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 44,
          color: Colors.white,
        ),
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          delay: 600.ms,
          duration: 2000.ms,
          color: Colors.white.withOpacity(0.3),
        );
  }

  // ---------------------------------------------------------------------------
  // Feature list
  // ---------------------------------------------------------------------------

  Widget _buildFeatureList(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chno ghadi t9der dir:',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 650.ms, duration: 400.ms),
        const Gap(16),
        ...List.generate(_trialFeatures.length, (i) {
          final feature = _trialFeatures[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildFeatureItem(
              context,
              isDark: isDark,
              icon: feature.icon,
              label: feature.label,
              desc: feature.desc,
              delay: 700 + (i * 100),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String label,
    required String desc,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _goldDark.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: _goldDark),
          ),
          const Gap(14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const Gap(2),
                Text(
                  desc,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Checkmark
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.success,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
        )
        .slideX(
          begin: 0.1,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 400.ms,
          curve: Curves.easeOutCubic,
        );
  }

  // ---------------------------------------------------------------------------
  // No credit card note
  // ---------------------------------------------------------------------------

  Widget _buildNoCreditCardNote(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.credit_card_off_rounded,
            size: 22,
            color: AppColors.success,
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'La carte bancaire machi nécessaire',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const Gap(2),
                Text(
                  'Bda l-trial daba w lghi f ay w9t bla ma t5ls walu.',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1350.ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, delay: 1350.ms, duration: 400.ms);
  }

  // ---------------------------------------------------------------------------
  // Social proof / FOMO
  // ---------------------------------------------------------------------------

  Widget _buildSocialProof(BuildContext context, bool isDark) {
    return Column(
      children: [
        // FOMO text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _goldDark.withOpacity(isDark ? 0.1 : 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: _goldDark),
              const Gap(8),
              Flexible(
                child: Text(
                  'Akthar mn 70% mn users khtar Premium mba3d ma jarraw l-trial',
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 1450.ms, duration: 400.ms),
        const Gap(12),
        // Stars
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.star_rounded,
                size: 20,
                color: _goldDark,
              ),
            ),
          ),
        ),
        const Gap(4),
        Text(
          '4.8/5 - 10,000+ users',
          style: TextStyle(fontFamily: 'Cairo', 
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        )
            .animate()
            .fadeIn(delay: 1500.ms, duration: 400.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom buttons
  // ---------------------------------------------------------------------------

  Widget _buildBottomButtons(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary: Start Trial
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _TrialPulseButton(
              isStarting: _isStarting,
              onPressed: _startTrial,
            ),
          ),
          const Gap(10),
          // Secondary: Continue with Free
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: _continueFree,
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Kml b Free - Ma bghitsh trial',
                style: TextStyle(fontFamily: 'Cairo', 
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ),
          ),
          // Reassurance
          Text(
            'Lghi ay w9t. La iltizam.',
            style: TextStyle(fontFamily: 'Cairo', 
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.7)
                  : AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1550.ms, duration: 400.ms)
        .slideY(begin: 0.12, end: 0, delay: 1550.ms, duration: 400.ms);
  }
}

// =============================================================================
// Trial pulse button
// =============================================================================

/// The primary CTA button with a pulsing glow animation.
class _TrialPulseButton extends StatefulWidget {
  final bool isStarting;
  final VoidCallback onPressed;

  const _TrialPulseButton({
    required this.isStarting,
    required this.onPressed,
  });

  @override
  State<_TrialPulseButton> createState() => _TrialPulseButtonState();
}

class _TrialPulseButtonState extends State<_TrialPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.5).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: widget.isStarting
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFFC77DFF).withOpacity(_glowAnimation.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isStarting ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC77DFF),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: const Color(0xFFC77DFF).withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: widget.isStarting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, size: 22),
                  const Gap(8),
                  Text(
                    'Bda l-trial mokan 7 jours - Gratuit',
                    style: TextStyle(fontFamily: 'Cairo', 
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
