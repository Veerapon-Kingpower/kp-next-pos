import 'package:flutter/widgets.dart';

/// Width classes from the handheld spec
/// (docs/superpowers/specs/2026-09-29-pos-handheld-design.md, decision 5):
/// **compact** — phones and the Sunmi handheld, the handheld design as drawn;
/// **medium** — tablets / iPads in portrait, the handheld design widened;
/// **expanded** — iPad landscape, iPad Pro 12.9 portrait and Windows, the
/// desktop design.
enum AppSizeClass { compact, medium, expanded }

/// Width breakpoints separating the responsive layout modes: the
/// **handheld touch-first** layout (bottom navigation) below [wide], the
/// **keyboard/scanner-first desktop** layout (persistent navigation rail,
/// multi-column working areas) at or above it.
///
/// Deliberately width-based rather than a platform check — an Android
/// tablet in landscape gets the same wide layout a small Windows window
/// would, and a narrow Windows window (if ever resized small) falls back to
/// the compact layout. This matches the spec's "responsive Android/Windows
/// layouts" requirement without hard-coding platform assumptions that break
/// on unusual window sizes. Values match Material's window size classes
/// (600dp / 840dp) so they compose with other Material-aware widgets.
abstract class AppBreakpoints {
  /// Lower bound of [AppSizeClass.medium].
  static const medium = 600.0;

  /// Lower bound of [AppSizeClass.expanded] — the desktop layout.
  static const wide = 840.0;

  static const sizeClassExpandedMin = wide;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  static AppSizeClass sizeClassForWidth(double width) {
    if (width >= wide) return AppSizeClass.expanded;
    if (width >= medium) return AppSizeClass.medium;
    return AppSizeClass.compact;
  }

  static AppSizeClass sizeClass(BuildContext context) =>
      sizeClassForWidth(MediaQuery.sizeOf(context).width);
}
