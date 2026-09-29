import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// Dimensions and text styles shared by the handheld kit, taken from the
/// POS handheld mockup (docs/design/pos-handheld/reference/screens/). Kept
/// here rather than in `AppSizing` because they only apply below
/// `AppBreakpoints.wide`.
abstract class HandheldMetrics {
  static const pagePadding = 20.0;
  static const primaryActionHeight = 56.0;
  static const scanFieldHeight = 62.0;
  static const tileHeight = 84.0;
  static const navBarHeight = 76.0;
  static const navItemHeight = 60.0;
  static const radius = 10.0;
  static const radiusSm = 9.0;
  static const sheetRadius = 18.0;

  /// Medium size class: page content is centred at this width.
  static const mediumContentMaxWidth = 720.0;

  /// Medium size class: sheets render as dialogs this wide.
  static const mediumSheetMaxWidth = 560.0;
}

abstract class HandheldText {
  static const _family = 'KingPowerHeadline';
  static const _tabular = [FontFeature.tabularFigures()];

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 19,
    fontWeight: FontWeight.w700,
  );

  static const displayTitle = TextStyle(
    fontFamily: _family,
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );

  static const sectionTitle = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  /// Caps micro-label above a stat or field (`9.5–10.5px`, tracked).
  static const overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.0,
  );

  static const statValue = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
  );

  static const body = TextStyle(fontSize: 14.5, color: AppColors.textPrimary);

  static const bodySmall = TextStyle(
    fontSize: 12.5,
    color: AppColors.mutedText,
  );

  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w700);

  static const tabular = TextStyle(fontFeatures: _tabular);
}
