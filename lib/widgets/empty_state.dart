import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// A reusable empty-state display for the Dostok app.
///
/// Shown when a screen has no content to display (no messages, no tasks,
/// no search results, etc.). Displays an illustration placeholder, a
/// Darija (or English) message, and an optional action button.
///
/// Usage:
/// ```dart
/// // Default messages empty state
/// EmptyState(
///   onAction: () => startNewChat(),
/// )
///
/// // Custom content
/// EmptyState(
///   icon: Icons.task_alt_rounded,
///   title: 'ما زال ما ديرتي شي واجب',
///   message: 'زيد شي واجب باش نعاونك نتتبعو',
///   actionLabel: 'زيد حاجة',
///   onAction: () => showAddTaskDialog(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Large illustration icon displayed at the top.
  ///
  /// Defaults to a waving-hand icon to match the app's friendly tone.
  final IconData? icon;

  /// Optional image asset path to display instead of an icon.
  ///
  /// When provided, [icon] is ignored. The image is rendered at
  /// [illustrationSize] x [illustrationSize].
  final String? imagePath;

  /// Optional Lottie animation asset path.
  ///
  /// Takes precedence over both [icon] and [imagePath] when provided.
  /// Requires the `lottie` package (already in pubspec.yaml).
  final String? lottiePath;

  /// Bold heading text. Defaults to the generic Darija empty title.
  final String? title;

  /// Descriptive body text below the title. Defaults to a generic Darija
  /// description.
  final String? message;

  /// Text for the primary action button.
  ///
  /// When `null` the button is hidden.
  final String? actionLabel;

  /// Callback when the user taps the action button.
  final VoidCallback? onAction;

  /// Accent color for the icon, button, and glow effects.
  ///
  /// Defaults to the app's primary teal.
  final Color? accentColor;

  /// The size of the illustration (icon, image, or Lottie container).
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = accentColor ?? const Color(0xFF7C6BF5);

    final effectiveTitle = title ?? 'والو هنا';
    final effectiveMessage = message ?? '';
    final effectiveActionLabel = actionLabel ?? 'بدا هضرة دابا';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration area.
            _buildIllustration(isDark, effectiveAccent),
            const SizedBox(height: 24),

            // Title.
            Text(
              effectiveTitle,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: GoogleFonts.cairo(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),

            // Description (optional).
            if (effectiveMessage.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                effectiveMessage,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],

            // Action button (optional).
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  effectiveActionLabel,
                  style: GoogleFonts.cairo(
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

  /// Builds the illustration at the top of the empty state.
  ///
  /// Priority: Lottie > Image asset > Icon with decorative ring.
  Widget _buildIllustration(bool isDark, Color accent) {
    // Lottie animation (highest priority).
    if (lottiePath != null) {
      return SizedBox(
        width: illustrationSize,
        height: illustrationSize,
        child: _LottieIllustration(path: lottiePath!),
      );
    }

    // Static image asset.
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

    // Default: icon with decorative concentric rings.
    return _buildFallbackIcon(isDark, accent);
  }

  /// The default icon presentation with a soft glowing ring behind it.
  Widget _buildFallbackIcon(bool isDark, Color accent) {
    return SizedBox(
      width: illustrationSize,
      height: illustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring.
          Container(
            width: illustrationSize,
            height: illustrationSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(isDark ? 0.08 : 0.06),
            ),
          ),
          // Inner ring.
          Container(
            width: illustrationSize * 0.72,
            height: illustrationSize * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(isDark ? 0.12 : 0.1),
            ),
          ),
          // Icon.
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

/// Renders a Lottie animation from the given asset [path].
///
/// Falls back to an empty [SizedBox] if the asset file is missing or cannot
/// be decoded, so the [EmptyState] icon fallback still appears.
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

/// Pre-configured empty states for common Dostok screens.
///
/// These factory constructors provide Darija copy tailored to each context
/// so screens can display a consistent empty state with one line of code.
///
/// Usage:
/// ```dart
/// EmptyState.messages(onAction: () => startNewChat())
/// EmptyState.tasks(onAction: () => showAddTaskDialog())
/// EmptyState.searchResults(onAction: () => clearSearch())
/// ```
extension EmptyStatePresets on EmptyState {
  /// Empty state for the messages / chat screen.
  static Widget messages({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'ما زال ما هضرنا!',
      message: 'بدا هضرة معايا و غادي نكون صاحبك',
      actionLabel: 'بدا هضرة دابا',
      onAction: onAction,
    );
  }

  /// Empty state for the daily tasks list.
  static Widget tasks({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.task_alt_rounded,
      title: 'ما زال ما ديرتي شي واجب',
      message: 'زيد شي واجب باش نعاونك نتتبعو',
      actionLabel: 'زيد واجب',
      onAction: onAction,
    );
  }

  /// Empty state for search results.
  static Widget searchResults({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: 'ما لقيت والو',
      message: 'جرب كلمات أخرى ولا عاود البحث',
      actionLabel: 'مسح البحث',
      onAction: onAction,
      illustrationSize: 80,
    );
  }

  /// Empty state for the daily mood / history screen.
  static Widget dailyHistory({VoidCallback? onAction}) {
    return EmptyState(
      icon: Icons.calendar_today_rounded,
      title: 'ما زال ما سجلتي شي حاجة',
      message: 'بدا نهارك معايا و غادي نتتبعو',
      actionLabel: 'بدا نهارك',
      onAction: onAction,
    );
  }
}
