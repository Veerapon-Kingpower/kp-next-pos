import 'package:flutter/widgets.dart';

/// Stable automation hook for a widget (handheld spec decision 6).
///
/// Applies [id] twice: as a `ValueKey<String>` so widget tests can
/// `find.byKey`, and as a [Semantics.identifier] so device automation can
/// target it — Flutter maps the identifier to Android's `resource-id` and
/// iOS's `accessibilityIdentifier` (Appium / Maestro). The identifier is not
/// read aloud by screen readers, so it never replaces a real label.
///
/// Use constants from `test_ids.dart`, never string literals.
class TestId extends StatelessWidget {
  final String id;
  final Widget child;

  const TestId(this.id, {super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: id,
      container: true,
      child: KeyedSubtree(key: ValueKey<String>(id), child: child),
    );
  }
}
