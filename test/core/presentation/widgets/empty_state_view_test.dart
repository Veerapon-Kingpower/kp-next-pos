import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/empty_state_view.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('shows the message and an optional action', (tester) async {
    await tester.pumpWidget(
      TestApp(home: EmptyStateView(message: 'No orders found')),
    );
    expect(find.text('No orders found'), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);

    await tester.pumpWidget(
      TestApp(
        home: EmptyStateView(
          message: 'No orders found',
          action: TextButton(onPressed: () {}, child: const Text('Retry')),
        ),
      ),
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}
