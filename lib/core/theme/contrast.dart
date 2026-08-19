import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG 2.1 relative luminance and contrast ratio, used to verify token
/// pairs meet the `pos-sales-workflows` spec's "accessible text contrast"
/// requirement rather than approving colours by eye.
double relativeLuminance(Color color) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// WCAG contrast ratio between two colours, in the range [1, 21].
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a) + 0.05;
  final lb = relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

/// WCAG AA thresholds: 4.5:1 for normal text, 3:1 for large text (≥18pt, or
/// ≥14pt bold) and for non-text UI elements.
bool meetsAAForNormalText(Color foreground, Color background) =>
    contrastRatio(foreground, background) >= 4.5;

bool meetsAAForLargeText(Color foreground, Color background) =>
    contrastRatio(foreground, background) >= 3.0;
