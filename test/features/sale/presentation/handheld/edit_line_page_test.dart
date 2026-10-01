import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/presentation/handheld/edit_line_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import 'sale_test_helpers.dart';
import '../../../../helpers/test_app.dart';

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
      TestApp(
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

  bool saveEnabled(WidgetTester tester) => tester
      .widget<ButtonStyleButton>(
        find.descendant(
          of: byTestId(EditLineIds.saveButton),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
      )
      .enabled;

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
    // Legacy shows Serial No only when the article requires one.
    expect(byTestId(EditLineIds.serialField), findsNothing);
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

  testWidgets('Save & close sends every Edit Detail value and pops', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.tap(byTestId(EditLineIds.saveCloseButton));
    await tester.pumpAndSettle();

    final sent = sale.lineEdits.single;
    expect(sent.row, '2');
    expect(sent.edit.quantity, 3);
    expect(sent.edit.isFreeze, isFalse);
    expect(sent.edit.isLockDiscount, isFalse);
    expect(sent.edit.collectStatus, '');
    expect(sent.edit.serialNo, '');
    expect(byTestId(EditLineIds.page), findsNothing);
  });

  testWidgets('nothing changed: Save is disabled, Save & close just closes', (
    tester,
  ) async {
    await open(tester);
    expect(saveEnabled(tester), isFalse);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
    await tester.tap(byTestId(EditLineIds.qtyDecrease));
    await tester.pump();
    expect(saveEnabled(tester), isFalse, reason: 'back to the saved value');

    await tester.tap(byTestId(EditLineIds.saveCloseButton));
    await tester.pumpAndSettle();
    expect(sale.lineEdits, isEmpty);
    expect(byTestId(EditLineIds.page), findsNothing);
  });

  testWidgets('a change enables Save; Save calls the backend and stays', (
    tester,
  ) async {
    // The saved line comes back in the returned order.
    sale = FakeSaleRepository(cartResult: sampleCart);
    viewModel = buildSaleViewModel(sale, cart: sampleCart);
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.pump();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();
    expect(sale.lineEdits.single.edit.quantity, 3);
    expect(byTestId(EditLineIds.page), findsOneWidget);
  });

  CartItem watch({String cites = '', List<VasItem> vas = const []}) => CartItem(
    row: '2',
    articleCode: '5000267116419',
    articleName: 'WATCH',
    quantity: 1,
    unitPrice: 9000,
    lineTotal: 9000,
    requireSerial: true,
    cites: cites,
    citesPermitNo: cites.isEmpty ? '' : 'P-77',
    vasItems: vas,
  );

  Finder serialField() => find.descendant(
    of: byTestId(EditLineIds.serialField),
    matching: find.byType(TextField),
  );

  testWidgets('a serial scan over 20 characters is looked up', (tester) async {
    sale.serialResult = 'SN-REAL-1';
    viewModel = buildSaleViewModel(
      sale,
      cart: Cart(guid: 'order-1', isCheckOut: false, items: [watch()]),
    );
    await open(tester);
    await tester.enterText(serialField(), '012345678901234567890123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(sale.serialLookups.single.barcode, '012345678901234567890123');
    expect(
      tester.widget<TextField>(serialField()).controller!.text,
      'SN-REAL-1',
    );
  });

  testWidgets('a short serial is kept as typed', (tester) async {
    viewModel = buildSaleViewModel(
      sale,
      cart: Cart(guid: 'order-1', isCheckOut: false, items: [watch()]),
    );
    await open(tester);
    await tester.enterText(serialField(), 'SN1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(sale.serialLookups, isEmpty);
    expect(tester.widget<TextField>(serialField()).controller!.text, 'SN1');
  });

  testWidgets('CITES and VAS details show when the line has them', (
    tester,
  ) async {
    viewModel = buildSaleViewModel(
      sale,
      cart: Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [
          watch(
            cites: 'Y',
            vas: const [
              VasItem(
                articleCode: 'VAS01',
                articleName: 'GIFT BOX',
                totalRequireQty: 2,
                existQty: 1,
                remainQty: 1,
              ),
            ],
          ),
        ],
      ),
    );
    await open(tester);

    await tester.ensureVisible(byTestId(EditLineIds.cites));
    expect(find.text('Permit No : P-77'), findsOneWidget);
    await tester.ensureVisible(byTestId(EditLineIds.vas(0)));
    expect(find.text('Article : VAS01'), findsOneWidget);
    expect(find.text('VAS INFORMATION [2]'), findsOneWidget);
  });

  testWidgets('no CITES / VAS blocks for a plain line', (tester) async {
    await open(tester);
    expect(byTestId(EditLineIds.cites), findsNothing);
    expect(byTestId(EditLineIds.vas(0)), findsNothing);
  });

  testWidgets('Freeze and Lock toggle and are saved', (tester) async {
    await open(tester);
    await tester.ensureVisible(byTestId(EditLineIds.lockDiscountSwitch));
    await tester.tap(byTestId(EditLineIds.freezeSwitch));
    await tester.tap(byTestId(EditLineIds.lockDiscountSwitch));
    await tester.pump();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();

    expect(sale.lineEdits.single.edit.isFreeze, isTrue);
    expect(sale.lineEdits.single.edit.isLockDiscount, isTrue);
  });

  testWidgets('Pickup needs actTake — without it the choice is refused', (
    tester,
  ) async {
    await open(tester);
    await tester.ensureVisible(byTestId(EditLineIds.pickupCollect));
    await tester.tap(byTestId(EditLineIds.pickupCollect));
    await tester.pumpAndSettle();

    expect(find.text(SaleCartViewModel.noCurrencyPermission), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // The refused choice leaves nothing to save.
    expect(saveEnabled(tester), isFalse);
    expect(sale.lineEdits, isEmpty);
  });

  testWidgets('Pickup with actTake saves take_collect', (tester) async {
    viewModel = buildSaleViewModel(
      sale,
      cart: sampleCart,
      session: const UserSession(
        sessionKey: 'abc123',
        branchNo: '03',
        userCode: 'U001',
        userName: 'Test User',
        authorizedActions: [
          AuthorizedAction(moduleCode: 'SALE', authCode: 'actTake', action: ''),
        ],
      ),
    );
    await open(tester);
    await tester.ensureVisible(byTestId(EditLineIds.pickupCollect));
    await tester.tap(byTestId(EditLineIds.pickupCollect));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();

    expect(sale.lineEdits.single.edit.collectStatus, 'C');
  });

  testWidgets('airport mPOS hides Pickup, as legacy does', (tester) async {
    setDeviceSize(tester, compactSize);
    await tester.pumpWidget(
      TestApp(
        home: EditLinePage(
          viewModel: viewModel,
          row: johnnie.row,
          lineNumber: 2,
          isAirportMpos: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(byTestId(EditLineIds.pickupCollect), findsNothing);
    expect(byTestId(EditLineIds.freezeSwitch), findsOneWidget);
  });

  testWidgets('serial shows only for a line that requires one, and is sent', (
    tester,
  ) async {
    viewModel = buildSaleViewModel(
      sale,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [
          CartItem(
            row: '2',
            articleCode: '5000267116419',
            articleName: 'WATCH',
            quantity: 1,
            unitPrice: 9000,
            lineTotal: 9000,
            requireSerial: true,
          ),
        ],
      ),
    );
    await open(tester);
    await tester.enterText(
      find.descendant(
        of: byTestId(EditLineIds.serialField),
        matching: find.byType(TextField),
      ),
      'SN123',
    );
    await tester.pump();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();

    expect(sale.lineEdits.single.edit.serialNo, 'SN123');
  });

  testWidgets('a WARNING answer is shown and the line kept', (tester) async {
    sale.lineEditWarning = 'Stock is low.';
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.pump();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('Warning !'), findsOneWidget);
    expect(find.text('Stock is low.'), findsOneWidget);
  });

  testWidgets('an error is shown and the draft undone', (tester) async {
    sale.mutationError = const ApiException(
      messageCode: 'E01',
      messageDesc: 'Not allowed.',
    );
    await open(tester);
    await tester.tap(byTestId(EditLineIds.qtyIncrease));
    await tester.pump();
    await tester.tap(byTestId(EditLineIds.saveButton));
    await tester.pumpAndSettle();

    expect(find.text('E01: Not allowed.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(textIn(tester, EditLineIds.qtyValue), '2');
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

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    expect(byTestId(EditLineIds.saveCloseButton), findsOneWidget);
  });
}
