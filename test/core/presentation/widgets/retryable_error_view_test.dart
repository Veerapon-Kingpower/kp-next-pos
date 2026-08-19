import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/retryable_error_view.dart';

void main() {
  testWidgets('shows the message and invokes onRetry when tapped', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: RetryableErrorView(
          message: 'Could not load the order.',
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Could not load the order.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
