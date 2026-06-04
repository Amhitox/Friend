import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF8B7BF7);
  static const Color primaryDark = Color(0xFF7C6BF5);
  static const Color primaryLight = Color(0xFFE8D5FF);
  static const Color primaryContainer = Color(0xFFF5F3FF);

  // Surface
  static const Color background = Color(0xFFF8F6FF);
  static const Color backgroundLight = background;
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surface = Colors.white;
  static const Color surfaceLight = surface;
  static const Color surfaceDark = Color(0xFF1E1B2E);

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textPrimaryDark = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8E8EA0);
  static const Color textSecondaryDark = Color(0xFFB0B0C8);
  static const Color textOnPrimary = Colors.white;

  // Semantic
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color error = Color(0xFFEF5350);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFFA726);

  // Chat
  static const Color bubbleUser = Color(0xFF8B7BF7);
  static const Color bubbleAi = Colors.white;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A7C6BF5),
      blurRadius: 20,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0x267C6BF5),
      blurRadius: 30,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // Gradients
  static const LinearGradient dreamyBg = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8F6FF), Color(0xFFF0EBFF)],
  );

  static const LinearGradient orbGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC4B5FD), Color(0xFFA78BFA), Color(0xFF8B5CF6), Color(0xFFE0C3FC)],
  );

  static const RadialGradient orbRadial = RadialGradient(
    colors: [Color(0xFFC4B5FD), Color(0xFFA78BFA), Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  );
}
