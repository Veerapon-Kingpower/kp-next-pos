/// Sizing tokens shared by both platform layouts (task 3.4 builds the
/// actual responsive Android touch-first / Windows keyboard-and-scanner
/// layouts on top of these).
abstract class AppSizing {
  /// Minimum interactive touch target — Material accessibility guideline.
  static const touchTargetMin = 48.0;

  static const controlHeight = 48.0;
  static const iconSize = 24.0;
  static const iconSizeLarge = 32.0;

  static const cornerRadiusSm = 4.0;
  static const cornerRadiusMd = 8.0;
  static const cornerRadiusLg = 16.0;
}
