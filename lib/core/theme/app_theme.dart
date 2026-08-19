import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizing.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// King Power theme: brand gold as a restrained accent (buttons, active
/// states) on neutral surfaces, with high-contrast text — see
/// `app_colors.dart` and its accessibility test for the reasoning.
abstract class AppTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.goldDark,
      onPrimary: Colors.white,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.textPrimary,
      error: AppColors.danger,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.surfaceAlt,
      textTheme: AppTypography.textTheme(AppColors.textPrimary),
      dividerColor: AppColors.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: Colors.white,
        titleTextStyle: AppTypography.textTheme(Colors.white).titleLarge,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizing.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizing.cornerRadiusMd),
        ),
        margin: const EdgeInsets.all(AppSpacing.xs),
      ),
    );
  }
}
