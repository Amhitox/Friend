import 'package:flutter/material.dart';

/// An expandable daily card widget for the Dostok app.
///
/// Displays a card with gradient background, title, content, and an
/// action button. Can be expanded to show more content.
///
/// Usage:
/// ```dart
/// DailyCard(
///   title: 'Ders lyoum',
///   content: 'T3allem kelma jdida...',
///   actionLabel: 'Bda',
///   onAction: () {
///     // Handle action
///   },
/// )
/// ```
class DailyCard extends StatefulWidget {
  /// The card title.
  final String title;

  /// The main content text.
  final String content;

  /// Optional extended content shown when expanded.
  final String? expandedContent;

  /// Label for the action button.
  final String? actionLabel;

  /// Callback when action button is pressed.
  final VoidCallback? onAction;

  /// Custom gradient colors (optional).
  final List<Color>? gradientColors;

  /// Leading icon or widget.
  final IconData? icon;

  const DailyCard({
    super.key,
    required this.title,
    required this.content,
    this.expandedContent,
    this.actionLabel,
    this.onAction,
    this.gradientColors,
    this.icon,
  });

  @override
  State<DailyCard> createState() => _DailyCardState();
}

class _DailyCardState extends State<DailyCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
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
          theme.colorScheme.secondary.withOpacity(0.6),
        ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? colors.map((c) => c.withOpacity(0.7)).toList()
                  : colors,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main content area
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Expand/collapse button
                        if (widget.expandedContent != null)
                          IconButton(
                            icon: AnimatedRotation(
                              turns: _isExpanded ? 0.5 : 0,
                              duration: const Duration(milliseconds: 300),
                              child: const Icon(
                                Icons.expand_more,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: _toggleExpand,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Content text
                    Text(
                      widget.content,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Expanded content
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 8),
                      Text(
                        widget.expandedContent ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Action button
              if (widget.actionLabel != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: widget.onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
