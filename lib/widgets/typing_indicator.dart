import 'dart:math';

import 'package:flutter/material.dart';

/// An animated typing indicator with three bouncing dots.
///
/// Shown at the bottom of the chat list while the AI is composing a response.
/// Each dot bounces with a staggered delay to create a wave effect.
/// The widget fades in/out smoothly via [AnimatedOpacity].
///
/// Usage:
/// ```dart
/// // Show the indicator
/// TypingIndicator(isVisible: true)
///
/// // Hide with fade-out
/// TypingIndicator(isVisible: false)
///
/// // Custom label
/// TypingIndicator(label: 'Dostok kaykteb...')
/// ```
class TypingIndicator extends StatefulWidget {
  /// Whether the indicator is visible. Toggling this triggers a fade.
  final bool isVisible;

  /// Optional label displayed next to the dots.
  final String? label;

  const TypingIndicator({
    super.key,
    this.isVisible = true,
    this.label,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final List<Animation<double>> _bounceAnimations;

  @override
  void initState() {
    super.initState();

    // Bounce controller -- loops continuously while the indicator is visible.
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Three staggered bounce curves for the dots.
    _bounceAnimations = List.generate(3, (index) {
      final start = index * 0.15;
      final end = start + 0.5;
      return Tween<double>(begin: 0, end: -8).animate(
        CurvedAnimation(
          parent: _bounceController,
          curve: Interval(
            start.clamp(0.0, 1.0),
            end.clamp(0.0, 1.0),
            curve: Curves.easeInOut,
          ),
        ),
      );
    });

    if (widget.isVisible) {
      _bounceController.repeat();
    }
  }

  @override
  void didUpdateWidget(TypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _bounceController.repeat();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _bounceController.stop();
      _bounceController.reset();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedOpacity(
      opacity: widget.isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin:
              const EdgeInsets.only(left: 12, right: 48, top: 4, bottom: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouncing dots
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimations[index].value),
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < 2 ? 5 : 0,
                          ),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.5)
                                : const Color(0xFF7C6BF5).withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              // Label
              if (widget.label != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.label!,
                  style: TextStyle(fontFamily: 'Cairo', 
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Shimmer loading placeholder
// =============================================================================

/// A shimmer placeholder for loading messages.
///
/// Renders a list of fake message bubbles with a shimmer gradient sweeping
/// across to give the impression that content is loading.
class ChatLoadingShimmer extends StatelessWidget {
  const ChatLoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final highlightColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer(
      gradient: LinearGradient(
        colors: [baseColor, highlightColor, baseColor],
        stops: const [0.0, 0.5, 1.0],
      ),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: 6,
        itemBuilder: (context, index) {
          final isUser = index.isOdd;
          final width = 140.0 + Random(index).nextInt(100).toDouble();
          return Align(
            alignment:
                isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: width,
              height: 48,
              margin: EdgeInsets.only(
                left: isUser ? 48 : 12,
                right: isUser ? 12 : 48,
                top: 4,
                bottom: 4,
              ),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Minimal local Shimmer widget.
/// Re-exports the key behaviour for the loading shimmer without an
/// additional package import.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Gradient gradient;
  final Duration duration;

  const Shimmer({
    super.key,
    required this.child,
    required this.gradient,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: widget.duration)
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return widget.gradient.createShader(
              Rect.fromLTWH(
                -bounds.width + bounds.width * 2 * _controller.value,
                0,
                bounds.width * 2,
                bounds.height,
              ),
            );
          },
          child: child,
        );
      },
    );
  }
}
