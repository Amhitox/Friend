import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Subscription tiers available in Dostok.
enum DostokTier { free, premium, vip }

/// Usage data for the current billing period.
class UsageData {
  final int messagesUsed;
  final int messagesLimit; // -1 for unlimited
  final int callsUsed;
  final int callsLimit; // -1 for unlimited
  final int daysRemaining; // 0 for free tier

  const UsageData({
    required this.messagesUsed,
    required this.messagesLimit,
    required this.callsUsed,
    required this.callsLimit,
    this.daysRemaining = 0,
  });

  bool get messagesUnlimited => messagesLimit == -1;
  bool get callsUnlimited => callsLimit == -1;

  double get messageFraction =>
      messagesUnlimited ? 0 : messagesUsed / messagesLimit;
  double get callFraction => callsUnlimited ? 0 : callsUsed / callsLimit;
}

/// A card displayed on the profile / settings screen showing the user's
/// current subscription tier, usage statistics, and action buttons.
///
/// The card adapts its gradient, icon, and available actions to the tier.
class SubscriptionStatusCard extends StatelessWidget {
  final DostokTier tier;
  final UsageData usage;

  /// Called when the user taps "Manage subscription".
  final VoidCallback? onManage;

  /// Called when the user taps "Upgrade".
  final VoidCallback? onUpgrade;

  const SubscriptionStatusCard({
    super.key,
    required this.tier,
    required this.usage,
    this.onManage,
    this.onUpgrade,
  });

  // ---------------------------------------------------------------------------
  // Tier theming
  // ---------------------------------------------------------------------------

  String get _tierLabel {
    switch (tier) {
      case DostokTier.free:
        return 'Free';
      case DostokTier.premium:
        return 'Premium';
      case DostokTier.vip:
        return 'VIP';
    }
  }

  String get _tierEmoji {
    switch (tier) {
      case DostokTier.free:
        return '🆓';
      case DostokTier.premium:
        return '⭐';
      case DostokTier.vip:
        return '💎';
    }
  }

  List<Color> get _gradientColors {
    switch (tier) {
      case DostokTier.free:
        return [
          const Color(0xFF2D2D44),
          const Color(0xFF3A3A5C),
        ];
      case DostokTier.premium:
        return [
          const Color(0xFF4A3FCF),
          const Color(0xFF6C63FF),
          const Color(0xFF8B83FF),
        ];
      case DostokTier.vip:
        return [
          const Color(0xFFB8860B),
          const Color(0xFFE0C3FC),
          const Color(0xFFE0C3FC),
        ];
    }
  }

  Color get _accentColor {
    switch (tier) {
      case DostokTier.free:
        return const Color(0xFF9E9E9E);
      case DostokTier.premium:
        return const Color(0xFF6C63FF);
      case DostokTier.vip:
        return const Color(0xFFE0C3FC);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradientColors,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle decorative circles
            Positioned(
              top: -30,
              right: -30,
              child: _buildDecoCircle(100, 0.08),
            ),
            Positioned(
              bottom: -20,
              left: -20,
              child: _buildDecoCircle(80, 0.06),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: badge + manage button
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // Days remaining (if subscribed)
                  if (tier != DostokTier.free) ...[
                    _buildDaysRemaining(),
                    const SizedBox(height: 20),
                  ],

                  // Usage bars
                  _buildUsageSection(),
                  const SizedBox(height: 20),

                  // Action button
                  _buildActionButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildDecoCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Tier badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_tierEmoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                'Dostok $_tierLabel',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),

        // Manage button (subscribed users only)
        if (tier != DostokTier.free)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onManage?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.settings_rounded,
                    size: 15,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Manage',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDaysRemaining() {
    return Row(
      children: [
        Icon(
          Icons.calendar_today_rounded,
          size: 16,
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Text(
          '${usage.daysRemaining} nhar b9aw',
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (usage.daysRemaining <= 7)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Ghadi t-sali!',
              style: TextStyle(
                color: Color(0xFFFF8A8A),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsageSection() {
    return Column(
      children: [
        _UsageBar(
          label: 'Messages',
          icon: Icons.chat_bubble_rounded,
          used: usage.messagesUsed,
          limit: usage.messagesLimit,
          unlimited: usage.messagesUnlimited,
          accentColor: _accentColor,
        ),
        const SizedBox(height: 14),
        _UsageBar(
          label: 'Moqatelat',
          icon: Icons.phone_rounded,
          used: usage.callsUsed,
          limit: usage.callsLimit,
          unlimited: usage.callsUnlimited,
          accentColor: _accentColor,
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (tier == DostokTier.free) {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            onUpgrade?.call();
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
              Icon(Icons.rocket_launch_rounded, size: 18),
              SizedBox(width: 8),
              Text(
                'Upgrade daba',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Subscribed: show renewal info
    return Center(
      child: Text(
        'Auto-renew mshghal',
        style: TextStyle(
          color: Colors.white.withOpacity(0.45),
          fontSize: 12,
        ),
      ),
    );
  }
}

// =============================================================================
// Usage bar widget
// =============================================================================

class _UsageBar extends StatelessWidget {
  final String label;
  final IconData icon;
  final int used;
  final int limit;
  final bool unlimited;
  final Color accentColor;

  const _UsageBar({
    required this.label,
    required this.icon,
    required this.used,
    required this.limit,
    required this.unlimited,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.white.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              unlimited ? '$used / ∞' : '$used / $limit',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                // Background
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // Fill
                FractionallySizedBox(
                  widthFactor: unlimited ? 0.15 : _fraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor,
                          accentColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  double get _fraction => limit > 0 ? used / limit : 0;
}
