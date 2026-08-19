import 'package:flutter/material.dart';

/// King Power brand and semantic colour tokens, carried forward from the
/// legacy app's `theme/color.scss` / `theme/variables.scss` (source values
/// noted per token) per design.md's "King Power visual system" decision:
/// gold stays a restrained accent, not the primary text colour, so
/// operational text stays high-contrast — see `contrast.dart` and
/// `app_colors_test.dart` for the accessibility check backing that choice.
abstract class AppColors {
  // Brand gold — legacy `$colors: (primary: #9F8957, darkGold: #654f1c,
  // lightGold: #c0ac7e)`.
  static const goldPrimary = Color(0xFF9F8957);
  static const goldDark = Color(0xFF654F1C);
  static const goldLight = Color(0xFFC0AC7E);

  // Neutrals — legacy `dark: #222`, `lightGrey: #838688`, `light: #f4f4f4`.
  static const textPrimary = Color(0xFF222222);
  static const textSecondary = Color(0xFF5C5F61);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F4F4);
  static const divider = Color(0xFFE6E6E6);

  // Transaction/device-status semantics — legacy `$myColorPallet`
  // (green-complete, red-failed, orange-gold) darkened where needed to
  // clear WCAG AA on white; see app_colors_test.dart.
  static const success = Color(0xFF037A19); // approved / finalized
  static const danger = Color(0xFFB80A23); // declined / failed
  static const warning = Color(
    0xFFA6650A,
  ); // awaiting-device / unresolved / validating / finalizing
  static const info = Color(0xFF024DA1); // draft / informational
  static const neutral = Color(0xFF6B6B6B); // cancelled
}
