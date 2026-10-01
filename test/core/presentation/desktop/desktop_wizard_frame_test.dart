import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/desktop/desktop.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/theme/app_colors.dart';

import '../../../helpers/test_id_finders.dart';
import '../../../helpers/test_app.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    setDeviceSize(tester, const Size(1440, 900));
    await tester.pumpWidget(
      TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DesktopWizardFrame(
                    title: 'Checkout',
                    subtitle: '2 lines · walk-in',
                    step: 2,
                    totalSteps: 3,
                    escapeLabel: 'Esc to return to sale',
                    body: Text('body'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('ink bar with title, step pills and the Esc hint', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('2 lines · walk-in'), findsOneWidget);
    expect(
      find.descendant(
        of: byTestId(DesktopPaymentIds.wizardSteps),
        matching: find.text('Step 2 of 3'),
      ),
      findsOneWidget,
    );
    final bar = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.text('Checkout'),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(bar.color, AppColors.ink);
    expect(find.text('body'), findsOneWidget);
  });

  testWidgets('Esc key and the Esc chip both go back', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(DesktopPaymentIds.wizardEscape));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
