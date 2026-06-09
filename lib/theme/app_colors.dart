import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color primaryContainer = Color(0xFFE0F2FE);

  // Surface
  static const Color background = Color(0xFFF0FDFA);
  static const Color backgroundLight = background;
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surface = Colors.white;
  static const Color surfaceLight = surface;
  static const Color surfaceDark = Color(0xFF1E293B);

  // Text
  static const Color textPrimary = Color(0xFF134E4A);
  static const Color textPrimaryDark = Color(0xFFF0FDFA);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Secondary accent
  static const Color secondary = Color(0xFFFDBA74);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);

  // Dividers
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);

  // Chat
  static const Color bubbleUser = Color(0xFF0D9488);
  static const Color bubbleAi = Colors.white;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A0D9488),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x260D9488),
      blurRadius: 30,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // Gradients
  static const LinearGradient dreamyBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF0FDFA), Color(0xFFECFDF5)],
  );

  static const LinearGradient orbGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF99F6E4), Color(0xFF5EEAD4), Color(0xFF14B8A6), Color(0xFF0D9488), Color(0xFF0F766E)],
  );

  static const RadialGradient orbRadial = RadialGradient(
    colors: [Color(0xFF99F6E4), Color(0xFF5EEAD4), Color(0xFF14B8A6), Color(0xFF0F766E)],
  );
}
