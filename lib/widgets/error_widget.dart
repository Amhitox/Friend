import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A user-friendly error display for the Dostok app.
///
/// Shows a large icon, a friendly Darija (or English) error message, and an
/// optional retry button. Designed to feel warm rather than alarming -- the
/// tone is "something small went wrong" not "catastrophic failure".
///
/// Usage:
/// ```dart
/// // Default Darija message with retry
/// AppErrorWidget(onRetry: () => provider.refresh())
///
/// // Custom message
/// AppErrorWidget(
///   title: 'مكاينش الأنترنت',
///   message: 'تأكد من الكونيكسيون ديالك',
///   icon: Icons.wifi_off_rounded,
///   onRetry: () => provider.refresh(),
/// )
/// ```
class AppErrorWidget extends StatelessWidget {
  /// Large icon displayed at the top. Defaults to a cloud-off icon.
  final IconData? icon;

  /// Error title shown below the icon. Defaults to a generic Darija message.
  final String? title;

  /// Descriptive error body text. Defaults to a generic Darija description.
  final String? message;

  /// Label for the retry button. Defaults to Darija "Try again".
  final String? retryLabel;

  /// Callback invoked when the user taps the retry button.
  ///
  /// When `null` the retry button is not shown.
  final VoidCallback? onRetry;

  /// Accent color for the icon and retry button. Defaults to the app teal.
  final Color? color;

  /// Whether to show a secondary dismiss / close button.
  final bool showDismiss;

  /// Called when the user taps the dismiss button.
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
    final accentColor = color ?? const Color(0xFF00897B);

    final effectiveIcon = icon ?? Icons.cloud_off_rounded;
    final effectiveTitle = title ?? 'واحد المشكيل!';
    final effectiveMessage =
        message ?? 'وقع شي مشكيل، عاود جرب مرة أخرى';
    final effectiveRetryLabel = retryLabel ?? 'عاود جرب';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with a subtle background circle.
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

            // Title.
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Description.
            Text(
              effectiveMessage,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 28),

            // Retry button.
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  effectiveRetryLabel,
                  style: GoogleFonts.cairo(
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

            // Optional dismiss / close button.
            if (showDismiss) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDismiss ?? () => Navigator.of(context).maybePop(),
                child: Text(
                  'سدّ',
                  style: GoogleFonts.cairo(
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

/// A small inline error banner that can be embedded inside other widgets
/// (e.g. above a list, inside a card).
///
/// Shows a warning icon, a one-line Darija message, and an optional retry
/// action.
///
/// Usage:
/// ```dart
/// InlineErrorBanner(
///   message: 'مشكيل ف الأنترنت',
///   onRetry: () => provider.refresh(),
/// )
/// ```
class InlineErrorBanner extends StatelessWidget {
  /// The error text.
  final String message;

  /// Optional callback for the retry action. When `null` the action button
  /// is hidden.
  final VoidCallback? onRetry;

  /// Background color override.
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
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
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
                'عاود جرب',
                style: GoogleFonts.cairo(
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
