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
/// Features a holographic iridescent orb, minimal bottom controls,
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
              child: Column(
                children: [
                  // App bar area already reserved by the Scaffold AppBar.
                  Expanded(
                    child: _buildBody(context, call),
                  ),
                ],
              ),
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
    final bool isListening =
        call.currentState == CallState.active && !call.isMuted;

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
            if (isListening)
              const Text(
                'Listening...',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                ),
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
    return Center(
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
    );
  }

  // ---------------------------------------------------------------------------
  // Connecting / Idle state
  // ---------------------------------------------------------------------------

  Widget _buildConnecting(BuildContext context, CallProvider call) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Orb
        const _IridescentOrb(
          size: 220,
          isActive: false,
        ),
        const SizedBox(height: 32),
        const Text(
          'Tap to start',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(flex: 3),
        // Bottom controls — mic prominent, others subdued
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: 0.5,
                child: _CircleControlButton(
                  icon: Icons.graphic_eq,
                  size: 56,
                  iconColor: AppColors.primary,
                  backgroundColor: Colors.white,
                  boxShadow: AppColors.cardShadow,
                  onPressed: () => call.toggleMute(),
                ),
              ),
              const SizedBox(width: 24),
              _CircleControlButton(
                icon: Icons.mic,
                size: 72,
                iconColor: Colors.white,
                backgroundColor: AppColors.primary,
                boxShadow: AppColors.elevatedShadow,
                onPressed: () {
                  if (call.currentState == CallState.idle) {
                    call.startCall();
                  } else if (call.isMuted) {
                    call.toggleMute();
                  }
                },
              ),
              const SizedBox(width: 24),
              Opacity(
                opacity: 0.5,
                child: _CircleControlButton(
                  icon: Icons.close,
                  size: 56,
                  iconColor: AppColors.error,
                  backgroundColor: Colors.white,
                  boxShadow: AppColors.cardShadow,
                  onPressed: () {
                    _recordCallUsage(call);
                    call.endCall();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Active state
  // ---------------------------------------------------------------------------

  Widget _buildActive(BuildContext context, CallProvider call) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          // Orb
          const _IridescentOrb(
            size: 220,
            isActive: true,
          ),
          const SizedBox(height: 32),
          // Listening dots
          const _AnimatedDots(
            baseText: 'Listening',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          // Transcription
          _buildTranscriptionArea(call),
          const SizedBox(height: 8),
          // Duration
          Text(
            call.formattedDuration,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(flex: 3),
          // Bottom controls
          _buildBottomControls(context, call),
          const SizedBox(height: 40),
        ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause / waveform
        _CircleControlButton(
          icon: Icons.graphic_eq,
          size: 56,
          iconColor: AppColors.primary,
          backgroundColor: Colors.white,
          boxShadow: AppColors.cardShadow,
          onPressed: () => call.toggleMute(),
        ),
        const SizedBox(width: 24),
        // Main mic (primary CTA)
        _CircleControlButton(
          icon: Icons.mic,
          size: 72,
          iconColor: Colors.white,
          backgroundColor: AppColors.primary,
          boxShadow: AppColors.elevatedShadow,
          onPressed: () {
            if (call.isMuted) {
              call.toggleMute();
            }
          },
        ),
        const SizedBox(width: 24),
        // Close / end
        _CircleControlButton(
          icon: Icons.close,
          size: 56,
          iconColor: AppColors.error,
          backgroundColor: Colors.white,
          boxShadow: AppColors.cardShadow,
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 2),
            // Orb (static, smaller)
            const _IridescentOrb(
              size: 160,
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
                border: Border.all(color: const Color(0xFFE8E5F3)),
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
                call.error!,
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
                    call.resetCall();
                    call.startCall();
                  },
                ),
                const SizedBox(width: 40),
                // Go back
                _CircleIconLabelButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  backgroundColor: const Color(0xFFE8E5F3),
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
    );
  }
}

// =============================================================================
// _IridescentOrb — Custom liquid-glass holographic sphere
// =============================================================================

class _IridescentOrb extends StatefulWidget {
  final double size;
  final bool isActive;

  const _IridescentOrb({
    required this.size,
    required this.isActive,
  });

  @override
  State<_IridescentOrb> createState() => _IridescentOrbState();
}

class _IridescentOrbState extends State<_IridescentOrb>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pulseMin = widget.isActive ? 1.0 : 0.96;
    final pulseMax = widget.isActive ? 1.03 : 1.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_rotateController, _pulseController]),
      builder: (context, child) {
        final pulseValue = _pulseController.value;
        final scale = pulseMin + (pulseMax - pulseMin) * pulseValue;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(
                    alpha: widget.isActive ? 0.4 : 0.2,
                  ),
                  blurRadius: widget.isActive ? 48 : 32,
                  spreadRadius: widget.isActive ? 8 : 4,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: const Color(0xFFE0C3FC).withOpacity(0.4),
                  blurRadius: 60,
                  spreadRadius: 10,
                  offset: const Offset(-10, -10),
                ),
              ],
            ),
            child: ClipOval(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Layer 1: Base radial gradient for depth
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFFE0C3FC),
                          Color(0xFFA78BFA),
                          Color(0xFF8B5CF6),
                          Color(0xFF7C3AED),
                        ],
                      ),
                    ),
                  ),
                  // Layer 2: Rotating SweepGradient blended over the base
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: const [
                          Color(0xFFC4B5FD),
                          Color(0xFFA78BFA),
                          Color(0xFF8B5CF6),
                          Color(0xFFE0C3FC),
                          Color(0xFFC4B5FD),
                        ],
                        transform: GradientRotation(
                          _rotateController.value * 2 * pi,
                        ),
                      ),
                    ),
                  ),
                  // Specular highlight (top-left)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.4, -0.4),
                        radius: 0.5,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Inner depth ring (concave bowl effect)
                  Container(
                    width: widget.size * 0.82, // ~180px when size is 220
                    height: widget.size * 0.82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF7C3AED).withOpacity(0.25),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
