import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/signature_page.dart';

import '../../../../../helpers/test_id_finders.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  SignatureCapture? result;
  var popped = false;

  Future<void> open(WidgetTester tester, {Size size = compactSize}) async {
    result = null;
    popped = false;
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await openSignaturePage(context, netPay: 87370);
                popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> sign(WidgetTester tester, String padId) async {
    final center = tester.getCenter(byTestId(padId));
    await tester.dragFrom(center - const Offset(60, 0), const Offset(120, 10));
    await tester.pump();
  }

  String status(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('shows net pay and two empty pads', (tester) async {
    await open(tester);
    expect(byTestId(SignatureIds.page), findsOneWidget);
    expect(find.text('฿87,370.00'), findsOneWidget);
    expect(status(tester, SignatureIds.paidByStatus), 'Empty — pad ready');
    expect(status(tester, SignatureIds.customerStatus), 'Empty — pad ready');
  });

  testWidgets('one Save only — the bottom Save signature', (tester) async {
    await open(tester);
    expect(byTestId(SignatureIds.saveButton), findsNothing);
    expect(byTestId(SignatureIds.bottomSaveButton), findsOneWidget);
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('drawing on a pad marks it captured; Clear resets it', (
    tester,
  ) async {
    await open(tester);
    await sign(tester, SignatureIds.customerPad);
    expect(status(tester, SignatureIds.customerStatus), 'Captured');

    await tester.tap(byTestId(SignatureIds.customerClear));
    await tester.pump();
    expect(status(tester, SignatureIds.customerStatus), 'Empty — pad ready');
  });

  testWidgets('Save stays disabled until the customer has signed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    await sign(tester, SignatureIds.paidByPad);
    expect(
      tester.getSemantics(byTestId(SignatureIds.bottomSaveButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );

    await sign(tester, SignatureIds.customerPad);
    expect(
      tester.getSemantics(byTestId(SignatureIds.bottomSaveButton)),
      isSemantics(hasEnabledState: true, isEnabled: true),
    );
    handle.dispose();
  });

  testWidgets('Save returns both captures to the caller', (tester) async {
    await open(tester);
    await sign(tester, SignatureIds.customerPad);
    await tester.tap(byTestId(SignatureIds.bottomSaveButton));
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expect(result, isNotNull);
    expect(result!.customer, isNotEmpty);
    expect(result!.paidBy, isEmpty, reason: 'optional pad left blank');
  });

  testWidgets('Cancel returns nothing', (tester) async {
    await open(tester);
    await sign(tester, SignatureIds.customerPad);
    await tester.tap(byTestId(SignatureIds.cancelButton));
    await tester.pumpAndSettle();
    expect(popped, isTrue);
    expect(result, isNull);
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    expect(byTestId(SignatureIds.customerPad), findsOneWidget);
  });
}
