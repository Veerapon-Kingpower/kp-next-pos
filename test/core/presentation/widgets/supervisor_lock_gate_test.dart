import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/supervisor_lock_gate.dart';

void main() {
  testWidgets('shows the lock message and hides child when locked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: true,
            onUnlock: () {},
            child: const Text('terminal settings form'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('supervisorUnlockButton')), findsOneWidget);
    expect(find.text('terminal settings form'), findsNothing);
  });

  testWidgets('shows child directly when unlocked', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: false,
            onUnlock: () {},
            child: const Text('terminal settings form'),
          ),
        ),
      ),
    );

    expect(find.text('terminal settings form'), findsOneWidget);
    expect(find.byKey(const Key('supervisorUnlockButton')), findsNothing);
  });

  testWidgets('tapping Unlock invokes onUnlock', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SupervisorLockGate(
            locked: true,
            onUnlock: () => unlocked = true,
            child: const Text('form'),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('supervisorUnlockButton')));
    await tester.pump();

    expect(unlocked, isTrue);
  });
}
