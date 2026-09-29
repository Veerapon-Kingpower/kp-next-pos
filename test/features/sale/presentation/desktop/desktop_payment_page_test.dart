import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_payment_page.dart';

import '../../../../helpers/test_id_finders.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      const MaterialApp(home: DesktopPaymentPage(netPay: 27370)),
    );
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  String tendered(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: byTestId(DesktopPaymentIds.tenderedField),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets('step 3: net pay / tendered / remaining and empty ledger', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(textIn(tester, PaymentIds.netPay), '฿27,370.00');
    expect(textIn(tester, PaymentIds.tendered), '฿0.00');
    expect(textIn(tester, PaymentIds.remaining), '฿27,370.00');
    expect(byTestId(PaymentIds.ledgerEmpty), findsOneWidget);
  });

  testWidgets('Cash is the default method; F-keys switch methods', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('cash'))),
      isSemantics(isSelected: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('card'))),
      isSemantics(isSelected: true),
    );
    expect(
      find.descendant(
        of: byTestId(DesktopPaymentIds.detailPanel),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(byTestId(DesktopPaymentIds.tenderedField), findsOneWidget);
    handle.dispose();
  });

  testWidgets('quick amount previews applied-to-bill and change due', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.quick(30000)));
    await tester.pump();
    expect(tendered(tester), '30000');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿27,370.00');
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿2,630.00');
  });

  testWidgets('Exact tenders the remaining amount with no change', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.exactChip));
    await tester.pump();
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿0.00');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿27,370.00');
  });

  testWidgets('keypad types, 00 appends, backspace deletes', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.keypad('5')));
    await tester.tap(byTestId(DesktopPaymentIds.keypad('00')));
    await tester.tap(byTestId(DesktopPaymentIds.keypad('0')));
    await tester.pump();
    expect(tendered(tester), '5000');
    await tester.tap(byTestId(DesktopPaymentIds.keypadBackspace));
    await tester.pump();
    expect(tendered(tester), '500');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿500.00');
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿0.00');
  });

  testWidgets('only THB is selectable until exchange rates exist', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(DesktopPaymentIds.currency('THB'))),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(byTestId(DesktopPaymentIds.currency('USD'))),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('Add tender, Open drawer and Complete sale are inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      DesktopPaymentIds.addTenderButton,
      DesktopPaymentIds.openDrawerButton,
      PaymentIds.completeSaleButton,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    expect(
      find.text('Complete sale unlocks when remaining hits ฿0.00'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('fits 1024 dp without overflow', (tester) async {
    await pump(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });
}
