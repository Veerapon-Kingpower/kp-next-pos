import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/widgets/app_dialogs.dart';

void main() {
  testWidgets('resolves true when the confirm action is tapped', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => _TriggerButton(
              onTap: () async {
                result = await showAppConfirmationDialog(
                  context,
                  title: 'Cancel sale?',
                  message: 'This cannot be undone.',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel sale?'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('resolves false when cancel is tapped', (tester) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => _TriggerButton(
              onTap: () async {
                result = await showAppConfirmationDialog(
                  context,
                  title: 'Void payment?',
                  message: 'This cannot be undone.',
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('trigger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}

class _TriggerButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _TriggerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onTap, child: const Text('trigger'));
  }
}
