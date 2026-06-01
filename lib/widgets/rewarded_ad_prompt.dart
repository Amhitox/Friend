import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// State of the rewarded ad interaction.
enum RewardedAdState {
  /// Ready to watch.
  idle,

  /// Ad is loading.
  loading,

  /// Ad is playing.
  playing,

  /// Reward was granted.
  success,

  /// Ad failed or was closed before completion.
  failure,

  /// Daily limit of rewarded ads reached.
  limitReached,
}

/// Inline widget that lets free-tier users watch a rewarded ad in exchange
/// for 5 extra messages. Capped at 3 rewarded ads per day.
///
/// ## Usage
/// ```dart
/// RewardedAdPrompt(
///   adsWatchedToday: 2,
///   onWatchAd: () async {
///     // Show rewarded ad; return true if completed.
///     return await AdService.showRewarded();
///   },
///   onRewardGranted: () {
///     // Add 5 messages to user's balance.
///   },
/// )
/// ```
class RewardedAdPrompt extends StatefulWidget {
  /// Number of rewarded ads the user has already watched today.
  final int adsWatchedToday;

  /// Maximum rewarded ads allowed per day.
  final int maxAdsPerDay;

  /// Callback to trigger the rewarded ad. Returns `true` if the ad was
  /// watched to completion.
  final Future<bool> Function()? onWatchAd;

  /// Called after a successful watch to credit the reward.
  final VoidCallback? onRewardGranted;

  /// Number of messages granted per rewarded ad.
  final int messagesPerAd;

  const RewardedAdPrompt({
    super.key,
    this.adsWatchedToday = 0,
    this.maxAdsPerDay = 3,
    this.onWatchAd,
    this.onRewardGranted,
    this.messagesPerAd = 5,
  });

  @override
  State<RewardedAdPrompt> createState() => _RewardedAdPromptState();
}

class _RewardedAdPromptState extends State<RewardedAdPrompt>
    with TickerProviderStateMixin {
  RewardedAdState _state = RewardedAdState.idle;

  late final AnimationController _successController;
  late final Animation<double> _successScale;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  Timer? _successResetTimer;

  int get _remaining => widget.maxAdsPerDay - widget.adsWatchedToday;
  bool get _limitReached => _remaining <= 0;

  @override
  void initState() {
    super.initState();

    if (_limitReached) {
      _state = RewardedAdState.limitReached;
    }

    // Success pop animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // Subtle pulse for the watch button
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    _pulseController.dispose();
    _successResetTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _handleWatch() async {
    if (_state == RewardedAdState.loading ||
        _state == RewardedAdState.playing ||
        _state == RewardedAdState.limitReached) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() => _state = RewardedAdState.loading);

    try {
      final completed = await widget.onWatchAd?.call() ?? false;

      if (!mounted) return;

      if (completed) {
        setState(() => _state = RewardedAdState.success);
        _successController.forward(from: 0);
        HapticFeedback.heavyImpact();
        widget.onRewardGranted?.call();

        // Auto-reset to idle (or limitReached) after a few seconds
        _successResetTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          final newAdsWatched = widget.adsWatchedToday + 1;
          setState(() {
            _state = newAdsWatched >= widget.maxAdsPerDay
                ? RewardedAdState.limitReached
                : RewardedAdState.idle;
          });
        });
      } else {
        setState(() => _state = RewardedAdState.failure);
        _scheduleResetToIdle();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = RewardedAdState.failure);
      _scheduleResetToIdle();
    }
  }

  void _scheduleResetToIdle() {
    _successResetTimer?.cancel();
    _successResetTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _state = RewardedAdState.idle);
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case RewardedAdState.idle:
        return _buildIdleCard(key: const ValueKey('idle'));
      case RewardedAdState.loading:
      case RewardedAdState.playing:
        return _buildLoadingCard(key: const ValueKey('loading'));
      case RewardedAdState.success:
        return _buildSuccessCard(key: const ValueKey('success'));
      case RewardedAdState.failure:
        return _buildFailureCard(key: const ValueKey('failure'));
      case RewardedAdState.limitReached:
        return _buildLimitCard(key: const ValueKey('limit'));
    }
  }

  // -- Idle -------------------------------------------------------------------

  Widget _buildIdleCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E3A),
            const Color(0xFF252550),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0C3FC).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE0C3FC).withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text('🎬', style: TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shuf l-i3lan 3la ${widget.messagesPerAd} messages zaydin?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'B9awlek $_remaining chances l-youm',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Watch button
          ScaleTransition(
            scale: _pulseScale,
            child: GestureDetector(
              onTap: _handleWatch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0C3FC), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE0C3FC).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Shuf',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Loading ----------------------------------------------------------------

  Widget _buildLoadingCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Color(0xFFE0C3FC),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'T-charja l-i3lan...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // -- Success ----------------------------------------------------------------

  Widget _buildSuccessCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BFA6).withOpacity(0.15),
            const Color(0xFF00BFA6).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00BFA6).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _successScale,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF00BFA6).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_rounded,
                  color: Color(0xFF00BFA6),
                  size: 24,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${widget.messagesPerAd} messages tzadou! 🎉',
                  style: const TextStyle(
                    color: Color(0xFF00BFA6),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Shukran 3la l-motaba3a!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Failure ----------------------------------------------------------------

  Widget _buildFailureCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('😅', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ma tqderch daba. Jreb m3a wa9t.',
                  style: TextStyle(
                    color: Color(0xFFFF8A8A),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'L-i3lan ma shghalch. Dir try mn be3d.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -- Limit reached ----------------------------------------------------------

  Widget _buildLimitCard({Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E3A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('🕐', style: TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Staghlti kolshi l-youm!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Jreb ghadwa, wla upgrade bach tzid.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
