import 'dart:async';

import 'package:flutter/material.dart';

/// A loading indicator that displays a rotating set of friendly
/// messages beneath a [CircularProgressIndicator].
///
/// The messages cycle every 2 seconds by default, fading in and out smoothly
/// so the user always knows the app is working.
///
/// Usage:
/// ```dart
/// LoadingWidget()
/// ```
class LoadingWidget extends StatefulWidget {
  final List<String>? messages;
  final Color? color;
  final Duration messageDuration;
  final Duration animationDuration;
  final double spinnerSize;
  final double strokeWidth;

  const LoadingWidget({
    super.key,
    this.messages,
    this.color,
    this.messageDuration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 400),
    this.spinnerSize = 40,
    this.strokeWidth = 3.5,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late final List<String> _messages;
  late final Color _color;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  int _currentIndex = 0;
  Timer? _timer;

  static const List<String> _defaultMessages = [
    'Just a moment...',
    'Loading...',
    'Thinking...',
    'Preparing something nice...',
    'Almost ready...',
    'One moment...',
  ];

  @override
  void initState() {
    super.initState();
    _messages = widget.messages ?? _defaultMessages;
    _color = widget.color ?? const Color(0xFF7C6BF5);

    _fadeController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _fadeController.value = 1.0;
    _timer = Timer.periodic(widget.messageDuration, (_) => _nextMessage());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _nextMessage() {
    if (!mounted || _messages.length <= 1) return;
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _messages.length;
      });
      _fadeController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: widget.spinnerSize,
              height: widget.spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _messages[_currentIndex],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact inline loading indicator for use inside buttons, list tiles, or
/// other constrained spaces.
class InlineLoadingIndicator extends StatelessWidget {
  final String? label;
  final Color? color;
  final double size;

  const InlineLoadingIndicator({
    super.key,
    this.label,
    this.color,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFF7C6BF5);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(
            label!,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ],
    );
  }
}
