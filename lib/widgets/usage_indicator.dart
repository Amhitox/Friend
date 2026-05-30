import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays remaining usage as a circular or linear progress indicator.
///
/// Color-coded green/yellow/red based on remaining percentage. Tapping the
/// indicator shows a full usage breakdown bottom sheet. Animates smoothly
/// when the value changes and glows subtly when near the limit.
///
/// Usage:
/// ```dart
/// UsageIndicator(
///   current: 15,
///   max: 20,
///   label: 'rassayil l-yum',
///   unit: 'rassila',
///   style: UsageIndicatorStyle.circular,
/// )
/// ```
class UsageIndicator extends StatefulWidget {
  /// Current usage count (messages sent, minutes used, etc.).
  final num current;

  /// Maximum allowed. Use -1 for unlimited (hides the indicator).
  final num max;

  /// Descriptive label appended after the count, e.g. "rassayil l-yum".
  final String label;

  /// Unit word for the breakdown sheet, e.g. "rassila" or "dqiqa".
  final String unit;

  /// Visual style: circular gauge or horizontal bar.
  final UsageIndicatorStyle style;

  /// Optional icon shown inside or next to the indicator.
  final IconData? icon;

  /// Additional breakdown rows shown in the detail bottom sheet.
  final List<UsageBreakdownItem>? breakdownItems;

  const UsageIndicator({
    super.key,
    required this.current,
    required this.max,
    required this.label,
    this.unit = '',
    this.style = UsageIndicatorStyle.circular,
    this.icon,
    this.breakdownItems,
  });

  @override
  State<UsageIndicator> createState() => _UsageIndicatorState();
}

class _UsageIndicatorState extends State<UsageIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  num _previousCurrent = 0;

  @override
  void initState() {
    super.initState();
    _previousCurrent = widget.current;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _updateGlow();
  }

  @override
  void didUpdateWidget(UsageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current ||
        oldWidget.max != widget.max) {
      _previousCurrent = oldWidget.current;
      _updateGlow();
    }
  }

  void _updateGlow() {
    if (widget.max > 0 && _ratio >= 0.8) {
      _glowController.repeat(reverse: true);
    } else {
      _glowController.stop();
      _glowController.value = 0;
    }
  }

  /// Usage ratio clamped to [0, 1]. Returns 0 for unlimited.
  double get _ratio {
    if (widget.max <= 0) return 0;
    return (widget.current / widget.max).clamp(0.0, 1.0);
  }

  /// Remaining percentage as a fraction [0, 1].
  double get _remaining => 1.0 - _ratio;

  /// Semantic color based on remaining percentage.
  Color get _color {
    if (_remaining > 0.5) return AppColors.success;
    if (_remaining > 0.2) return AppColors.warning;
    return AppColors.error;
  }

  /// Whether this usage is unlimited (max == -1).
  bool get _isUnlimited => widget.max == -1;

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Unlimited -> no indicator
    if (_isUnlimited) return const SizedBox.shrink();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: GestureDetector(
        onTap: () => _showBreakdownSheet(context),
        child: AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              decoration: _ratio >= 0.8
                  ? BoxDecoration(
                      shape: widget.style == UsageIndicatorStyle.circular
                          ? BoxShape.circle
                          : BoxShape.rectangle,
                      boxShadow: [
                        BoxShadow(
                          color: _color.withOpacity(0.3 * _glowAnimation.value),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: child,
            );
          },
          child: widget.style == UsageIndicatorStyle.circular
              ? _buildCircular(context)
              : _buildLinear(context),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Circular indicator
  // ---------------------------------------------------------------------------

  Widget _buildCircular(BuildContext context) {
    final theme = Theme.of(context);
    final size = 56.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previousCurrent.toDouble(), end: widget.current.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedCurrent, _) {
        final animatedRatio = widget.max > 0
            ? (animatedCurrent / widget.max).clamp(0.0, 1.0)
            : 0.0;
        final remaining = (widget.max - animatedCurrent).clamp(0, widget.max);

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedRatio,
                  strokeWidth: 5,
                  backgroundColor: _color.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              if (widget.icon != null)
                Icon(widget.icon, size: 20, color: _color)
              else
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${remaining.toInt()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _color,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      'left',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _color.withOpacity(0.7),
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Linear indicator
  // ---------------------------------------------------------------------------

  Widget _buildLinear(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _previousCurrent.toDouble(), end: widget.current.toDouble()),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animatedCurrent, _) {
        final animatedRatio = widget.max > 0
            ? (animatedCurrent / widget.max).clamp(0.0, 1.0)
            : 0.0;
        final remaining = (widget.max - animatedCurrent).clamp(0, widget.max);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 16, color: _color),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(
                    '${remaining.toInt()}/${widget.max.toInt()} ${widget.label}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(animatedRatio * 100).toInt()}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: animatedRatio,
                minHeight: 6,
                backgroundColor: _color.withOpacity(0.12),
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Breakdown bottom sheet
  // ---------------------------------------------------------------------------

  void _showBreakdownSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = (widget.max - widget.current).clamp(0, widget.max);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Stistikat L-yom',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              // Main stat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      widget.icon ?? Icons.data_usage_rounded,
                      color: _color,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${remaining.toInt()} ${widget.unit} mazal',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: _color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'mn ${widget.max.toInt()} ${widget.label}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: _color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Used / max bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _ratio,
                  minHeight: 10,
                  backgroundColor: _color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(_color),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Msta3mel: ${widget.current.toInt()}',
                    style: theme.textTheme.bodySmall,
                  ),
                  Text(
                    'B9a: ${remaining.toInt()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Extra breakdown items
              if (widget.breakdownItems != null &&
                  widget.breakdownItems!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                ...widget.breakdownItems!.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 20, color: item.color ?? theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(item.label, style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          item.value,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// Visual style for the [UsageIndicator].
enum UsageIndicatorStyle {
  /// Circular progress ring (default).
  circular,

  /// Horizontal linear bar.
  linear,
}

/// An additional row shown in the usage breakdown bottom sheet.
class UsageBreakdownItem {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const UsageBreakdownItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });
}
