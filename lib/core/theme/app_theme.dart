import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_sizing.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// King Power theme: navy chrome (app shell, header, navigation) with gold
/// reserved for primary actions and highlights — see `app_colors.dart` and
/// its accessibility test for the reasoning. Primary-action colour lives on
/// [AppPrimaryButton] itself (gold background needs a dark, not white,
/// foreground to clear WCAG AA — see `app_colors_test.dart`), not on
/// `colorScheme.primary`/`onPrimary`, so it doesn't leak into
/// [AppDestructiveButton]'s own explicit-background styling.
abstract class AppTheme {
  static ThemeData light() {
    final colorScheme = const ColorScheme.light().copyWith(
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.goldAccent,
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
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        titleTextStyle: AppTypography.textTheme(Colors.white).titleLarge,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.navyLight,
        selectedIconTheme: const IconThemeData(color: AppColors.goldAccent),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.goldAccent,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: const IconThemeData(color: Colors.white70),
        unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.navy,
        indicatorColor: AppColors.navyLight,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.goldAccent
                : Colors.white70,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.goldAccent
                : Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
      // Filled and outlined buttons share one fully-rounded (stadium) shape
      // — declared explicitly on both rather than left to each widget's
      // Material 3 default, so a primary/destructive action never
      // mismatches its paired secondary action (e.g. a confirm dialog's
      // Confirm/Cancel pair) regardless of future default changes.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizing.controlHeight),
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
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
