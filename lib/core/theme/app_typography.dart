import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale using King Power's approved typeface (see `app_theme.md`
/// note in `app_colors.dart` — `KingPowerHeadline` is the legacy app's sole
/// active font family; sizes here are a clean modern scale rather than a
/// literal port of the legacy app's ad hoc rem-based utility classes, which
/// were Ionic/CSS artifacts rather than a deliberate type scale.
abstract class AppTypography {
  static const _fontFamily = 'KingPowerHeadline';

  static TextTheme textTheme(Color color) => TextTheme(
    displayLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 40,
      fontWeight: FontWeight.w900,
      color: color,
    ),
    headlineLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    headlineMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    titleLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    titleMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: color,
    ),
    bodyLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    bodyMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: color,
    ),
    labelLarge: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    labelMedium: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: color,
    ),
    bodySmall: TextStyle(
      fontFamily: _fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
  );
}
