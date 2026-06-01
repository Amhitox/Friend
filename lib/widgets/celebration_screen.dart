import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The subscription tier that was just purchased.
enum SubscribedTier { premium, vip }

/// Full-screen overlay shown after a successful subscription purchase.
/// Displays confetti, a congratulations message in Darija, the features
/// the user just unlocked, and auto-dismisses after 5 seconds.
class CelebrationOverlay extends StatefulWidget {
  /// The tier the user just subscribed to.
  final SubscribedTier tier;

  /// Called when the user taps "Start exploring" or when the overlay
  /// auto-dismisses.
  final VoidCallback? onDismiss;

  /// Auto-dismiss delay. Defaults to 5 seconds.
  final Duration autoDismissAfter;

  const CelebrationOverlay({
    super.key,
    required this.tier,
    this.onDismiss,
    this.autoDismissAfter = const Duration(seconds: 5),
  });

  /// Push the overlay as a full-screen transparent route.
  static Future<void> show(
    BuildContext context, {
    required SubscribedTier tier,
    VoidCallback? onDismiss,
    Duration autoDismissAfter = const Duration(seconds: 5),
  }) {
    return Navigator.of(context).push(
      _CelebrationRoute(
        tier: tier,
        onDismiss: onDismiss,
        autoDismissAfter: autoDismissAfter,
      ),
    );
  }

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

// =============================================================================
// Custom route
// =============================================================================

class _CelebrationRoute extends PageRouteBuilder {
  final SubscribedTier tier;
  final VoidCallback? onDismiss;
  final Duration autoDismissAfter;

  _CelebrationRoute({
    required this.tier,
    this.onDismiss,
    required this.autoDismissAfter,
  }) : super(
          opaque: false,
          barrierDismissible: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: CelebrationOverlay(
                tier: tier,
                onDismiss: onDismiss,
                autoDismissAfter: autoDismissAfter,
              ),
            );
          },
        );
}

// =============================================================================
// State
// =============================================================================

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with TickerProviderStateMixin {
  // -- Confetti ---------------------------------------------------------------
  late final AnimationController _confettiController;
  final List<_ConfettiPiece> _confettiPieces = [];
  static const int _confettiCount = 60;

  // -- Checkmark / content ----------------------------------------------------
  late final AnimationController _checkController;
  late final Animation<double> _checkScale;
  late final AnimationController _contentController;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  // -- Auto-dismiss -----------------------------------------------------------
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _generateConfetti();
    _confettiController.forward();

    // Checkmark pop-in
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _checkScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _checkController.forward();
    });

    // Content fade-in
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _contentController.forward();
    });

    // Auto-dismiss
    _autoDismissTimer = Timer(widget.autoDismissAfter, _dismiss);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _checkController.dispose();
    _contentController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _generateConfetti() {
    final rng = Random();
    for (int i = 0; i < _confettiCount; i++) {
      _confettiPieces.add(_ConfettiPiece(
        x: rng.nextDouble(),
        startY: -0.1 - rng.nextDouble() * 0.4,
        endY: 1.1 + rng.nextDouble() * 0.3,
        rotationSpeed: rng.nextDouble() * 4 - 2,
        size: 6 + rng.nextDouble() * 8,
        color: _confettiColors[rng.nextInt(_confettiColors.length)],
        shape: _ConfettiShape.values[rng.nextInt(_ConfettiShape.values.length)],
        delay: rng.nextDouble() * 0.3,
        drift: rng.nextDouble() * 0.3 - 0.15,
      ));
    }
  }

  static const _confettiColors = [
    Color(0xFF6C63FF),
    Color(0xFFE0C3FC),
    Color(0xFF00BFA6),
    Color(0xFFFF6B6B),
    Color(0xFFFFA726),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
  ];

  void _dismiss() {
    _autoDismissTimer?.cancel();
    widget.onDismiss?.call();
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------------------------
  // Data helpers
  // ---------------------------------------------------------------------------

  String get _tierLabel {
    switch (widget.tier) {
      case SubscribedTier.premium:
        return 'Premium';
      case SubscribedTier.vip:
        return 'VIP';
    }
  }

  List<String> get _unlockedFeatures {
    switch (widget.tier) {
      case SubscribedTier.premium:
        return [
          'Messages bla limit 📩',
          'Moqatelat dyal 30 min 📞',
          'Dark mode w themes 🌙',
          'Priority response ⚡',
          'T3alim machi mawjub mn 9bal 🎓',
        ];
      case SubscribedTier.vip:
        return [
          'Kolshi dyal Premium ⭐',
          'Moqatelat bla limit 📞',
          'Voice cloning dyalek 🎙️',
          'Custom personality 🤖',
          'API access 🔧',
          'Support m9addem 💬',
        ];
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Stack(
        children: [
          // Confetti layer
          _ConfettiAnimatedBuilder(
            listenable: _confettiController,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(
                pieces: _confettiPieces,
                progress: _confettiController.value,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 40),

                    // Animated checkmark / party
                    ScaleTransition(
                      scale: _checkScale,
                      child: _buildCheckCircle(),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    FadeTransition(
                      opacity: _contentFade,
                      child: SlideTransition(
                        position: _contentSlide,
                        child: Column(
                          children: [
                            Text(
                              'Mabrouk! 🎉',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFE0C3FC),
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Dostok $_tierLabel m3ak daba!',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Features list
                    FadeTransition(
                      opacity: _contentFade,
                      child: _buildFeaturesList(),
                    ),
                    const SizedBox(height: 40),

                    // CTA button
                    FadeTransition(
                      opacity: _contentFade,
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _dismiss,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Bda t-kashf 🚀',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckCircle() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            widget.tier == SubscribedTier.vip
                ? const Color(0xFFE0C3FC)
                : const Color(0xFF6C63FF),
            widget.tier == SubscribedTier.vip
                ? const Color(0xFF9D4EDD)
                : const Color(0xFF8B83FF),
            widget.tier == SubscribedTier.vip
                ? const Color(0xFFE0C3FC)
                : const Color(0xFF6C63FF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (widget.tier == SubscribedTier.vip
                    ? const Color(0xFFE0C3FC)
                    : const Color(0xFF6C63FF))
                .withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A1A2E),
          ),
          child: Center(
            child: Text(
              widget.tier == SubscribedTier.vip ? '💎' : '⭐',
              style: const TextStyle(fontSize: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chno khassek daba:',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(_unlockedFeatures.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BFA6).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFF00BFA6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _unlockedFeatures[i],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// =============================================================================
// Confetti primitives
// =============================================================================

enum _ConfettiShape { square, circle, ribbon }

class _ConfettiPiece {
  final double x;
  final double startY;
  final double endY;
  final double rotationSpeed;
  final double size;
  final Color color;
  final _ConfettiShape shape;
  final double delay;
  final double drift;

  const _ConfettiPiece({
    required this.x,
    required this.startY,
    required this.endY,
    required this.rotationSpeed,
    required this.size,
    required this.color,
    required this.shape,
    required this.delay,
    required this.drift,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiPiece> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
      if (t <= 0) continue;

      final y = p.startY + (p.endY - p.startY) * Curves.easeIn.transform(t);
      final x = p.x + p.drift * sin(t * pi * 2);
      final rotation = p.rotationSpeed * t * pi * 2;
      final opacity = t < 0.85 ? 1.0 : ((1.0 - t) / 0.15).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      final center = Offset(x * size.width, y * size.height);

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);

      switch (p.shape) {
        case _ConfettiShape.square:
          canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size),
            paint,
          );
          break;
        case _ConfettiShape.circle:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case _ConfettiShape.ribbon:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 2.2,
              height: p.size * 0.5,
            ),
            paint,
          );
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// =============================================================================
// AnimatedBuilder helper (avoids importing a package)
// =============================================================================

class _ConfettiAnimatedBuilder extends AnimatedWidget {
  final TransitionBuilder builder;
  final Widget? child;

  const _ConfettiAnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
    this.child,
  });

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
