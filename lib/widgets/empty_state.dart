import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable empty-state display for the Dostok app.
///
/// Shown when a screen has no content to display (no messages, no tasks,
/// no search results, etc.). Displays an illustration placeholder, a
/// message, and an optional action button.
///
/// Usage:
/// ```dart
/// EmptyState(
///   onAction: () => startNewChat(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String? lottiePath;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;
  final double illustrationSize;

  const EmptyState({
    super.key,
    this.icon,
    this.imagePath,
    this.lottiePath,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.accentColor,
    this.illustrationSize = 96,
  });

  factory EmptyState.messages({Key? key, VoidCallback? onAction}) {
    return EmptyState(
      key: key,
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No messages yet',
      message: 'Start a chat and I will be your companion',
      actionLabel: 'Start chatting',
      onAction: onAction,
    );
  }

  factory EmptyState.tasks({Key? key, VoidCallback? onAction}) {
    return EmptyState(
      key: key,
      icon: Icons.task_alt_rounded,
      title: 'No tasks yet',
      message: 'Add something to keep track of',
      actionLabel: 'Add task',
      onAction: onAction,
    );
  }

  factory EmptyState.searchResults({Key? key, VoidCallback? onAction}) {
    return EmptyState(
      key: key,
      icon: Icons.search_off_rounded,
      title: 'Nothing found',
      message: 'Try different words or search again',
      actionLabel: 'Clear search',
      onAction: onAction,
      illustrationSize: 80,
    );
  }

  factory EmptyState.dailyHistory({Key? key, VoidCallback? onAction}) {
    return EmptyState(
      key: key,
      icon: Icons.calendar_today_rounded,
      title: 'No entries yet',
      message: 'Start your day and I will keep track',
      actionLabel: 'Start day',
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? const Color(0xFF7C6BF5);

    final effectiveTitle = title ?? 'Nothing here';
    final effectiveMessage = message ?? '';
    final effectiveActionLabel = actionLabel ?? 'Get started';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIllustration(isDark, effectiveAccent),
            const SizedBox(height: 24),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (effectiveMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  effectiveActionLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: effectiveAccent,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: effectiveAccent.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isDark, Color accent) {
    if (lottiePath != null) {
      return SizedBox(
        width: illustrationSize,
        height: illustrationSize,
        child: _LottieIllustration(path: lottiePath!),
      );
    }
    if (imagePath != null) {
      return SizedBox(
        width: illustrationSize,
        height: illustrationSize,
        child: Image.asset(
          imagePath!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(isDark, accent),
        ),
      );
    }
    return _buildFallbackIcon(isDark, accent);
  }

  Widget _buildFallbackIcon(bool isDark, Color accent) {
    return SizedBox(
      width: illustrationSize,
      height: illustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: illustrationSize,
            height: illustrationSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(isDark ? 0.08 : 0.06),
            ),
          ),
          Container(
            width: illustrationSize * 0.72,
            height: illustrationSize * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(isDark ? 0.12 : 0.1),
            ),
          ),
          Icon(
            icon ?? Icons.waving_hand_rounded,
            size: illustrationSize * 0.42,
            color: accent.withOpacity(0.8),
          ),
        ],
      ),
    );
  }
}

class _LottieIllustration extends StatelessWidget {
  final String path;

  const _LottieIllustration({required this.path});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
