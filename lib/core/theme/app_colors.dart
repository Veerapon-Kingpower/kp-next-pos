import 'package:flutter/material.dart';

/// King Power brand and semantic colour tokens per design.md's "King Power
/// visual system" decision: a navy-and-gold two-tone rebrand, superseding
/// the original all-neutral-with-restrained-gold system. Navy is the
/// dominant chrome colour (app shell, navigation, header); gold is an
/// accent reserved for primary actions and membership/status highlights,
/// never used as body text colour. See `contrast.dart` and
/// `app_colors_test.dart` for the WCAG AA checks backing every pairing —
/// `goldAccent` in particular is light enough that it needs a dark
/// foreground, not white, wherever it carries text.
abstract class AppColors {
  // Brand navy — primary chrome colour.
  static const navy = Color(0xFF0A192F);
  static const navyLight = Color(0xFF1B3A63); // selected/hover nav state

  // Brand gold — accent for primary actions (e.g. Pay Now) and
  // membership/status highlights. `goldDark`/`goldLight` are the legacy
  // gold family, kept for decorative tints that don't carry text.
  static const goldAccent = Color(0xFFC5A059);
  static const goldDark = Color(0xFF654F1C);
  static const goldLight = Color(0xFFC0AC7E);

  // Handheld layout (below AppBreakpoints.wide) — warm near-black chrome
  // with a brighter gold, per the POS handheld mockup
  // (docs/superpowers/specs/2026-09-29-pos-handheld-design.md). The desktop
  // layout keeps navy. `gold` carries `ink` text, never white.
  static const ink = Color(0xFF191712);
  static const gold = Color(0xFFC8A04B);
  static const goldMuted = Color(0xFF9F8957);
  static const cream = Color(0xFFFBF8F1);
  static const line = Color(0xFFE4E8EE);
  static const mutedText = Color(
    0xFF626B77,
  ); // mockup #6B7480, darkened for AA on canvas
  // Placeholder / decorative only — below AA for body text.
  static const hintText = Color(0xFF9AA2AE);
  static const online = Color(0xFF1DB87A); // status dot
  static const onlineOnInk = Color(0xFF5BD9A4); // status text on ink

  // Neutrals.
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF5C5F61);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF4F6F9);
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
