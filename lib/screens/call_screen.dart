import 'dart:math';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../providers/call_provider.dart';
import '../services/subscription_service.dart';
import '../services/analytics_service.dart';
import '../models/subscription.dart';
import '../widgets/upgrade_prompt_sheet.dart';

// =============================================================================
// CallScreen — Full-screen voice call interface for Dostok
// =============================================================================

/// A full-screen voice call UI consumed by [CallProvider].
///
/// Monetization integration:
/// - Checks canMakeCall() before starting call
/// - If no call minutes: shows UpgradePromptSheet
/// - Tracks call duration against quota
/// - Shows remaining minutes during call
/// - Warns at 80% usage
/// - Auto-ends call when quota exhausted (with friendly message)
/// - Records usage on call end
class CallScreen extends StatefulWidget {
  const CallScreen({super.key});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> with TickerProviderStateMixin {
  // ---------------------------------------------------------------------------
  // Animation controllers
  // ---------------------------------------------------------------------------

  /// Drives the waveform bars in the active state.
  late final AnimationController _waveformController;

  /// Drives the ring / connecting pulse animation.
  late final AnimationController _ringController;

  /// Drives the fade-in of the ended summary.
  late final AnimationController _summaryFadeController;

  /// Controls the avatar glow pulse.
  late final AnimationController _glowPulseController;

  /// Whether microphone permission was granted.
  bool _micPermissionGranted = false;

  /// Error message if permission was denied.
  String? _permissionError;

  /// Whether the call was auto-ended due to quota exhaustion.
  bool _quotaExhausted = false;

  /// Whether the 80% warning has been shown already.
  bool _warnedAt80 = false;

  /// The call duration at the time the call started (for tracking).
  Duration _callDurationAtStart = Duration.zero;

  // Random seed for waveform bar heights so they look organic.
  final List<double> _waveformSeeds = List.generate(
    _kWaveformBarCount,
    (_) => Random().nextDouble(),
  );

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const int _kWaveformBarCount = 32;
  static const double _kAvatarRadius = 56.0;
  static const Duration _kRingAnimDuration = Duration(seconds: 2);
  static const Duration _kWaveformAnimDuration = Duration(milliseconds: 600);
  static const Duration _kSummaryFadeDuration = Duration(milliseconds: 500);
  static const Duration _kGlowPulseDuration = Duration(seconds: 2);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _waveformController = AnimationController(
      vsync: this,
      duration: _kWaveformAnimDuration,
    )..repeat(reverse: true);

    _ringController = AnimationController(
      vsync: this,
      duration: _kRingAnimDuration,
    )..repeat();

    _summaryFadeController = AnimationController(
      vsync: this,
      duration: _kSummaryFadeDuration,
    );

    _glowPulseController = AnimationController(
      vsync: this,
      duration: _kGlowPulseDuration,
    )..repeat(reverse: true);

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
      final subService = context.read<SubscriptionService>();

      // Check if user can make a call.
      if (!subService.canMakeCall()) {
        _showCallLimitPrompt(subService);
        return;
      }

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
    _waveformController.dispose();
    _ringController.dispose();
    _summaryFadeController.dispose();
    _glowPulseController.dispose();

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
  // Monetization helpers
  // ---------------------------------------------------------------------------

  /// Shows UpgradePromptSheet when user has no call minutes remaining.
  void _showCallLimitPrompt(SubscriptionService subService) {
    AnalyticsService().logPaywallShown(
      trigger: 'call_limit',
      placement: 'call',
    );

    UpgradePromptSheet.show(
      context,
      limitType: LimitType.callLimit,
      remaining: 0,
      onUpgradePremium: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/paywall', arguments: {
          'highlightFeature': 'voice_calls',
        });
      },
      onUpgradeVIP: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushNamed('/paywall', arguments: {
          'highlightFeature': 'voice_calls',
        });
      },
      onDismiss: () {
        AnalyticsService().logPaywallDismissed(placement: 'call');
        Navigator.of(context).pop(); // Go back from call screen.
      },
    );
  }

  /// Records call usage in the subscription service.
  void _recordCallUsage(CallProvider callProvider) {
    final subService = context.read<SubscriptionService>();
    final duration = callProvider.callDuration;
    final minutes = duration.inSeconds / 60.0;

    if (minutes > 0) {
      subService.recordCallMinutes(minutes);
      AnalyticsService().logCallEnded(
        durationSeconds: duration.inSeconds,
        callType: 'voice',
      );
    }
  }

  /// Checks call quota during an active call. Warns at 80%, auto-ends at limit.
  void _checkCallQuota(CallProvider callProvider) {
    final subService = context.read<SubscriptionService>();
    final maxMinutes = subService.limits.maxCallMinutesPerDay;

    // Unlimited for this tier.
    if (maxMinutes == -1) return;

    final remainingMinutes = subService.remainingCallMinutes;
    if (remainingMinutes == -1) return;

    final elapsedMinutes = callProvider.callDuration.inSeconds / 60.0;

    // Auto-end when quota is exhausted.
    if (elapsedMinutes >= maxMinutes) {
      if (!_quotaExhausted) {
        _quotaExhausted = true;
        _recordCallUsage(callProvider);
        callProvider.endCall();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'L-moqatelat dyalek salaw l-youm! Upgrade bach tzid.',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Warn at 80% usage.
    if (!_warnedAt80) {
      final usedRatio = elapsedMinutes / maxMinutes;
      if (usedRatio >= 0.8) {
        _warnedAt80 = true;
        final remaining = (maxMinutes - elapsedMinutes).ceil();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$remaining ${remaining == 1 ? "minute" : "minutes"} b9aw',
              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFFFFA726),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Consumer2<CallProvider, SubscriptionService>(
      builder: (context, call, subService, _) {
        // Trigger summary fade-in when the call ends.
        if (call.currentState == CallState.ended &&
            _summaryFadeController.status == AnimationStatus.dismissed) {
          _summaryFadeController.forward();
        }

        // Check quota during active calls.
        if (call.currentState == CallState.active) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkCallQuota(call);
          });
        }

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF00695C), // teal[800]
                  Color(0xFF004D40), // teal[900]
                  Color(0xFF1A1A2E), // dark navy
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: _buildBody(context, call, subService),
            ),
          ),
        );
      },
    );
  }

  /// Delegates to the correct sub-layout based on [CallProvider.currentState].
  Widget _buildBody(
    BuildContext context,
    CallProvider call,
    SubscriptionService subService,
  ) {
    // Permission denied — show an error state instead of the call UI.
    if (!_micPermissionGranted) {
      return _buildPermissionDenied();
    }

    switch (call.currentState) {
      case CallState.idle:
        // Idle is transient; show connecting as a fallback.
        return _buildConnecting(context, call, subService);
      case CallState.connecting:
        return _buildConnecting(context, call, subService);
      case CallState.active:
        return _buildActive(context, call, subService);
      case CallState.ended:
        return _buildEnded(context, call, subService);
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
            const Icon(Icons.mic_off_rounded, size: 64, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              _permissionError ?? 'Permission required.',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => openAppSettings(),
              icon: const Icon(Icons.settings),
              label: Text(
                'Open Settings',
                style: GoogleFonts.cairo(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Go Back',
                style: GoogleFonts.cairo(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Connecting state — ring animation
  // ---------------------------------------------------------------------------

  Widget _buildConnecting(
    BuildContext context,
    CallProvider call,
    SubscriptionService subService,
  ) {
    return Column(
      children: [
        const Spacer(flex: 2),

        // Pulsing ring + avatar
        _buildAvatarSection(
          context,
          call,
          child: AnimatedBuilder(
            animation: _ringController,
            builder: (context, child) {
              return Container(
                width: (_kAvatarRadius * 2) + 48,
                height: (_kAvatarRadius * 2) + 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(
                      0.3 + 0.3 * sin(_ringController.value * 2 * pi),
                    ),
                    width: 2 + 2 * _ringController.value,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // Status text
        Text(
          'Connecting...',
          style: GoogleFonts.cairo(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),

        const Spacer(flex: 3),

        // Cancel button
        Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: _EndCallButton(
            onPressed: () {
              _recordCallUsage(call);
              call.endCall();
            },
            size: 64,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Active state — full UI (with remaining minutes display)
  // ---------------------------------------------------------------------------

  Widget _buildActive(
    BuildContext context,
    CallProvider call,
    SubscriptionService subService,
  ) {
    final maxMinutes = subService.limits.maxCallMinutesPerDay;
    final remainingMinutes = maxMinutes == -1
        ? -1
        : (maxMinutes - (call.callDuration.inSeconds / 60.0)).clamp(0, maxMinutes);

    return Column(
      children: [
        const SizedBox(height: 24),

        // ---- Top: Avatar + name + status + duration ----
        _buildAvatarSection(context, call),
        const SizedBox(height: 20),
        Text(
          'Dostok',
          style: GoogleFonts.cairo(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          call.isMuted ? 'Muted' : 'In Call',
          style: GoogleFonts.cairo(
            fontSize: 14,
            color: call.isMuted ? Colors.orangeAccent : Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          call.formattedDuration,
          style: GoogleFonts.cairo(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.85),
            letterSpacing: 2,
          ),
        ),

        // ---- Remaining minutes indicator (for non-unlimited tiers) ----
        if (remainingMinutes != -1) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: remainingMinutes <= 2
                  ? const Color(0xFFFF6B6B).withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: remainingMinutes <= 2
                    ? const Color(0xFFFF6B6B).withOpacity(0.4)
                    : Colors.white.withOpacity(0.15),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: remainingMinutes <= 2
                      ? const Color(0xFFFF8A8A)
                      : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  '${remainingMinutes.toStringAsFixed(1)} min b9aw',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: remainingMinutes <= 2
                        ? const Color(0xFFFF8A8A)
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // ---- Middle: Waveform visualization ----
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Animated waveform bars
                _buildWaveform(call),
                const SizedBox(height: 20),

                // Real-time transcript display area
                Expanded(
                  child: _buildTranscriptArea(),
                ),
              ],
            ),
          ),
        ),

        // ---- Bottom: Controls ----
        _buildBottomControls(context, call),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Ended state — summary (with usage recording)
  // ---------------------------------------------------------------------------

  Widget _buildEnded(
    BuildContext context,
    CallProvider call,
    SubscriptionService subService,
  ) {
    return FadeTransition(
      opacity: _summaryFadeController,
      child: Column(
        children: [
          const Spacer(flex: 2),

          // Avatar (no glow)
          CircleAvatar(
            radius: _kAvatarRadius,
            backgroundColor: Colors.white.withOpacity(0.15),
            child: const Icon(
              Icons.person_rounded,
              size: 56,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            _quotaExhausted ? 'W9t l-mkimat salaw!' : 'Call Ended',
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 12),

          // Duration summary
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Duration: ${call.formattedDuration}',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          // Quota exhausted message
          if (_quotaExhausted) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Moqatelat dyalek salaw l-youm. Upgrade l-Premium bach tzid!',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: const Color(0xFFFFD700),
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Error message if call ended due to an error
          if (call.error != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                call.error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: Colors.orangeAccent,
                ),
              ),
            ),
          ],

          const Spacer(flex: 2),

          // Action buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Call again (only if quota allows)
                _CircleIconButton(
                  icon: Icons.call_rounded,
                  label: 'Call Again',
                  backgroundColor: subService.canMakeCall()
                      ? const Color(0xFF00897B)
                      : Colors.grey.shade700,
                  onPressed: () {
                    if (subService.canMakeCall()) {
                      _quotaExhausted = false;
                      _warnedAt80 = false;
                      _summaryFadeController.reset();
                      call.resetCall();
                      call.startCall();
                    } else {
                      _showCallLimitPrompt(subService);
                    }
                  },
                ),
                const SizedBox(width: 40),
                // Go back
                _CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back',
                  backgroundColor: Colors.white.withOpacity(0.15),
                  onPressed: () {
                    call.resetCall();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shared widgets
  // ---------------------------------------------------------------------------

  /// Builds the avatar with optional glow and a [child] decoration overlay.
  Widget _buildAvatarSection(
    BuildContext context,
    CallProvider call, {
    Widget? child,
  }) {
    final avatar = CircleAvatar(
      radius: _kAvatarRadius,
      backgroundColor: Colors.white.withOpacity(0.15),
      child: const Icon(
        Icons.person_rounded,
        size: 56,
        color: Colors.white,
      ),
    );

    Widget avatarWidget = avatar;
    if (child != null) {
      avatarWidget = Stack(
        alignment: Alignment.center,
        children: [child, avatar],
      );
    }

    // Wrap in AvatarGlow for the active state pulse.
    if (call.currentState == CallState.active ||
        call.currentState == CallState.connecting) {
      return AvatarGlow(
        glowColor: const Color(0xFF00897B),
        endRadius: 75.0,
        animate: true,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  /// Animated waveform visualization — 32 bars whose heights oscillate.
  Widget _buildWaveform(CallProvider call) {
    final isMuted = call.isMuted;

    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, _) {
        return SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_kWaveformBarCount, (i) {
              // Compute a height that oscillate based on the animation value
              // and the per-bar seed so bars move independently.
              final seed = _waveformSeeds[i];
              final phase = (_waveformController.value * 2 * pi) + (seed * pi);
              final rawHeight = (sin(phase) * 0.5 + 0.5); // 0..1
              final minHeight = 6.0;
              final maxHeight = isMuted ? 12.0 : 56.0;
              final height = minHeight + rawHeight * (maxHeight - minHeight);

              return AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isMuted
                      ? Colors.white24
                      : Colors.white.withOpacity(0.6 + rawHeight * 0.4),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// Scrollable transcript display area.
  Widget _buildTranscriptArea() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transcript',
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white38,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Text(
                'Listening...',
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: Colors.white38,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom control bar: mute, speaker, end-call, switch-to-text.
  Widget _buildBottomControls(BuildContext context, CallProvider call) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40, left: 24, right: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Mute
          _CallControlButton(
            icon: call.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            label: call.isMuted ? 'Unmute' : 'Mute',
            isActive: call.isMuted,
            activeColor: Colors.orangeAccent,
            onPressed: () => call.toggleMute(),
          ),

          // End call (prominent)
          _EndCallButton(
            onPressed: () {
              _recordCallUsage(call);
              call.endCall();
            },
            size: 72,
          ),

          // Speaker
          _CallControlButton(
            icon: call.isSpeakerOn
                ? Icons.volume_up_rounded
                : Icons.volume_down_rounded,
            label: 'Speaker',
            isActive: call.isSpeakerOn,
            activeColor: const Color(0xFF64FFDA),
            onPressed: () => call.toggleSpeaker(),
          ),

          // Switch to text
          _CallControlButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Text',
            isActive: false,
            onPressed: () {
              _recordCallUsage(call);
              call.endCall();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Private helper widgets
// =============================================================================

/// A circular control button used in the bottom call-controls row.
class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onPressed;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor ?? Colors.white : Colors.white70;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isActive
              ? (activeColor ?? Colors.white).withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }
}

/// The prominent red end-call button.
class _EndCallButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const _EndCallButton({
    required this.onPressed,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.redAccent.shade700,
          shape: const CircleBorder(),
          elevation: 6,
          shadowColor: Colors.redAccent.withOpacity(0.4),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: size * 0.45,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'End',
          style: GoogleFonts.cairo(
            fontSize: 11,
            color: Colors.redAccent.shade100,
          ),
        ),
      ],
    );
  }
}

/// A labeled circular icon button used in the ended-state summary.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _CircleIconButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 13,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
