import 'package:flutter/material.dart';

/// A user-friendly error display for the Dostok app.
///
/// Shows a large icon, a friendly error message, and an optional retry button.
///
/// Usage:
/// ```dart
/// AppErrorWidget(onRetry: () => provider.refresh())
/// ```
class AppErrorWidget extends StatelessWidget {
  final IconData? icon;
  final String? title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final Color? color;
  final bool showDismiss;
  final VoidCallback? onDismiss;

  const AppErrorWidget({
    super.key,
    this.icon,
    this.title,
    this.message,
    this.retryLabel,
    this.onRetry,
    this.color,
    this.showDismiss = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = color ?? const Color(0xFF7C6BF5);

    final effectiveIcon = icon ?? Icons.cloud_off_rounded;
    final effectiveTitle = title ?? 'Oops!';
    final effectiveMessage =
        message ?? 'Something went wrong. Please try again.';
    final effectiveRetryLabel = retryLabel ?? 'Try again';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(isDark ? 0.15 : 0.1),
              ),
              child: Icon(
                effectiveIcon,
                size: 44,
                color: accentColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  effectiveRetryLabel,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: accentColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                ),
              ),
            if (showDismiss) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDismiss ?? () => Navigator.of(context).maybePop(),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small inline error banner that can be embedded inside other widgets.
class InlineErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final Color? backgroundColor;

  const InlineErrorBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0xFF3E2723).withOpacity(0.6)
            : const Color(0xFFFFF3E0));
    final textColor = isDark ? Colors.orange.shade200 : Colors.orange.shade900;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: textColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: textColor,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
