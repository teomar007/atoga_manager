import 'package:flutter/material.dart';

/// لوحة ألوان ATOGA MANAGER — تركوازية (#107275) في الوضعين.
abstract final class AppColors {
  const AppColors._();

  // Brand (teal)
  static const Color primary = Color(0xFF107275);
  static const Color primaryDark = Color(0xFF0B5759);
  static const Color primaryLight = Color(0xFF2E9A9C);
  static const Color accent = Color(0xFFFFB300);

  // Surfaces (light)
  static const Color background = Color(0xFFF6F8F8);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFEDF3F3);
  static const Color divider = Color(0xFFDCE5E5);

  // Text (light)
  static const Color textPrimary = Color(0xFF1B2424);
  static const Color textSecondary = Color(0xFF5C6B6B);
  static const Color textDisabled = Color(0xFFA9B6B6);

  // Surfaces (dark)
  static const Color darkBackground = Color(0xFF0E1415);
  static const Color darkSurface = Color(0xFF1A2223);
  static const Color darkSurfaceMuted = Color(0xFF232D2E);
  static const Color darkDivider = Color(0xFF2E3A3B);

  // Text (dark)
  static const Color darkTextPrimary = Color(0xFFECEFF1);
  static const Color darkTextSecondary = Color(0xFF9FB0B0);

  // Semantic
  static const Color success = Color(0xFF15A05A);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFE53935);
  static const Color info = Color(0xFF2F80ED);
  static const Color onPrimary = Colors.white;
}
