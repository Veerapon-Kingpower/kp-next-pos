/// 4dp-based spacing scale. The legacy app's own spacing was an unscaled
/// raw-pixel Sass utility loop (0–10, 15), which is CSS/Ionic cruft rather
/// than a deliberate scale — this replaces it with a conventional
/// Material-aligned progression.
abstract class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
