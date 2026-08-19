import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/unavailable_state_view.dart';

void main() {
  testWidgets(
    'shows title and message, and hides the retry button when none is provided',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: UnavailableStateView(
            title: 'No connection',
            message: 'Check the network and try again.',
          ),
        ),
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Check the network and try again.'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    },
  );

  testWidgets('shows and invokes the retry action when provided', (
    tester,
  ) async {
    var retried = false;

    await tester.pumpWidget(
      MaterialApp(
        home: UnavailableStateView(
          title: 'Printer unavailable',
          message: 'Reconnect the printer to continue.',
          onRetry: () => retried = true,
        ),
      ),
    );

    await tester.tap(find.text('Try again'));
    await tester.pump();

    expect(retried, isTrue);
  });
}
