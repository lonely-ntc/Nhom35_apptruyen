import 'package:flutter/material.dart';

/// 📐 APP STYLES & CONSTANTS
class AppStyles {
  // Spacing
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXXLarge = 24.0;
  static const double radiusCircle = 999.0;

  // Shadows
  static BoxShadow shadowSmall = BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 5,
    offset: const Offset(0, 2),
  );

  static BoxShadow shadowMedium = BoxShadow(
    color: Colors.black.withOpacity(0.1),
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static BoxShadow shadowLarge = BoxShadow(
    color: Colors.black.withOpacity(0.15),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );

  static BoxShadow shadowXLarge = BoxShadow(
    color: Colors.black.withOpacity(0.2),
    blurRadius: 30,
    offset: const Offset(0, 12),
  );

  // Colored Shadows
  static BoxShadow purpleShadow = BoxShadow(
    color: const Color(0xFF6A5AE0).withOpacity(0.3),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  static BoxShadow blueShadow = BoxShadow(
    color: const Color(0xFF4A90E2).withOpacity(0.3),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  static BoxShadow pinkShadow = BoxShadow(
    color: const Color(0xFFE91E63).withOpacity(0.3),
    blurRadius: 20,
    offset: const Offset(0, 10),
  );

  // Typography
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  static const TextStyle heading4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.3,
  );

  static TextStyle caption = TextStyle(
    fontSize: 12,
    color: Colors.grey.shade600,
  );

  // Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Curves
  static const Curve curveDefault = Curves.easeInOut;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveSpring = Curves.elasticOut;
}
