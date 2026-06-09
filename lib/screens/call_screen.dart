import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/call_provider.dart';
import '../services/analytics_service.dart';
import '../theme/app_colors.dart';

// =============================================================================
// CallScreen — Premium full-screen voice call interface for Dostok
// =============================================================================

/// A full-screen voice call UI consumed by [CallProvider].
///
/// Features a holographic 3D living orb, minimal bottom controls,
/// and clean premium typography. All text is in English.
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------

  /// Drives the fade-in of the ended summary.
  late final AnimationController _summaryFadeController;

  /// Whether microphone permission was granted.
  bool _micPermissionGranted = false;

  /// Error message if permission was denied.
  String? _permissionError;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _summaryFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _initCall();
  }

  Future<void> _initCall() async {
    final granted = await _requestMicPermission();
    if (!mounted) return;

    setState(() {
      _micPermissionGranted = granted;
      if (!granted) {
        _permissionError = 'Microphone permission is required for voice calls.';
      }
    });

    if (granted) {
      // Track call start with analytics.
      AnalyticsService().logCallStarted(callType: 'voice');

      // Kick off the call — transitions connecting -> active via the provider.
      context.read<CallProvider>().startCall();
    }
  }

  /// Requests microphone access via the `permission_handler` package.
  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  @override
  void dispose() {
    _summaryFadeController.dispose();

    // If the call is still active/connecting when the user navigates away,
    // end it gracefully so stats are persisted.
    final provider = context.read<CallProvider>();
    if (provider.isInCall) {
      _recordCallUsage(provider);
      provider.endCall();
    }

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------

  /// Records call usage in analytics.
  void _recordCallUsage(CallProvider callProvider) {
    final duration = callProvider.callDuration;
    if (duration.inSeconds > 0) {
      AnalyticsService().logCallEnded(
        durationSeconds: duration.inSeconds,
        callType: 'voice',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer<CallProvider>(
      builder: (context, call, _) {
        // Trigger summary fade-in when the call ends.
        if (call.currentState == CallState.ended &&
            _summaryFadeController.status == AnimationStatus.dismissed) {
          _summaryFadeController.forward();
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context, call),
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.dreamyBg,
            ),
            child: SafeArea(
              child: _buildBody(context, call),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // AppBar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(BuildContext context, CallProvider call) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: 64,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Back arrow
                IconButton(
                  onPressed: () {
                    if (call.isInCall) {
                      _recordCallUsage(call);
                      call.endCall();
                    }
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                  splashRadius: 24,
                ),
                const Spacer(),
                // Title
                const Text(
                  'Voice Chat',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // Menu icon
                IconButton(
                  onPressed: () {
                    // Placeholder for future call settings / menu
                  },
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                  splashRadius: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Delegates to the correct sub-layout based on [CallProvider.currentState].
  Widget _buildBody(BuildContext context, CallProvider call) {
    // Permission denied — show an error state instead of the call UI.
    if (!_micPermissionGranted) {
      return _buildPermissionDenied();
    }

    switch (call.currentState) {
      case CallState.idle:
      case CallState.connecting:
        return _buildConnecting(context, call);
      case CallState.active:
        return _buildActive(context, call);
      case CallState.ended:
        return _buildEnded(context, call);
    }
  }

  // ---------------------------------------------------------------------------
  // Permission denied state
  // ---------------------------------------------------------------------------

  Widget _buildPermissionDenied() {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mic_off_rounded,
                size: 64,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 24),
              Text(
                _permissionError ?? 'Permission required.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 18,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => openAppSettings(),
                icon: const Icon(Icons.settings, color: Colors.white),
                label: const Text(
                  'Open Settings',
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connecting / Idle state
  // ---------------------------------------------------------------------------

  Widget _buildConnecting(BuildContext context, CallProvider call) {
    return Container(
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const _LivingOrb(size: 260, isActive: false),
          const SizedBox(height: 40),
          const Text(
            'Calling...',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w300,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(flex: 3),
          _CircleControlButton(
            icon: Icons.close,
            size: 72,
            iconColor: Colors.white,
            backgroundColor: AppColors.error,
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 6),
              ),
            ],
            onPressed: () {
              _recordCallUsage(call);
              call.endCall();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Active state
  // ---------------------------------------------------------------------------

  Widget _buildActive(BuildContext context, CallProvider call) {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            const _LivingOrb(size: 260, isActive: true),
            const SizedBox(height: 40),
            Text(
              call.isMuted ? 'Muted' : 'On a call',
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.w300,
                color: AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            if (!call.isMuted)
              const _AnimatedDots(
                baseText: 'Connected',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
            const SizedBox(height: 16),
            _buildTranscriptionArea(call),
            const SizedBox(height: 8),
            Text(
              call.formattedDuration,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 3,
              ),
            ),
            const Spacer(flex: 3),
            _buildBottomControls(context, call),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionArea(CallProvider call) {
    // TODO: wire real STT transcript when available
    const String transcript = '';
    final bool hasText = transcript.isNotEmpty;

    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        hasText ? transcript : 'Say something...',
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Cairo',
          fontSize: 16,
          fontWeight: hasText ? FontWeight.w500 : FontWeight.w400,
          fontStyle: hasText ? FontStyle.normal : FontStyle.italic,
          color: hasText ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context, CallProvider call) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mute & Speaker row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleControlButton(
              icon: call.isMuted ? Icons.mic_off : Icons.mic,
              size: 52,
              iconColor: call.isMuted ? AppColors.error : AppColors.primary,
              backgroundColor: Colors.white,
              boxShadow: AppColors.cardShadow,
              onPressed: () => call.toggleMute(),
            ),
            const SizedBox(width: 24),
            _CircleControlButton(
              icon: call.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              size: 52,
              iconColor:
                  call.isSpeakerOn ? AppColors.primary : AppColors.textSecondary,
              backgroundColor: Colors.white,
              boxShadow: AppColors.cardShadow,
              onPressed: () => call.toggleSpeaker(),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // End call — prominent red
        _CircleControlButton(
          icon: Icons.call_end,
          size: 72,
          iconColor: Colors.white,
          backgroundColor: AppColors.error,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 4,
              offset: const Offset(0, 6),
            ),
          ],
          onPressed: () {
            _recordCallUsage(call);
            call.endCall();
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Ended state — summary
  // ---------------------------------------------------------------------------

  Widget _buildEnded(BuildContext context, CallProvider call) {
    return FadeTransition(
      opacity: _summaryFadeController,
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Orb (static, smaller)
              const _LivingOrb(
                size: 200,
                isActive: false,
              ),
              const SizedBox(height: 24),
              const Text(
                'Call Ended',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Duration summary card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFCCFBF1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Duration: ${call.formattedDuration}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Error message if call ended due to an error
              if (call.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  call.error ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: AppColors.error,
                  ),
                ),
              ],
              const Spacer(flex: 2),
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Call again
                  _CircleIconLabelButton(
                    icon: Icons.call_rounded,
                    label: 'Call Again',
                    backgroundColor: AppColors.primary,
                    onPressed: () {
                      _summaryFadeController.reset();
                      call.resetCall();
                      call.startCall();
                    },
                  ),
                  const SizedBox(width: 40),
                  // Go back
                  _CircleIconLabelButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'Back',
                    backgroundColor: const Color(0xFFCCFBF1),
                    iconColor: AppColors.textPrimary,
                    onPressed: () {
                      call.resetCall();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _LivingOrb — True 3D living glass sphere with 7 distinct layers
// =============================================================================

class _LivingOrb extends StatefulWidget {
  final double size;
  final bool isActive;

  const _LivingOrb({
    required this.size,
    required this.isActive,
  });

  @override
  State<_LivingOrb> createState() => _LivingOrbState();
}

class _LivingOrbState extends State<_LivingOrb>
    with TickerProviderStateMixin {
  late final AnimationController _breathController;
  late final AnimationController _rimRotateController;
  late final AnimationController _particleOrbitController;

  static const double _orbBaseSize = 240.0;

  @override
  void initState() {
    super.initState();

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _rimRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _particleOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _breathController.dispose();
    _rimRotateController.dispose();
    _particleOrbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleFactor = widget.size / _orbBaseSize;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _breathController,
        _rimRotateController,
        _particleOrbitController,
      ]),
      builder: (context, child) {
        final breath = _breathController.value;
        final breathScale = 1.0 + (widget.isActive ? 0.08 : 0.04) * breath;

        return Container(
          color: Colors.transparent,
          child: Transform.scale(
            scale: scaleFactor,
            child: SizedBox(
              width: _orbBaseSize,
              height: _orbBaseSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Outer Aura Glow (300px, breathing)
                  Transform.scale(
                    scale: breathScale,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: widget.isActive
                                  ? 0.25 + 0.08 * breath
                                  : 0.20,
                            ),
                            blurRadius: 60,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Layer 2: Base Sphere (240px, true 3D radial gradient)
                  Container(
                    width: _orbBaseSize,
                    height: _orbBaseSize,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.3, -0.4),
                        radius: 0.85,
                        colors: [
                          Color(0xFFCCFBF1), // highlight (bright cyan-white)
                          Color(0xFF5EEAD4), // mid-tone
                          Color(0xFF14B8A6), // teal body
                          Color(0xFF0D9488), // shadow side
                          Color(0xFF0F766E), // deep shadow
                        ],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Layer 3: Specular Highlight (rotated oval at top-left)
                  Positioned(
                    top: 45,
                    left: 55,
                    child: Transform.rotate(
                      angle: -15 * pi / 180,
                      child: Container(
                        width: 50,
                        height: 28,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x99FFFFFF),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Layer 4: Inner Depth Ring (180px, hollow sphere feel)
                  Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x1A0F766E),
                          Colors.transparent,
                        ],
                        stops: [0.5, 0.75, 1.0],
                      ),
                    ),
                  ),

                  // Layer 5: Rotating Rim Light (240px, sweep gradient)
                  Transform.rotate(
                    angle: _rimRotateController.value * 2 * pi,
                    child: Container(
                      width: _orbBaseSize,
                      height: _orbBaseSize,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.transparent,
                            Color(0x405EEAD4),
                            Color(0x2014B8A6),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Layer 6: Caustic Reflection (bottom soft oval)
                  Positioned(
                    bottom: 40,
                    left: 90,
                    child: Container(
                      width: 60,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            Color(0x26FFFFFF),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Layer 7: Ambient Particle Ring (6-8 dots orbiting)
                  ..._buildParticles(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildParticles() {
    const int particleCount = 8;
    const double orbitRadius = 130.0;
    const double particleSize = 4.0;
    final double orbitAngle = _particleOrbitController.value * 2 * pi;

    return List.generate(particleCount, (index) {
      final phase = (index / particleCount) * 2 * pi;
      final angle = orbitAngle + phase;
      final x = orbitRadius * cos(angle);
      final y = orbitRadius * sin(angle);
      final alpha = 0.3 + 0.3 * ((index % 3) / 2); // varying alpha 0.3-0.6

      return Positioned(
        left: (_orbBaseSize / 2) + x - (particleSize / 2),
        top: (_orbBaseSize / 2) + y - (particleSize / 2),
        child: Container(
          width: particleSize,
          height: particleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: alpha),
          ),
        ),
      );
    });
  }
}

// =============================================================================
// _AnimatedDots — cycling "..." animation using Timer.periodic
// =============================================================================

class _AnimatedDots extends StatefulWidget {
  final String baseText;
  final TextStyle style;

  const _AnimatedDots({
    required this.baseText,
    required this.style,
  });

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots> {
  late Timer _timer;
  int _dotCount = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 800), (_) {
      if (mounted) {
        setState(() {
          _dotCount = (_dotCount + 1) % 4;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    return Text(
      '${widget.baseText}$dots',
      style: widget.style,
    );
  }
}

// =============================================================================
// _CircleControlButton — circular icon button with shadow
// =============================================================================

class _CircleControlButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color iconColor;
  final Color backgroundColor;
  final List<BoxShadow> boxShadow;
  final VoidCallback onPressed;

  const _CircleControlButton({
    required this.icon,
    required this.size,
    required this.iconColor,
    required this.backgroundColor,
    required this.boxShadow,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: boxShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(
            child: Icon(icon, color: iconColor, size: size * 0.4),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// _CircleIconLabelButton — labeled circular icon button (ended state)
// =============================================================================

class _CircleIconLabelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color? iconColor;
  final VoidCallback onPressed;

  const _CircleIconLabelButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Center(
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
