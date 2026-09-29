import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/handheld/edit_line_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import 'sale_test_helpers.dart';

void main() {
  late FakeSaleRepository sale;
  late SaleCartViewModel viewModel;

  setUp(() {
    // After a mutation the fake returns the cart with Johnnie removed —
    // enough to observe the page reacting to a changed cart.
    sale = FakeSaleRepository(
      cartResult: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel],
      ),
    );
    viewModel = buildSaleViewModel(sale, cart: sampleCart);
  });

  Future<void> open(WidgetTester tester, {Size size = compactSize}) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openEditLinePage(
                context,
                viewModel: viewModel,
                row: johnnie.row,
                lineNumber: 2,
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

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('shows the line code, description, qty and amounts', (
    tester,
  ) async {
    await open(tester);
    expect(byTestId(EditLineIds.page), findsOneWidget);
    expect(find.text('Order item'), findsOneWidget);
    expect(find.text('Line 2'), findsOneWidget);
    expect(find.text('5000267116419'), findsOneWidget);
    expect(find.text('JOHNNIE WALKER BLUE LABEL 1L'), findsOneWidget);
    expect(textIn(tester, EditLineIds.qtyValue), '2');
    expect(textIn(tester, EditLineIds.netAmount), '฿15,600.00');
  });

  testWidgets('the stepper changes qty locally and previews the amount', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.pump();
    expect(textIn(tester, EditLineIds.qtyValue), '3');
    expect(textIn(tester, EditLineIds.netAmount), '฿23,400.00');
    expect(sale.lastUpdatedQuantity, isNull, reason: 'not saved yet');

    await tester.tap(byTestId(EditLineIds.undoButton));
    await tester.pump();
    expect(textIn(tester, EditLineIds.qtyValue), '2');
  });

  testWidgets('qty cannot go below 1 with the stepper', (tester) async {
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyDecrease));
    await tester.tap(byTestId(EditLineIds.qtyDecrease));
    await tester.pump();
    expect(textIn(tester, EditLineIds.qtyValue), '1');
  });

  testWidgets('Save & close sends the new qty and pops', (tester) async {
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.tap(byTestId(EditLineIds.saveCloseButton));
    await tester.pumpAndSettle();

    expect(sale.lastUpdatedRow, '2');
    expect(sale.lastUpdatedQuantity, 3);
    expect(byTestId(EditLineIds.page), findsNothing);
  });

  testWidgets('Save with no change does not call the backend', (tester) async {
    await open(tester);
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();
    expect(sale.lastUpdatedQuantity, isNull);
    expect(byTestId(EditLineIds.page), findsOneWidget);
  });

  testWidgets('Void line confirms, removes the row and pops', (tester) async {
    await open(tester);
    await tester.ensureVisible(byTestId(EditLineIds.voidButton));
    await tester.tap(byTestId(EditLineIds.voidButton));
    await tester.pumpAndSettle();

    expect(find.text('Void this line?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Void line'));
    await tester.pumpAndSettle();

    expect(sale.lastRemovedRow, '2');
    expect(byTestId(EditLineIds.page), findsNothing);
  });

  testWidgets('serial, freeze, lock and pickup are shown but inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    for (final id in [
      EditLineIds.freezeSwitch,
      EditLineIds.lockDiscountSwitch,
      EditLineIds.pickupCollect,
      EditLineIds.pickupTake,
    ]) {
      await tester.ensureVisible(byTestId(id));
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    final serial = tester.widget<TextField>(
      find.descendant(
        of: byTestId(EditLineIds.serialField),
        matching: find.byType(TextField),
      ),
    );
    expect(serial.enabled, isFalse);
    handle.dispose();
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    expect(byTestId(EditLineIds.saveCloseButton), findsOneWidget);
  });
}
