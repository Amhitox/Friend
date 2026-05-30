import 'package:flutter/material.dart';

/// A tappable action card widget for the Dostok app.
///
/// Displays a card with icon, title, subtitle, gradient background, and
/// rounded corners. Includes InkWell with scale animation on press.
///
/// Usage:
/// ```dart
/// ActionCard(
///   icon: Icons.chat_bubble,
///   title: 'Hder m3aya',
///   subtitle: 'Bda conversation jdida',
///   onTap: () {
///     // Handle tap
///   },
/// )
/// ```
class ActionCard extends StatefulWidget {
  /// The icon to display.
  final IconData icon;

  /// The card title.
  final String title;

  /// Optional subtitle text.
  final String? subtitle;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Custom gradient colors (optional).
  final List<Color>? gradientColors;

  /// Icon color (optional, defaults to white).
  final Color? iconColor;

  /// Whether to show a trailing arrow.
  final bool showArrow;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.gradientColors,
    this.iconColor,
    this.showArrow = true,
  });

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default gradient colors
    final colors = widget.gradientColors ??
        [
          theme.colorScheme.primary,
          theme.colorScheme.primary.withOpacity(0.8),
        ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isDark
                          ? colors.map((c) => c.withOpacity(0.6)).toList()
                          : colors,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Icon container
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            widget.icon,
                            color: widget.iconColor ?? Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Title and subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Trailing arrow
                        if (widget.showArrow)
                          Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white.withOpacity(0.7),
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
