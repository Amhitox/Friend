import 'package:flutter/material.dart';

/// Central color palette for the Dostok app.
///
/// All colors are organized by usage pattern: brand, surface, text, semantic,
/// and gradients. This class is intentionally not instantiable -- every member
/// is a static const so colors can be referenced as `AppColors.primary`
/// throughout the codebase without allocating objects.
///
/// The palette is built around a vivid purple (#7C6BF5) primary and a soft
/// orchid (#C77DFF) accent, for a modern, calm AI-assistant aesthetic with
/// lavender surfaces and iridescent gradients.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand / Primary
  // ---------------------------------------------------------------------------

  /// Primary purple -- the dominant brand color.
  static const Color primary = Color(0xFF7C6BF5);

  /// Darker purple variant for elevated surfaces and dark-theme primary.
  static const Color primaryDark = Color(0xFF5B4BD6);

  /// Light lavender for backgrounds, chips, and subtle highlights.
  static const Color primaryLight = Color(0xFFCFC6FF);

  /// Very light lavender tint for card fills and containers.
  static const Color primaryContainer = Color(0xFFEDE9FF);

  // ---------------------------------------------------------------------------
  // Secondary / Accent
  // ---------------------------------------------------------------------------

  /// Accent orchid -- used for FABs, highlights, and call-to-action elements.
  static const Color secondary = Color(0xFFC77DFF);

  /// Darker orchid for pressed states and text on light backgrounds.
  static const Color secondaryDark = Color(0xFF9D4EDD);

  /// Light orchid for secondary container fills.
  static const Color secondaryLight = Color(0xFFE0C3FC);

  /// Very light orchid tint for secondary containers.
  static const Color secondaryContainer = Color(0xFFF3E8FF);

  // ---------------------------------------------------------------------------
  // Surface & Background
  // ---------------------------------------------------------------------------

  /// Soft lavender-white scaffold background for light theme.
  static const Color backgroundLight = Color(0xFFF7F5FF);

  /// Deep purple-tinted background for dark theme.
  static const Color backgroundDark = Color(0xFF14121F);

  /// Card and elevated surface color in light theme.
  static const Color surfaceLight = Color(0xFFFFFFFF);

  /// Card and elevated surface color in dark theme.
  static const Color surfaceDark = Color(0xFF1E1B2E);

  /// Subtle divider and separator color.
  static const Color divider = Color(0xFFEAE6F7);

  /// Dark theme divider.
  static const Color dividerDark = Color(0xFF2C2840);

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
  static const Color bubbleUser = Color(0xFFE5DEFF);

  /// Background for AI-sent chat bubbles (light theme).
  static const Color bubbleAi = Color(0xFFF4F1FF);

  /// Background for user-sent chat bubbles (dark theme).
  static const Color bubbleUserDark = Color(0xFF4B3FA8);

  /// Background for AI-sent chat bubbles (dark theme).
  static const Color bubbleAiDark = Color(0xFF2A2640);

  // ---------------------------------------------------------------------------
  // Call & Voice
  // ---------------------------------------------------------------------------

  /// Active call / recording indicator (pulsing red).
  static const Color callActive = Color(0xFFE53935);

  /// Call button / start-call purple.
  static const Color callButton = Color(0xFF7C6BF5);

  /// Voice waveform active color.
  static const Color waveformActive = Color(0xFF7C6BF5);

  /// Voice waveform inactive / idle color.
  static const Color waveformIdle = Color(0xFFCFC6FF);

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

  /// Primary brand gradient (purple top-left to deep purple bottom-right).
  static const LinearGradient gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  /// Orchid accent gradient (light orchid to deep orchid).
  static const LinearGradient gradientSecondary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryDark],
  );

  /// Purple-to-lavender container gradient for hero sections.
  static const LinearGradient gradientTealFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, primaryLight],
  );

  /// Subtle lavender background gradient for onboarding and splash.
  static const LinearGradient gradientWarmBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF7F5FF), Color(0xFFF1E9FF)],
  );

  /// Dark theme background gradient.
  static const LinearGradient gradientDarkBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B2E), Color(0xFF14121F)],
  );

  /// Iridescent voice/call ambient gradient (the signature holographic sphere).
  static const LinearGradient gradientCallAmbient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C6BF5), Color(0xFFB388FF), Color(0xFFE0C3FC)],
  );
}
