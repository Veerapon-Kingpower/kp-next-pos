import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds the widget wrapped in `TestId(id, ...)` via its `ValueKey`.
Finder byTestId(String id) => find.byKey(ValueKey<String>(id));

/// Pumps [surface] at a device size, resetting the view after the test.
///
/// Sizes used across handheld tests: compact `Size(400, 860)` (Sunmi V2),
/// medium `Size(820, 1180)` (iPad Air portrait), expanded
/// `Size(1180, 820)` (iPad Air landscape).
void setDeviceSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

const compactSize = Size(400, 860);
const mediumSize = Size(820, 1180);
const expandedSize = Size(1180, 820);
