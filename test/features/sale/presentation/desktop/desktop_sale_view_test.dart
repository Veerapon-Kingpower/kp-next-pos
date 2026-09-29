import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_sale_view.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';

void main() {
  late FakeSaleRepository sale;

  Future<SaleCartViewModel> pump(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Cart cartAfterMutation = sampleCart,
    Size size = const Size(1440 - 84, 900 - 64),
  }) async {
    setDeviceSize(tester, size);
    sale = FakeSaleRepository(cartResult: cartAfterMutation);
    final viewModel = buildSaleViewModel(sale, cart: cart);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: DesktopSaleView(viewModel: viewModel)),
      ),
    );
    await tester.pumpAndSettle();
    return viewModel;
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  Finder scanField() => find.descendant(
    of: byTestId(SaleIds.scanField),
    matching: find.byType(TextField),
  );

  group('table', () {
    testWidgets('one row per cart line with qty, unit price and net', (
      tester,
    ) async {
      await pump(tester);
      for (final label in [
        '#',
        'Item',
        'Qty',
        'Unit price',
        'Discount',
        'Net (THB)',
        'Fulfilment',
      ]) {
        expect(
          find.descendant(
            of: byTestId(DesktopSaleIds.table),
            matching: find.text(label),
          ),
          findsWidgets,
          reason: label,
        );
      }
      final row = byTestId(SaleIds.line('2'));
      expect(
        find.descendant(
          of: row,
          matching: find.text('JOHNNIE WALKER BLUE LABEL 1L'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('7,800.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('15,600.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('—')),
        findsNWidgets(2),
      );
    });

    testWidgets('empty bill shows the scan prompt', (tester) async {
      await pump(tester, cart: null);
      expect(byTestId(SaleIds.emptyState), findsOneWidget);
    });

    testWidgets('qty stepper updates the line through the view-model', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(byTestId(DesktopSaleIds.qtyIncrease('2')));
      await tester.pumpAndSettle();
      expect(sale.lastUpdatedRow, '2');
      expect(sale.lastUpdatedQuantity, 3);
    });

    testWidgets('selecting a row enables Discount / Remove', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(byTestId(SaleIds.discountButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(find.text('CHANEL N°5 EAU DE PARFUM 100ML'));
      await tester.pump();
      expect(
        tester.getSemantics(byTestId(SaleIds.line('1'))),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(byTestId(SaleIds.discountButton)),
        isSemantics(hasEnabledState: true, isEnabled: true),
      );
      expect(
        textIn(tester, DesktopSaleIds.selectionHint),
        'Line 1 selected · ↑↓ to move',
      );
      handle.dispose();
    });

    testWidgets('Discount (F6) opens the overlay for the selected line', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(find.text('JOHNNIE WALKER BLUE LABEL 1L'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f6);
      await tester.pumpAndSettle();
      expect(byTestId(DiscountIds.sheet), findsOneWidget);
      expect(find.text('Discount · line 2'), findsOneWidget);
    });

    testWidgets('Remove (F8) confirms, then removes the selected line', (
      tester,
    ) async {
      await pump(
        tester,
        cartAfterMutation: const Cart(
          guid: 'o',
          isCheckOut: false,
          items: [chanel],
        ),
      );
      await tester.tap(find.text('JOHNNIE WALKER BLUE LABEL 1L'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f8);
      await tester.pumpAndSettle();
      expect(find.text('Remove this line?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Remove line'));
      await tester.pumpAndSettle();
      expect(sale.lastRemovedRow, '2');
      expect(byTestId(SaleIds.line('2')), findsNothing);
    });

    testWidgets('↓ / ↑ move the selection', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(find.text('CHANEL N°5 EAU DE PARFUM 100ML'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        tester.getSemantics(byTestId(SaleIds.line('2'))),
        isSemantics(isSelected: true),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        tester.getSemantics(byTestId(SaleIds.line('1'))),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });
  });

  group('scan row', () {
    testWidgets('scanning adds through the view-model and keeps focus', (
      tester,
    ) async {
      await pump(tester, cart: null);
      await tester.enterText(scanField(), '2*8850012345678');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(sale.lastLookupBarcode, '8850012345678');
      expect(sale.lastAddedQuantity, 2);
      expect(tester.widget<TextField>(scanField()).controller!.text, isEmpty);
      expect(tester.widget<TextField>(scanField()).focusNode!.hasFocus, isTrue);
    });

    testWidgets('Qty × (F7) turns a typed quantity into the qty* prefix', (
      tester,
    ) async {
      await pump(tester);
      await tester.enterText(scanField(), '3');
      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await tester.pump();
      expect(tester.widget<TextField>(scanField()).controller!.text, '3*');
    });

    testWidgets('scan errors are shown', (tester) async {
      await pump(tester);
      await tester.enterText(scanField(), '');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanError), findsOneWidget);
    });

    testWidgets('Lookup (F9) is inert', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(byTestId(DesktopSaleIds.lookupButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('bill summary', () {
    testWidgets('totals from the cart; unknown breakdown as —', (tester) async {
      await pump(tester);
      expect(textIn(tester, DesktopSaleIds.qtyTotal), '3');
      expect(textIn(tester, DesktopSaleIds.lineCount), '2');
      expect(textIn(tester, DesktopSaleIds.grand), '21,500.00');
      expect(textIn(tester, SaleIds.netPay), '฿21,500.00');
      expect(
        find.descendant(
          of: byTestId(DesktopSaleIds.summary),
          matching: find.text('—'),
        ),
        findsNWidgets(2),
        reason: 'discount, Cash-D subsidy',
      );
    });

    testWidgets('shows the privilege picked on the Customer tab', (
      tester,
    ) async {
      final viewModel = await pump(tester);
      viewModel.selectPrivilege(
        const Privilege(
          name: 'Gold Member',
          discount: 10,
          typeCode: 'VIP',
          promoCode: 'PROMO123',
        ),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: byTestId(SaleIds.privilege),
          matching: find.text('[VIP]:PROMO123'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Take payment and Suspend are inert until 2c', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      for (final id in [SaleIds.checkoutButton, DesktopSaleIds.suspendButton]) {
        expect(
          tester.getSemantics(byTestId(id)),
          isSemantics(hasEnabledState: true, isEnabled: false),
          reason: id,
        );
      }
      handle.dispose();
    });
  });

  group('Basket tab (S4)', () {
    testWidgets('shows the lines with the fulfilment notice and actions', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(SaleIds.tabBasket)),
        isSemantics(isSelected: true),
      );
      expect(byTestId(SaleIds.basketNotice), findsOneWidget);
      expect(byTestId(SaleIds.line('1')), findsOneWidget);
      for (final id in [
        DesktopSaleIds.printBasketButton,
        DesktopSaleIds.claimCheckButton,
      ]) {
        expect(
          tester.getSemantics(byTestId(id)),
          isSemantics(hasEnabledState: true, isEnabled: false),
          reason: id,
        );
      }
      handle.dispose();
    });
  });

  for (final size in [
    const Size(1024 - 84, 768 - 64),
    const Size(1920 - 84, 1080 - 64),
  ]) {
    testWidgets('no overflow at ${size.width.toInt()} dp body width', (
      tester,
    ) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
