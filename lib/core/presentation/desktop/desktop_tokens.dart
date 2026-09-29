import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Dimensions from the POS Desktop mockup
/// (docs/design/pos-desktop/reference/screens/). Desktop layouts also run
/// on iPad landscape, so interactive targets stay ≥ 44 dp.
abstract class DesktopMetrics {
  static const railWidth = 84.0;
  static const topBarHeight = 64.0;
  static const pagePadding = 28.0;
  static const panelRadius = 12.0;
  static const fieldHeight = 56.0;
  static const buttonHeight = 48.0;
  static const largeButtonHeight = 66.0;
}

abstract class DesktopText {
  static const _family = 'KingPowerHeadline';
  static const _tabular = [FontFeature.tabularFigures()];

  static const screenTitle = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const heroTitle = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const panelLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.goldMuted,
  );

  static const fieldLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.mutedText,
  );

  static const kpiValue = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFeatures: _tabular,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}
