import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/test_id.dart';

import '../../../helpers/test_id_finders.dart';
import '../../../helpers/test_app.dart';

void main() {
  testWidgets('TestId exposes both a ValueKey and a semantics identifier', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: TestId(
            'demo.button',
            child: ElevatedButton(
              onPressed: () => taps++,
              child: const Text('Go'),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('demo.button')), findsOneWidget);
    expect(find.bySemanticsIdentifier('demo.button'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('demo.button')));
    expect(taps, 1);
    handle.dispose();
  });

  testWidgets('byTestId finder helper matches the key', (tester) async {
    await tester.pumpWidget(
      TestApp(home: TestId('demo.label', child: Text('Hi'))),
    );
    expect(byTestId('demo.label'), findsOneWidget);
  });
}
