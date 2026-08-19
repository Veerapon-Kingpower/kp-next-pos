import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_card.dart';

void main() {
  testWidgets('renders its child and invokes onTap when tapped', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('Order #1'),
          ),
        ),
      ),
    );

    expect(find.text('Order #1'), findsOneWidget);

    await tester.tap(find.text('Order #1'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('is not tappable when onTap is omitted', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppCard(child: Text('Static content'))),
      ),
    );

    expect(find.byType(InkWell), findsNothing);
  });
}
