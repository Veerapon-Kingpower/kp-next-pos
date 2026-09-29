import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/theme/app_colors.dart';
import 'package:kp_pos/core/theme/contrast.dart';

void main() {
  group('text-on-surface pairs meet WCAG AA for normal text (>=4.5:1)', () {
    final textOnSurfacePairs = {
      'textPrimary on surface': (AppColors.textPrimary, AppColors.surface),
      'textPrimary on surfaceAlt': (
        AppColors.textPrimary,
        AppColors.surfaceAlt,
      ),
      'textSecondary on surface': (AppColors.textSecondary, AppColors.surface),
      'goldDark on surface': (AppColors.goldDark, AppColors.surface),
      'success on surface': (AppColors.success, AppColors.surface),
      'danger on surface': (AppColors.danger, AppColors.surface),
      'warning on surface': (AppColors.warning, AppColors.surface),
      'info on surface': (AppColors.info, AppColors.surface),
      'neutral on surface': (AppColors.neutral, AppColors.surface),
    };

    for (final entry in textOnSurfacePairs.entries) {
      test(entry.key, () {
        final (fg, bg) = entry.value;
        final ratio = contrastRatio(fg, bg);
        expect(
          meetsAAForNormalText(fg, bg),
          isTrue,
          reason: '$ratio:1 (need >= 4.5:1)',
        );
      });
    }
  });

  test(
    'textPrimary on goldAccent meets WCAG AA for normal text (button/badge use)',
    () {
      final ratio = contrastRatio(AppColors.textPrimary, AppColors.goldAccent);
      expect(
        meetsAAForNormalText(AppColors.textPrimary, AppColors.goldAccent),
        isTrue,
        reason: '$ratio:1 (need >= 4.5:1)',
      );
    },
  );

  group('handheld pairs meet WCAG AA for normal text (>=4.5:1)', () {
    const white = Color(0xFFFFFFFF);
    final pairs = {
      'white on ink (handheld header)': (white, AppColors.ink),
      'ink on gold (handheld primary action)': (AppColors.ink, AppColors.gold),
      'gold on ink (accent text on dark)': (AppColors.gold, AppColors.ink),
      'mutedText on surface': (AppColors.mutedText, AppColors.surface),
      'mutedText on canvas': (AppColors.mutedText, AppColors.surfaceAlt),
      'goldDark on cream (selected nav / hint strip)': (
        AppColors.goldDark,
        AppColors.cream,
      ),
      'onlineOnInk on ink (status text)': (
        AppColors.onlineOnInk,
        AppColors.ink,
      ),
    };

    for (final entry in pairs.entries) {
      test(entry.key, () {
        final (fg, bg) = entry.value;
        final ratio = contrastRatio(fg, bg);
        expect(
          meetsAAForNormalText(fg, bg),
          isTrue,
          reason: '$ratio:1 (need >= 4.5:1)',
        );
      });
    }
  });

  test('white text on navy meets WCAG AA for normal text (header/nav use)', () {
    const white = Color(0xFFFFFFFF);
    final ratio = contrastRatio(white, AppColors.navy);
    expect(
      meetsAAForNormalText(white, AppColors.navy),
      isTrue,
      reason: '$ratio:1 (need >= 4.5:1)',
    );
  });
}
