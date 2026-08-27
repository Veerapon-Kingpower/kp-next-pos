import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/theme/app_typography.dart';

void main() {
  group('desktopTextTheme', () {
    test('pairs KingPowerHeadline for headline styles', () {
      final theme = AppTypography.desktopTextTheme(Colors.black);

      expect(theme.displayLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.headlineLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.headlineMedium?.fontFamily, 'KingPowerHeadline');
      expect(theme.titleLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.titleMedium?.fontFamily, 'KingPowerHeadline');
    });

    test('pairs KingPowerText for body/label styles', () {
      final theme = AppTypography.desktopTextTheme(Colors.black);

      expect(theme.bodyLarge?.fontFamily, 'KingPowerText');
      expect(theme.bodyMedium?.fontFamily, 'KingPowerText');
      expect(theme.bodySmall?.fontFamily, 'KingPowerText');
      expect(theme.labelLarge?.fontFamily, 'KingPowerText');
      expect(theme.labelMedium?.fontFamily, 'KingPowerText');
    });

    test('applies the given color to every style except bodySmall', () {
      final theme = AppTypography.desktopTextTheme(Colors.red);

      expect(theme.displayLarge?.color, Colors.red);
      expect(theme.bodyLarge?.color, Colors.red);
      // bodySmall always uses AppColors.textSecondary, matching textTheme()'s
      // existing behavior — not the passed-in color.
      expect(theme.bodySmall?.color, isNot(Colors.red));
    });

    test('does not change the existing single-family textTheme', () {
      final theme = AppTypography.textTheme(Colors.black);

      expect(theme.displayLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.bodyLarge?.fontFamily, 'KingPowerHeadline');
      expect(theme.displayLarge?.fontWeight, FontWeight.w900);
    });
  });
}
