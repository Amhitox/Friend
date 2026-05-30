import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The type of limit that triggered the upgrade prompt.
enum LimitType {
  messageLimit,
  callLimit,
  featureLock,
}

/// Bottom sheet shown when a user hits a usage limit or tries to access
/// a locked feature. Displays a context-aware message in Darija with
/// upgrade options and an optional rewarded-ad shortcut.
class UpgradePromptSheet extends StatefulWidget {
  /// The kind of limit that was reached.
  final LimitType limitType;

  /// Number of messages/calls remaining (null for feature locks).
  final int? remaining;

  /// Name of the locked feature (only used when [limitType] is [LimitType.featureLock]).
  final String? featureName;

  /// Called when the user taps the Premium upgrade button.
  final VoidCallback? onUpgradePremium;

  /// Called when the user taps the VIP upgrade button.
  final VoidCallback? onUpgradeVIP;

  /// Called when the user chooses to watch a rewarded ad.
  final VoidCallback? onWatchAd;

  /// Called when the user dismisses the sheet ("Maybe later").
  final VoidCallback? onDismiss;

  /// Whether this is the first time showing the prompt this session.
  /// When true the sheet cannot be dismissed via back gesture.
  final bool isFirstShow;

  const UpgradePromptSheet({
    super.key,
    required this.limitType,
    this.remaining,
    this.featureName,
    this.onUpgradePremium,
    this.onUpgradeVIP,
    this.onWatchAd,
    this.onDismiss,
    this.isFirstShow = true,
  });

  /// Convenience method to present the sheet from anywhere.
  static Future<void> show(
    BuildContext context, {
    required LimitType limitType,
    int? remaining,
    String? featureName,
    VoidCallback? onUpgradePremium,
    VoidCallback? onUpgradeVIP,
    VoidCallback? onWatchAd,
    VoidCallback? onDismiss,
    bool isFirstShow = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: !isFirstShow,
      enableDrag: !isFirstShow,
      backgroundColor: Colors.transparent,
      builder: (_) => UpgradePromptSheet(
        limitType: limitType,
        remaining: remaining,
        featureName: featureName,
        onUpgradePremium: onUpgradePremium,
        onUpgradeVIP: onUpgradeVIP,
        onWatchAd: onWatchAd,
        onDismiss: onDismiss,
        isFirstShow: isFirstShow,
      ),
    );
  }

  @override
  State<UpgradePromptSheet> createState() => _UpgradePromptSheetState();
}

class _UpgradePromptSheetState extends State<UpgradePromptSheet>
    with TickerProviderStateMixin {
  late final AnimationController _illustrationController;
  late final AnimationController _contentController;
  late final Animation<double> _bounceAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeInOut),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Context-aware copy
  // ---------------------------------------------------------------------------

  String get _title {
    switch (widget.limitType) {
      case LimitType.messageLimit:
        return 'Wselti l-limit dyalek lyoum!';
      case LimitType.callLimit:
        return 'L-moqatelat dyalek salaw!';
      case LimitType.featureLock:
        return 'Had l-khasya ma mawjach b-tier dyalek.';
    }
  }

  String get _subtitle {
    switch (widget.limitType) {
      case LimitType.messageLimit:
        if (widget.remaining != null && widget.remaining! > 0) {
          return '3andek ${widget.remaining} messages b9aw. Upgrade bach tkamml.';
        }
        return 'Ma 3andek ta message. Upgrade wla shuf i3lan bach tzid 5.';
      case LimitType.callLimit:
        if (widget.remaining != null && widget.remaining! > 0) {
          return '3andek ${widget.remaining} moqatel b9aw l-youm.';
        }
        return 'Moqatelat dyalek salaw l-youm. Upgrade bach tkamml.';
      case LimitType.featureLock:
        return 'Upgrade l-Premium wla VIP bach t-khlli had l-khasya.';
    }
  }

  String get _illustrationEmoji {
    switch (widget.limitType) {
      case LimitType.messageLimit:
        return '💬';
      case LimitType.callLimit:
        return '📞';
      case LimitType.featureLock:
        return '🔒';
    }
  }

  Color get _accentColor {
    switch (widget.limitType) {
      case LimitType.messageLimit:
        return const Color(0xFF6C63FF);
      case LimitType.callLimit:
        return const Color(0xFF00BFA6);
      case LimitType.featureLock:
        return const Color(0xFFFF8A65);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            _buildDragHandle(),
            const SizedBox(height: 20),

            // Animated illustration
            _buildIllustration(),
            const SizedBox(height: 24),

            // Title + subtitle
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: _buildTextContent(),
              ),
            ),
            const SizedBox(height: 28),

            // Rewarded ad option (free-tier only, message limit only)
            if (widget.limitType == LimitType.messageLimit) ...[
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildRewardedAdCard(),
              ),
              const SizedBox(height: 20),
            ],

            // Upgrade buttons
            FadeTransition(
              opacity: _fadeAnimation,
              child: _buildUpgradeButtons(),
            ),
            const SizedBox(height: 16),

            // Dismiss
            _buildDismissButton(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _accentColor.withOpacity(0.3),
              _accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _illustrationEmoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      children: [
        Text(
          _title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardedAdCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onWatchAd?.call();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Ad icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🎬', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shuf l-i3lan w zid 5 messages!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'L-i3lan ghadi ydir ~30 seconds',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(
              Icons.play_circle_fill_rounded,
              color: const Color(0xFFFFD700),
              size: 32,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButtons() {
    return Column(
      children: [
        // Premium button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onUpgradePremium?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('⭐', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Upgrade l-Premium',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // VIP button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              widget.onUpgradeVIP?.call();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFFD700),
              side: const BorderSide(color: Color(0xFFFFD700), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('💎', style: TextStyle(fontSize: 18)),
                SizedBox(width: 8),
                Text(
                  'Upgrade l-VIP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissButton() {
    if (widget.isFirstShow) {
      // On first show we still display the text but the back gesture is blocked.
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: TextButton(
          onPressed: () {
            widget.onDismiss?.call();
            Navigator.of(context).pop();
          },
          child: Text(
            'Mn be3d',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: TextButton(
        onPressed: () {
          widget.onDismiss?.call();
          Navigator.of(context).pop();
        },
        child: Text(
          'Mn be3d',
          style: TextStyle(
            color: Colors.white.withOpacity(0.45),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
