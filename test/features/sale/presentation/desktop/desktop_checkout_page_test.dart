import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_checkout_page.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Privilege? privilege,
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    final viewModel = buildSaleViewModel(FakeSaleRepository(), cart: cart);
    viewModel.selectedPrivilege = privilege;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  openDesktopCheckoutPage(context, viewModel: viewModel),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('step 2 of 3, read-only lines and amount due', (tester) async {
    await open(tester);
    expect(byTestId(CheckoutIds.page), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('2 lines · 3 units'), findsOneWidget);
    final table = byTestId(DesktopPaymentIds.linesTable);
    expect(
      find.descendant(
        of: table,
        matching: find.text('JOHNNIE WALKER BLUE LABEL 1L'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: table, matching: find.text('15,600.00')),
      findsOneWidget,
    );
    expect(textIn(tester, CheckoutIds.totalAmount), '21,500.00');
    expect(textIn(tester, CheckoutIds.grandAmount), '21,500.00');
    expect(textIn(tester, CheckoutIds.netPay), '฿21,500.00');
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.amountsCard),
        matching: find.text('—'),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('flags / flight are reported as unavailable, not cleared', (
    tester,
  ) async {
    await open(tester);
    expect(find.textContaining('All blocking flags cleared'), findsNothing);
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.flagsNotice),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: byTestId(DesktopPaymentIds.flightCard),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('customer: walk-in, or the selected privilege', (tester) async {
    await open(tester);
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.customerCard),
        matching: find.text('Walk-in · no customer attached'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('customer card shows the selected privilege', (tester) async {
    await open(
      tester,
      privilege: const Privilege(
        name: 'Gold Member',
        discount: 10,
        typeCode: 'VIP',
        promoCode: 'P1',
      ),
    );
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.customerCard),
        matching: find.text('[VIP]:P1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Take payment (button or Enter) opens step 3', (tester) async {
    await open(tester);
    await tester.tap(byTestId(CheckoutIds.takePaymentButton));
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Step 3 of 3'), findsOneWidget);
  });

  testWidgets('Esc returns to the sale', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('signature box opens the pad; Suspend / Print quote inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    for (final id in [
      CheckoutIds.suspendButton,
      CheckoutIds.printQuoteButton,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    await tester.tap(byTestId(DesktopPaymentIds.signatureBox));
    await tester.pumpAndSettle();
    expect(byTestId(SignatureIds.page), findsOneWidget);
    handle.dispose();
  });

  testWidgets('an empty bill cannot take payment', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, cart: null);
    expect(
      tester.getSemantics(byTestId(CheckoutIds.takePaymentButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('fits 1024 dp without overflow', (tester) async {
    await open(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });
}
