import 'package:flutter/widgets.dart';

/// Width breakpoint separating the two responsive layout modes from
/// design.md: **Android touch-first** (compact bottom navigation) below the
/// breakpoint, **Windows keyboard/scanner-first** (persistent navigation
/// rail, multi-column working areas) at or above it.
///
/// Deliberately width-based rather than a platform check — an Android
/// tablet in landscape gets the same wide layout a small Windows window
/// would, and a narrow Windows window (if ever resized small) falls back to
/// the compact layout. This matches the spec's "responsive Android/Windows
/// layouts" requirement without hard-coding platform assumptions that break
/// on unusual window sizes. Value matches Material's medium/expanded
/// breakpoint (840dp) so it composes with other Material-aware widgets.
abstract class AppBreakpoints {
  static const wide = 840.0;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;
}
