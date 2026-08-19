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
    'white text on goldPrimary meets WCAG AA for large text only (button/banner use, not body text)',
    () {
      const white = Color(0xFFFFFFFF);
      final ratio = contrastRatio(white, AppColors.goldPrimary);
      expect(
        meetsAAForLargeText(white, AppColors.goldPrimary),
        isTrue,
        reason: '$ratio:1 (need >= 3.0:1)',
      );
    },
  );
}
