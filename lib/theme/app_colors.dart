import 'package:flutter/material.dart';

/// Central color palette for the Dostok app.
///
/// All colors are organized by usage pattern: brand, surface, text, semantic,
/// and gradients. This class is intentionally not instantiable -- every member
/// is a static const so colors can be referenced as `AppColors.primary`
/// throughout the codebase without allocating objects.
///
/// The palette is built around a teal (#00897B) primary and an amber (#FFB300)
/// accent, reflecting Moroccan warmth and modernity.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand / Primary
  // ---------------------------------------------------------------------------

  /// Primary teal -- the dominant brand color.
  static const Color primary = Color(0xFF00897B);

  /// Darker teal variant for elevated surfaces and dark-theme primary.
  static const Color primaryDark = Color(0xFF00695C);

  /// Light teal for backgrounds, chips, and subtle highlights.
  static const Color primaryLight = Color(0xFFB2DFDB);

  /// Very light teal tint for card fills and containers.
  static const Color primaryContainer = Color(0xFFE0F2F1);

  // ---------------------------------------------------------------------------
  // Secondary / Accent
  // ---------------------------------------------------------------------------

  /// Accent amber -- used for FABs, highlights, and call-to-action elements.
  static const Color secondary = Color(0xFFFFB300);

  /// Darker amber for pressed states and text on light backgrounds.
  static const Color secondaryDark = Color(0xFFFF8F00);

  /// Light amber for secondary container fills.
  static const Color secondaryLight = Color(0xFFFFE082);

  /// Very light amber tint for secondary containers.
  static const Color secondaryContainer = Color(0xFFFFF8E1);

  // ---------------------------------------------------------------------------
  // Surface & Background
  // ---------------------------------------------------------------------------

  /// Warm off-white scaffold background for light theme.
  static const Color backgroundLight = Color(0xFFF5F5F0);

  /// Dark surface background for dark theme.
  static const Color backgroundDark = Color(0xFF121212);

  /// Card and elevated surface color in light theme.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Card and elevated surface color in dark theme.
  static const Color surfaceDark = Color(0xFF1E1E1E);

  /// Subtle divider and separator color.
  static const Color divider = Color(0xFFE0E0E0);

  /// Dark theme divider.
  static const Color dividerDark = Color(0xFF2C2C2C);

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  /// Primary text color for light theme (near-black).
  static const Color textPrimary = Color(0xFF212121);

  /// Secondary text color for light theme (muted).
  static const Color textSecondary = Color(0xFF757575);

  /// Primary text color for dark theme (near-white).
  static const Color textPrimaryDark = Color(0xFFECECEC);

  /// Secondary text color for dark theme.
  static const Color textSecondaryDark = Color(0xFF9E9E9E);

  /// Text on primary-colored surfaces.
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// Text on secondary/amber surfaces.
  static const Color textOnSecondary = Color(0xFF212121);

  // ---------------------------------------------------------------------------
  // Semantic / Status
  // ---------------------------------------------------------------------------

  /// Success green -- task completion, positive indicators.
  static const Color success = Color(0xFF4CAF50);

  /// Light success background for cards and chips.
  static const Color successLight = Color(0xFFE8F5E9);

  /// Error red -- validation errors, destructive actions.
  static const Color error = Color(0xFFEF5350);

  /// Light error background.
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Warning orange -- caution states.
  static const Color warning = Color(0xFFFFA726);

  /// Light warning background.
  static const Color warningLight = Color(0xFFFFF3E0);

  /// Info blue -- informational messages.
  static const Color info = Color(0xFF42A5F5);

  /// Light info background.
  static const Color infoLight = Color(0xFFE3F2FD);

  // ---------------------------------------------------------------------------
  // Chat Bubble
  // ---------------------------------------------------------------------------

  /// Background for user-sent chat bubbles (light theme).
  static const Color bubbleUser = Color(0xFFE0F2F1);

  /// Background for AI-sent chat bubbles (light theme).
  static const Color bubbleAi = Color(0xFFFFF8E1);

  /// Background for user-sent chat bubbles (dark theme).
  static const Color bubbleUserDark = Color(0xFF004D40);

  /// Background for AI-sent chat bubbles (dark theme).
  static const Color bubbleAiDark = Color(0xFF3E2723);

  // ---------------------------------------------------------------------------
  // Call & Voice
  // ---------------------------------------------------------------------------

  /// Active call / recording indicator (pulsing red).
  static const Color callActive = Color(0xFFE53935);

  /// Call button / start-call green.
  static const Color callButton = Color(0xFF00897B);

  /// Voice waveform active color.
  static const Color waveformActive = Color(0xFF00897B);

  /// Voice waveform inactive / idle color.
  static const Color waveformIdle = Color(0xFFB2DFDB);

  // ---------------------------------------------------------------------------
  // Mood Colors
  // ---------------------------------------------------------------------------

  /// Mood: happy (warm yellow).
  static const Color moodHappy = Color(0xFFFFCA28);

  /// Mood: excited (vibrant orange).
  static const Color moodExcited = Color(0xFFFF7043);

  /// Mood: tired (muted blue-grey).
  static const Color moodTired = Color(0xFF90A4AE);

  /// Mood: neutral (medium grey).
  static const Color moodNeutral = Color(0xFFBDBDBD);

  /// Mood: anxious (tense purple).
  static const Color moodAnxious = Color(0xFFAB47BC);

  /// Mood: sad (deep blue).
  static const Color moodSad = Color(0xFF5C6BC0);

  // ---------------------------------------------------------------------------
  // Gradients
  // ---------------------------------------------------------------------------

  /// Primary brand gradient (teal top-left to dark teal bottom-right).
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Warm accent gradient (amber to deep amber).
  static const LinearGradient gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  /// Teal-to-light container gradient for hero sections.
  static const LinearGradient gradientTealFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryLight],
  );

  /// Subtle warm background gradient for onboarding and splash.
  static const LinearGradient gradientWarmBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF5F5F0), Color(0xFFE8F5E9)],
  );

  /// Dark theme background gradient.
  static const LinearGradient gradientDarkBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
  );

  /// Call screen ambient gradient (dark teal overlay).
  static const LinearGradient gradientCallAmbient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
  );
}
