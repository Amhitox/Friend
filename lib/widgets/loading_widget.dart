import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A loading indicator that displays a rotating set of friendly Darija
/// messages beneath a [CircularProgressIndicator].
///
/// The messages cycle every 2 seconds by default, fading in and out smoothly
/// so the user always knows the app is working.
///
/// Usage:
/// ```dart
/// // Default rotating messages
/// LoadingWidget()
///
/// // Custom messages
/// LoadingWidget(
///   messages: ['كنحضّر ليك...', 'واحد شوية...'],
///   color: Colors.teal,
/// )
/// ```
class LoadingWidget extends StatefulWidget {
  /// Optional list of Darija messages to cycle through.
  ///
  /// When `null` a built-in set of friendly loading messages is used.
  final List<String>? messages;

  /// The accent color for the spinner and text. Defaults to the app's
  /// primary teal (`Color(0xFF7C6BF5)`).
  final Color? color;

  /// Duration each message stays visible before transitioning.
  final Duration messageDuration;

  /// Duration of the cross-fade animation between messages.
  final Duration animationDuration;

  /// Size of the [CircularProgressIndicator].
  final double spinnerSize;

  /// Stroke width of the [CircularProgressIndicator].
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

  /// Default Darija loading messages -- warm, casual, and reassuring.
  static const List<String> _defaultMessages = [
    'شوية ديال الصبر...', // Shwiya d-sbar... = A little patience...
    'كنتسنّى...', // Kantssenna... = Waiting...
    'كنفكر شنو نقول ليك...', // Kanfekkar shnu ngoul lik... = Thinking of what to say...
    'كنحضّر ليك شي حاجة زوينة...', // Kan7addher lik shi 7aja zwina... = Preparing something nice...
    'تقريبا وجدت...', // Tqriban wjdad... = Almost ready...
    'واحد لحظة...', // Wahd l-lahda... = One moment...
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

    // Start fully visible.
    _fadeController.value = 1.0;

    // Cycle messages on a timer.
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

    // Fade out, swap text, fade in.
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
            // Spinner.
            SizedBox(
              width: widget.spinnerSize,
              height: widget.spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: widget.strokeWidth,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
            const SizedBox(height: 20),

            // Rotating message with fade transition.
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                _messages[_currentIndex],
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
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
///
/// Shows a small spinner with optional Darija text next to it.
///
/// Usage:
/// ```dart
/// InlineLoadingIndicator(label: 'كنصيفط...') // "Sending..."
/// ```
class InlineLoadingIndicator extends StatelessWidget {
  /// Optional text displayed to the right of the spinner.
  final String? label;

  /// Spinner accent color.
  final Color? color;

  /// Spinner diameter.
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
            textDirection: TextDirection.rtl,
            style: GoogleFonts.cairo(
              fontSize: 14,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
        ],
      ],
    );
  }
}
