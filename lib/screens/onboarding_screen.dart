import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../services/subscription_service.dart';
import 'trial_screen.dart';

/// Multi-page onboarding flow for the Dostok app.
///
/// Walks the user through a warm, Darija-flavored introduction and collects
/// their name on the final page. After completion, shows the TrialScreen
/// before navigating to `/home`.
///
/// Monetization integration:
/// - After final page: shows TrialScreen before home
/// - Tracks onboarding completion with analytics
/// - If user skips trial: sets as free tier, stores skip date for 3-day nudge
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();
  int _currentPage = 0;
  bool _isSaving = false;
  String? _nameError;

  /// Timestamp when onboarding started, for analytics.
  late final DateTime _onboardingStartTime;

  static const _totalPages = 4;

  // Brand colors
  static const _teal = Color(0xFF00897B);
  static const _tealDark = Color(0xFF00695C);
  static const _tealLight = Color(0xFFB2DFDB);
  static const _amber = Color(0xFFFFB300);
  static const _warmBg = Color(0xFFF5F5F0);

  @override
  void initState() {
    super.initState();
    _onboardingStartTime = DateTime.now();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _skipToLast() async {
    // Track skip analytics.
    AnalyticsService().logOnboardingSkipped(stepSkippedAt: _currentPage);

    await _pageController.animateToPage(
      _totalPages - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'دخل سميتك، عافاك');
      _nameFocus.requestFocus();
      return;
    }
    setState(() {
      _nameError = null;
      _isSaving = true;
    });

    // Save the user profile
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initializeUser(name);

    // Mark onboarding as seen so we don't repeat it
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    // Track onboarding completion analytics.
    final durationSeconds =
        DateTime.now().difference(_onboardingStartTime).inSeconds;
    AnalyticsService().logOnboardingCompleted(
      durationSeconds: durationSeconds,
      stepsCompleted: _totalPages,
    );

    if (!mounted) return;

    // Show TrialScreen before navigating to home.
    final trialStarted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const TrialScreen()),
    );

    if (!mounted) return;

    // If the user skipped the trial, store the skip date for a 3-day nudge.
    if (trialStarted != true) {
      await prefs.setString(
        'trialSkippedDate',
        DateTime.now().toIso8601String(),
      );
      await prefs.setBool('showUpgradeNudge', true);
    }

    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _warmBg,
      body: SafeArea(
        child: Column(
          children: [
            // ---- Top bar: Skip button (hidden on last page) ----
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: AnimatedOpacity(
                  opacity: _currentPage < _totalPages - 1 ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: TextButton(
                    onPressed:
                        _currentPage < _totalPages - 1 ? _skipToLast : null,
                    child: Text(
                      'تخطّى',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _teal,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ---- Page content ----
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                children: [
                  _buildWelcomePage(),
                  _buildLanguagePage(),
                  _buildFriendPage(),
                  _buildSetupPage(),
                ],
              ),
            ),

            // ---- Page indicators ----
            _buildPageIndicators(),
            const Gap(12),

            // ---- Bottom button ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: _currentPage < _totalPages - 1
                    ? _buildNextButton()
                    : _buildDoneButton(),
              ),
            ),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page 1 -- Welcome
  // ---------------------------------------------------------------------------

  Widget _buildWelcomePage() {
    return _OnboardingPageWrapper(
      children: [
        // Illustration placeholder -- friendly chat bubble cluster
        _buildIllustration(
          icons: [
            Icons.waving_hand_rounded,
            Icons.chat_bubble_rounded,
            Icons.favorite_rounded,
          ],
          colors: const [
            Color(0xFFFFB300),
            Color(0xFF00897B),
            Color(0xFFEF5350),
          ],
        ),
        const Gap(40),
        Text(
          'مرحبا! أنا دوستك',
          style: GoogleFonts.cairo(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _tealDark,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 600.ms),
        const Gap(12),
        Text(
          'Ana Dostok, صاحبك الجديد!',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _teal,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 400.ms, duration: 600.ms),
        const Gap(20),
        Text(
          'غادي نكون معاك فكل يوم، نهضرو ونتسناو معاك',
          style: GoogleFonts.cairo(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 600.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Page 2 -- Language
  // ---------------------------------------------------------------------------

  Widget _buildLanguagePage() {
    return _OnboardingPageWrapper(
      children: [
        _buildIllustration(
          icons: [
            Icons.translate_rounded,
            Icons.record_voice_over_rounded,
            Icons.language_rounded,
          ],
          colors: const [
            Color(0xFF00897B),
            Color(0xFF26A69A),
            Color(0xFF4DB6AC),
          ],
        ),
        const Gap(40),
        Text(
          'Kanhdro b Darija',
          style: GoogleFonts.cairo(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _tealDark,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 600.ms),
        const Gap(16),
        Text(
          'كنهضرو بالدارجة المغربية، كيف كتهضر مع صحابك',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 400.ms, duration: 600.ms),
        const Gap(28),
        _buildFeatureChip(Icons.chat_rounded, 'دارجة طبيعية')
            .animate()
            .fadeIn(delay: 500.ms, duration: 500.ms)
            .slideX(begin: -0.15, end: 0, delay: 500.ms, duration: 500.ms),
        const Gap(10),
        _buildFeatureChip(Icons.emoji_emotions_rounded, 'Expressions b Darija')
            .animate()
            .fadeIn(delay: 650.ms, duration: 500.ms)
            .slideX(begin: -0.15, end: 0, delay: 650.ms, duration: 500.ms),
        const Gap(10),
        _buildFeatureChip(Icons.auto_awesome_rounded, 'Kayfham l\'context dyalek')
            .animate()
            .fadeIn(delay: 800.ms, duration: 500.ms)
            .slideX(begin: -0.15, end: 0, delay: 800.ms, duration: 500.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Page 3 -- Friendship / assistant
  // ---------------------------------------------------------------------------

  Widget _buildFriendPage() {
    return _OnboardingPageWrapper(
      children: [
        _buildIllustration(
          icons: [
            Icons.people_rounded,
            Icons.psychology_rounded,
            Icons.lightbulb_rounded,
          ],
          colors: const [
            Color(0xFFFFB300),
            Color(0xFF00897B),
            Color(0xFF42A5F5),
          ],
        ),
        const Gap(40),
        Text(
          'Sadiqek',
          style: GoogleFonts.cairo(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _tealDark,
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 600.ms),
        const Gap(8),
        Text(
          'صاحبك، ماشي مجرد تطبيق',
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _teal,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 600.ms),
        const Gap(24),
        _buildFeatureTile(
          icon: Icons.headset_mic_rounded,
          title: 'Kallem m3ak',
          subtitle: ' talk و كالم معايا بصوتك',
          delay: 500,
        ),
        const Gap(14),
        _buildFeatureTile(
          icon: Icons.celebration_rounded,
          title: 'Ferhek m3ak',
          subtitle: 'كنفرحك و نعاونك نهارك يدوز مزيان',
          delay: 650,
        ),
        const Gap(14),
        _buildFeatureTile(
          icon: Icons.school_rounded,
          title: '3llemek',
          subtitle: 'كنعلمك حوايج جداد كل نهار',
          delay: 800,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Page 4 -- Setup (name input)
  // ---------------------------------------------------------------------------

  Widget _buildSetupPage() {
    return _OnboardingPageWrapper(
      children: [
        // Decorative circle avatar
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_tealLight, _teal],
            ),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 44,
            color: Colors.white,
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms)
            .scale(
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.0, 1.0),
              duration: 700.ms,
              curve: Curves.elasticOut,
            ),
        const Gap(32),
        Text(
          'خلّينا نبداو!',
          style: GoogleFonts.cairo(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: _tealDark,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 600.ms)
            .slideY(begin: 0.2, end: 0, delay: 200.ms, duration: 600.ms),
        const Gap(8),
        Text(
          'شنو سميتك؟',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: _teal,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 350.ms, duration: 600.ms),
        const Gap(32),
        // Name input field
        _buildNameField(),
        if (_nameError != null) ...[
          const Gap(8),
          Text(
            _nameError!,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: Colors.red.shade600,
              fontWeight: FontWeight.w600,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .shake(hz: 4, duration: 400.ms),
        ],
        const Gap(20),
        Text(
          'هادشي غادي يعاونّي نعرفك مزيان',
          style: GoogleFonts.cairo(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        )
            .animate()
            .fadeIn(delay: 600.ms, duration: 500.ms),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Reusable widgets
  // ---------------------------------------------------------------------------

  Widget _buildIllustration({
    required List<IconData> icons,
    required List<Color> colors,
  }) {
    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(icons.length, (i) {
          final offset = (i - 1).toDouble();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Transform.translate(
              offset: Offset(0, offset.abs() * 12),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colors[i].withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(icons[i], size: 34, color: colors[i]),
              )
                  .animate()
                  .fadeIn(
                    delay: Duration(milliseconds: 100 * i),
                    duration: 500.ms,
                  )
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    delay: Duration(milliseconds: 100 * i),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: _teal.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: _teal),
          const Gap(10),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _tealDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required int delay,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _teal, size: 26),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _tealDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 500.ms,
        )
        .slideX(
          begin: -0.12,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildNameField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _nameError != null
              ? Colors.red.shade400
              : _nameFocus.hasFocus
                  ? _teal
                  : Colors.grey.shade300,
          width: _nameFocus.hasFocus ? 2.0 : 1.5,
        ),
        boxShadow: [
          if (_nameFocus.hasFocus)
            BoxShadow(
              color: _teal.withOpacity(0.15),
              blurRadius: 16,
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
        style: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _tealDark,
        ),
        decoration: InputDecoration(
          hintText: '...',
          hintStyle: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade300,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          prefixIcon: Icon(
            Icons.edit_rounded,
            color: _teal.withOpacity(0.5),
            size: 22,
          ),
        ),
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
      ),
    )
        .animate()
        .fadeIn(delay: 450.ms, duration: 600.ms)
        .slideY(begin: 0.15, end: 0, delay: 450.ms, duration: 600.ms);
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? _teal : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextPage,
      style: ElevatedButton.styleFrom(
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 3,
        shadowColor: _teal.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'التالي',
            style: GoogleFonts.cairo(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(8),
          const Icon(Icons.arrow_forward_rounded, size: 22),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildDoneButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _completeOnboarding,
      style: ElevatedButton.styleFrom(
        backgroundColor: _amber,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        elevation: 4,
        shadowColor: _amber.withOpacity(0.4),
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
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'يلاه نبداو!',
                  style: GoogleFonts.cairo(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const Gap(8),
                const Icon(Icons.rocket_launch_rounded, size: 22),
              ],
            ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Wraps each onboarding page with consistent padding and centering.
class _OnboardingPageWrapper extends StatelessWidget {
  const _OnboardingPageWrapper({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap(16),
          ...children,
          const Gap(16),
        ],
      ),
    );
  }
}
