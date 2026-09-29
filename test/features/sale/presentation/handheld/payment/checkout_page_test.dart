import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/checkout_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../../helpers/test_id_finders.dart';
import '../../../fake_sale_repository.dart';
import '../sale_test_helpers.dart';

void main() {
  Future<SaleCartViewModel> pump(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Privilege? privilege,
    Size size = compactSize,
  }) async {
    setDeviceSize(tester, size);
    final viewModel = buildSaleViewModel(FakeSaleRepository(), cart: cart);
    viewModel.selectedPrivilege = privilege;
    await tester.pumpWidget(
      MaterialApp(home: CheckoutPage(viewModel: viewModel)),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('header shows lines, units and net pay from the cart', (
    tester,
  ) async {
    await pump(tester);
    expect(byTestId(CheckoutIds.page), findsOneWidget);
    expect(find.text('2 lines · 3 units'), findsOneWidget);
    expect(textIn(tester, CheckoutIds.netPay), '฿21,500.00');
  });

  testWidgets('amounts: real total / grand, unknown breakdown as —', (
    tester,
  ) async {
    await pump(tester);
    expect(textIn(tester, CheckoutIds.totalAmount), '21,500.00');
    expect(textIn(tester, CheckoutIds.grandAmount), '21,500.00');
    final amounts = byTestId(CheckoutIds.amountsCard);
    expect(
      find.descendant(of: amounts, matching: find.text('—')),
      findsNWidgets(3),
      reason: 'discount, Cash-D subsidy, VAT',
    );
  });

  testWidgets('pre-checkout flags are not claimed as cleared', (tester) async {
    await pump(tester);
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.flagsNotice),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('All flags cleared'), findsNothing);
  });

  testWidgets('customer card: walk-in without a privilege', (tester) async {
    await pump(tester);
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.customerCard),
        matching: find.text('Walk-in · no customer attached'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('customer card shows the selected privilege', (tester) async {
    await pump(
      tester,
      privilege: const Privilege(
        name: 'Gold Member',
        discount: 10,
        typeCode: 'VIP',
        promoCode: 'PROMO123',
      ),
    );
    final card = byTestId(CheckoutIds.customerCard);
    expect(
      find.descendant(of: card, matching: find.text('Gold Member')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('[VIP]:PROMO123')),
      findsOneWidget,
    );
  });

  testWidgets('Take payment opens Payment with the net pay', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(CheckoutIds.takePaymentButton));
    await tester.pumpAndSettle();
    expect(byTestId(PaymentIds.page), findsOneWidget);
    expect(
      find.descendant(
        of: byTestId(PaymentIds.netPay),
        matching: find.text('฿21,500.00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('signature: capture on the pad, then shown as captured', (
    tester,
  ) async {
    await pump(tester);
    expect(
      find.descendant(
        of: byTestId(CheckoutIds.signatureRow),
        matching: find.text('Not captured'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(byTestId(CheckoutIds.signatureRow));
    await tester.tap(byTestId(CheckoutIds.signatureRow));
    await tester.pumpAndSettle();

    final pad = tester.getCenter(byTestId(SignatureIds.customerPad));
    await tester.dragFrom(pad - const Offset(60, 0), const Offset(120, 8));
    await tester.pump();
    await tester.tap(byTestId(SignatureIds.bottomSaveButton));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: byTestId(CheckoutIds.signatureRow),
        matching: find.text('Captured · not uploaded yet'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Suspend and Print quote are inert', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
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
    handle.dispose();
  });

  testWidgets('an empty bill cannot take payment', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, cart: null);
    expect(
      tester.getSemantics(byTestId(CheckoutIds.takePaymentButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await pump(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
  });
}
