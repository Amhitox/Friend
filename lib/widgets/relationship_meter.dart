import 'package:flutter/material.dart';

/// A relationship meter widget for the Dostok app.
///
/// Displays a LinearProgressIndicator with gradient colors and level labels.
/// Animates the fill from current to target value.
///
/// Usage:
/// ```dart
/// RelationshipMeter(
///   level: 0.6,
///   label: 'Sahib',
/// )
/// ```
class RelationshipMeter extends StatefulWidget {
  /// The current relationship level (0.0 to 1.0).
  final double level;

  /// Optional label to display (overrides auto-detection).
  final String? label;

  /// Custom gradient colors (optional).
  final List<Color>? gradientColors;

  /// Height of the progress bar.
  final double height;

  const RelationshipMeter({
    super.key,
    required this.level,
    this.label,
    this.gradientColors,
    this.height = 12,
  });

  @override
  State<RelationshipMeter> createState() => _RelationshipMeterState();
}

class _RelationshipMeterState extends State<RelationshipMeter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousLevel = 0;

  /// Relationship levels with Darija labels.
  static const List<Map<String, dynamic>> _levels = [
    {'threshold': 0.0, 'label': 'Sadiq Jedid', 'emoji': '👋'},
    {'threshold': 0.25, 'label': 'Sahib', 'emoji': '🤝'},
    {'threshold': 0.5, 'label': 'Kho', 'emoji': '💪'},
    {'threshold': 0.75, 'label': '7bibi', 'emoji': '❤️'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0,
      end: widget.level,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(RelationshipMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.level != oldWidget.level) {
      _previousLevel = oldWidget.level;
      _animation = Tween<double>(
        begin: _previousLevel,
        end: widget.level,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Gets the appropriate label for the current level.
  String _getLabel() {
    if (widget.label != null) return widget.label!;

    String label = _levels[0]['label'];
    for (var level in _levels) {
      if (widget.level >= level['threshold']) {
        label = level['label'];
      }
    }
    return label;
  }

  /// Gets the emoji for the current level.
  String _getEmoji() {
    String emoji = _levels[0]['emoji'];
    for (var level in _levels) {
      if (widget.level >= level['threshold']) {
        emoji = level['emoji'];
      }
    }
    return emoji;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Default gradient colors
    final colors = widget.gradientColors ??
        [
          Colors.green,
          Colors.teal,
          Colors.blue,
          Colors.purple,
        ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with label and emoji
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _getEmoji(),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Livwel: ${_getLabel()}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(widget.level * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress bar
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  height: widget.height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.height / 2),
                    color: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _animation.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.height / 2),
                        gradient: LinearGradient(
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Level markers
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _levels.map((level) {
                return Text(
                  level['label'],
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.level >= level['threshold']
                        ? theme.colorScheme.primary
                        : isDark
                            ? Colors.grey[600]
                            : Colors.grey[400],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
