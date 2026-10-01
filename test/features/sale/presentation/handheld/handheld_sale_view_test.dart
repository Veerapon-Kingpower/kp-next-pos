import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/theme/app_colors.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/sale_order_context.dart';
import 'package:kp_pos/features/sale/presentation/handheld/handheld_sale_view.dart';
import 'package:kp_pos/features/sale/presentation/handheld/sale_order_type.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import 'sale_test_helpers.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeSaleRepository sale;

  Future<SaleCartViewModel> pump(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Cart cartAfterMutation = sampleCart,
    Object? mutationError,
    Size size = compactSize,
    SaleOrderType orderType = SaleOrderType.normal,
    bool isAirportMpos = false,
    VoidCallback? onExit,
    VoidCallback? onCustomer,
  }) async {
    setDeviceSize(tester, size);
    sale = FakeSaleRepository(
      cartResult: cartAfterMutation,
      mutationError: mutationError,
    );
    final viewModel = buildSaleViewModel(sale, cart: cart);
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: HandheldSaleView(
            viewModel: viewModel,
            orderType: orderType,
            isAirportMpos: isAirportMpos,
            onExit: onExit ?? () {},
            onCustomer: onCustomer ?? () {},
          ),
        ),
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

  group('header', () {
    testWidgets('title, totals band and tab counts come from the cart', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Sale · NORMAL'), findsOneWidget);
      expect(textIn(tester, SaleIds.netPay), '฿21,500.00');
      expect(textIn(tester, SaleIds.totalLine), 'Total 21,500.00 · 3 units');
      expect(
        find.descendant(
          of: byTestId(SaleIds.tabBuying),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
    });

    for (final (type, title, color) in [
      (SaleOrderType.normal, 'Sale · NORMAL', AppColors.goldDark),
      (SaleOrderType.delivery, 'Sale · DELIVERY', Color(0xFF165FA9)),
      (SaleOrderType.deposit, 'Sale · DEPOSIT', Color(0xFF165FA9)),
      (SaleOrderType.preOrder, 'Sale · Pre-order', Color(0xFFBF4D0D)),
    ]) {
      testWidgets('${type.name} uses its own header colour', (tester) async {
        await pump(tester, orderType: type);
        expect(find.text(title), findsOneWidget);
        final box = tester.widget<ColoredBox>(
          find
              .ancestor(
                of: byTestId(SaleIds.backButton),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(box.color, color);
      });
    }

    testWidgets('back button exits to Home', (tester) async {
      var exits = 0;
      await pump(tester, onExit: () => exits++);
      await tester.tap(byTestId(SaleIds.backButton));
      expect(exits, 1);
    });
  });

  group('scan', () {
    testWidgets('scanning adds the article through the view-model', (
      tester,
    ) async {
      await pump(tester, cart: null);
      expect(byTestId(SaleIds.emptyState), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: byTestId(SaleIds.scanField),
          matching: find.byType(TextField),
        ),
        '2*8850012345678',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(sale.lastAddedItemCode, '2*8850012345678');
      expect(sale.lastAddedRows, isEmpty);
      expect(byTestId(SaleIds.line('1')), findsOneWidget);
    });

    testWidgets('the scan field does not take focus on open (no on-screen '
        'keyboard), and gets it back after a scan (disabled while busy)', (
      tester,
    ) async {
      await pump(tester, cart: null);
      bool focused() => tester
          .state<EditableTextState>(
            find.descendant(
              of: byTestId(SaleIds.scanField),
              matching: find.byType(EditableText),
            ),
          )
          .widget
          .focusNode
          .hasFocus;
      expect(focused(), isFalse);

      await tester.enterText(
        find.descendant(
          of: byTestId(SaleIds.scanField),
          matching: find.byType(TextField),
        ),
        '8850012345678',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(sale.lastAddedItemCode, '8850012345678');
      expect(focused(), isTrue);
    });

    testWidgets('the search button submits the typed code', (tester) async {
      await pump(tester, cart: null);
      await tester.enterText(
        find.descendant(
          of: byTestId(SaleIds.scanField),
          matching: find.byType(TextField),
        ),
        '8850012345678',
      );
      await tester.tap(byTestId(SaleIds.searchButton));
      await tester.pumpAndSettle();
      expect(sale.lastAddedItemCode, '8850012345678');
      expect(byTestId(SaleIds.line('1')), findsOneWidget);
    });

    testWidgets('a rejected scan shows the error and keeps the text', (
      tester,
    ) async {
      await pump(
        tester,
        mutationError: const ApiException(messageDesc: 'Item not found'),
      );
      final field = find.descendant(
        of: byTestId(SaleIds.scanField),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, '8850000000000');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanError), findsOneWidget);
      expect(tester.widget<TextField>(field).controller!.text, '8850000000000');
    });
  });

  group('lines', () {
    testWidgets('each line shows number, name, qty and total', (tester) async {
      await pump(tester);
      final line = byTestId(SaleIds.line('2'));
      expect(
        find.descendant(
          of: line,
          matching: find.text('JOHNNIE WALKER BLUE LABEL 1L'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: line, matching: find.text('Qty 2 × 7,800.00')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: line, matching: find.text('15,600.00')),
        findsOneWidget,
      );
    });

    testWidgets('tapping a line opens Edit line', (tester) async {
      await pump(tester);
      await tester.tap(byTestId(SaleIds.line('1')));
      await tester.pumpAndSettle();
      expect(byTestId(EditLineIds.page), findsOneWidget);
      expect(find.text('Line 1'), findsOneWidget);
    });

    testWidgets('swiping left asks to void, then removes the row', (
      tester,
    ) async {
      await pump(
        tester,
        cartAfterMutation: const Cart(
          guid: 'order-1',
          isCheckOut: false,
          items: [chanel],
        ),
      );
      await tester.drag(byTestId(SaleIds.line('2')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Void this line?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Void line'));
      await tester.pumpAndSettle();
      expect(sale.lastRemovedRow, '2');
      expect(byTestId(SaleIds.line('2')), findsNothing);
    });

    testWidgets('cancelling the void keeps the line', (tester) async {
      await pump(tester);
      await tester.drag(byTestId(SaleIds.line('2')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(sale.lastRemovedRow, isNull);
      expect(byTestId(SaleIds.line('2')), findsOneWidget);
    });

    testWidgets('swiping right opens the Discount sheet for that line', (
      tester,
    ) async {
      await pump(tester);
      await tester.drag(byTestId(SaleIds.line('2')), const Offset(500, 0));
      await tester.pumpAndSettle();
      expect(byTestId(DiscountIds.sheet), findsOneWidget);
      expect(find.text('Discount · line 2'), findsOneWidget);
    });

    testWidgets('a selected privilege is shown above the lines', (
      tester,
    ) async {
      final viewModel = await pump(tester);
      viewModel
        ..selectedPrivilege = const Privilege(
          name: 'Gold Member',
          discount: 10,
          typeCode: 'VIP',
          promoCode: 'PROMO123',
        )
        ..update();
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: byTestId(SaleIds.privilege),
          matching: find.text('Gold Member'),
        ),
        findsOneWidget,
      );
    });

    group('privilege (legacy Privilege Selection)', () {
      const gold = Privilege(
        name: 'Gold 10%',
        discount: 10,
        typeCode: 'VIP',
        promoCode: 'GOLD10',
        raw: {'PromoCode': 'GOLD10'},
      );
      const elite = Privilege(
        name: 'Elite 15%',
        discount: 15,
        typeCode: 'VIP',
        promoCode: 'ELITE15',
        raw: {'PromoCode': 'ELITE15'},
      );

      Future<SaleCartViewModel> pumpMember(WidgetTester tester) async {
        final viewModel = await pump(tester);
        await viewModel.openOrder(
          const SaleOrderContext(shoppingCard: 'CPX0001', memberId: 'M1'),
          privilege: gold,
          privileges: const [gold, elite],
        );
        await tester.pumpAndSettle();
        return viewModel;
      }

      testWidgets('Change on the privilege row re-prices the order', (
        tester,
      ) async {
        final viewModel = await pumpMember(tester);
        await tester.tap(byTestId(SaleIds.privilegeChangeButton));
        await tester.pumpAndSettle();
        expect(byTestId(SaleIds.privilegePicker), findsOneWidget);
        await tester.tap(byTestId(SaleIds.privilegeOption(1)));
        await tester.pumpAndSettle();
        expect(sale.lastOrderContext!.tier, elite.raw);
        expect(viewModel.selectedPrivilege, elite);
        expect(
          find.descendant(
            of: byTestId(SaleIds.privilege),
            matching: find.text('Elite 15%'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('the More sheet offers Privilege Selection, as legacy', (
        tester,
      ) async {
        final viewModel = await pumpMember(tester);
        await tester.tap(byTestId(SaleIds.moreButton));
        await tester.pumpAndSettle();
        await tester.ensureVisible(byTestId(SaleIds.privilegeMoreButton));
        await tester.tap(byTestId(SaleIds.privilegeMoreButton));
        await tester.pumpAndSettle();
        await tester.tap(byTestId(SaleIds.privilegeNone));
        await tester.pumpAndSettle();
        expect(sale.lastOrderContext!.tier, isNull);
        expect(viewModel.selectedPrivilege, isNull);
        expect(
          find.descendant(
            of: byTestId(SaleIds.privilege),
            matching: find.text('No Privilege'),
          ),
          findsOneWidget,
        );
      });
    });
  });

  group('tabs', () {
    testWidgets('Basket shows the lines of the saved order with their status', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: mixedCart, cartAfterMutation: mixedCart);
      expect(byTestId(SaleIds.line('1')), findsOneWidget, reason: 'Buying');
      expect(byTestId(SaleIds.line('b1')), findsNothing);

      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(SaleIds.tabBasket)),
        isSemantics(isSelected: true),
      );
      expect(byTestId(SaleIds.line('1')), findsNothing);
      expect(byTestId(SaleIds.line('b1')), findsOneWidget);
      expect(byTestId(SaleIds.lineFulfilment('b1')), findsOneWidget);
      expect(byTestId(SaleIds.lineCancelled('b2')), findsOneWidget);
      expect(byTestId(SaleIds.lineFreeze('b2')), findsOneWidget);
      expect(byTestId(SaleIds.lineLock('b2')), findsOneWidget);

      // Basket's secondary action returns to Buying.
      await tester.tap(find.widgetWithText(InkWell, 'Buying').last);
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.line('1')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('swiping a Basket line left cancels it after confirming', (
      tester,
    ) async {
      await pump(tester, cart: mixedCart, cartAfterMutation: mixedCart);
      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();

      await tester.drag(byTestId(SaleIds.line('b2')), const Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(sale.lineActions.single.action, 'cancel');
      expect(sale.lineActions.single.value, '0', reason: 'b2 was cancelled');
      expect(sale.lastRemovedRow, isNull, reason: 'never voided');
    });
  });

  group('action bar', () {
    testWidgets('Checkout shows the net and opens the Checkout page', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Checkout · ฿21,500.00'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.checkoutButton));
      await tester.pumpAndSettle();
      expect(byTestId(CheckoutIds.page), findsOneWidget);
    });

    testWidgets('Checkout is disabled on an empty bill', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: null);
      expect(
        tester.getSemantics(byTestId(SaleIds.checkoutButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('Customer goes to customer lookup', (tester) async {
      var calls = 0;
      await pump(tester, onCustomer: () => calls++);
      await tester.tap(byTestId(SaleIds.customerButton));
      expect(calls, 1);
    });

    testWidgets('Discount opens the sheet for the last line', (tester) async {
      await pump(tester);
      await tester.tap(byTestId(SaleIds.discountButton));
      await tester.pumpAndSettle();
      expect(find.text('Discount · line 2'), findsOneWidget);
    });

    testWidgets('the number badge selects lines; Discount opens for them', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(byTestId(SaleIds.lineSelect('1')));
      await tester.pump();
      expect(
        tester.getSemantics(byTestId(SaleIds.lineSelect('1'))),
        isSemantics(isButton: true, isSelected: true),
      );
      await tester.tap(byTestId(SaleIds.lineSelect('2')));
      await tester.pump();

      await tester.tap(byTestId(SaleIds.discountButton));
      await tester.pumpAndSettle();
      expect(find.text('Discount · 2 lines'), findsOneWidget);
    });

    testWidgets('Discount is disabled on an empty bill', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: null);
      expect(
        tester.getSemantics(byTestId(SaleIds.discountButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('More lists legacy order types, only NORMAL is available', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tester.tap(byTestId(SaleIds.moreButton));
      await tester.pumpAndSettle();

      expect(byTestId(SaleIds.moreSheet), findsOneWidget);
      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('DELIVERY'), findsOneWidget);
      expect(find.text('Pre-order'), findsOneWidget);
      expect(byTestId(SaleIds.orderType('deposit')), findsNothing);
      expect(
        tester.getSemantics(byTestId(SaleIds.orderType('normal'))),
        isSemantics(isSelected: true),
      );
      for (final id in [
        SaleIds.orderType('delivery'),
        SaleIds.orderType('preOrder'),
      ]) {
        expect(
          tester.getSemantics(byTestId(id)),
          isSemantics(hasEnabledState: true, isEnabled: false),
          reason: id,
        );
      }
      handle.dispose();
    });

    testWidgets('airport mPOS offers NORMAL / DEPOSIT, as legacy', (
      tester,
    ) async {
      await pump(tester, isAirportMpos: true);
      await tester.tap(byTestId(SaleIds.moreButton));
      await tester.pumpAndSettle();

      expect(find.text('NORMAL'), findsOneWidget);
      expect(find.text('DEPOSIT'), findsOneWidget);
      expect(byTestId(SaleIds.orderType('delivery')), findsNothing);
      expect(byTestId(SaleIds.orderType('preOrder')), findsNothing);
    });

    testWidgets('all bar actions expose semantics ids', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      for (final id in [
        SaleIds.scanField,
        SaleIds.netPay,
        SaleIds.tabBuying,
        SaleIds.tabBasket,
        SaleIds.checkoutButton,
        SaleIds.customerButton,
        SaleIds.discountButton,
        SaleIds.saveOrderButton,
        SaleIds.moreButton,
        SaleIds.line('1'),
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      handle.dispose();
    });
  });

  testWidgets('iPad portrait: header spans full width, lines are capped', (
    tester,
  ) async {
    await pump(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    final line = tester.getRect(byTestId(SaleIds.line('1')));
    expect(line.width, lessThanOrEqualTo(720));
    expect(line.center.dx, closeTo(410, 0.5));
  });

  testWidgets('Save in the action bar saves the order after confirming', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(byTestId(SaleIds.saveOrderButton));
    await tester.pumpAndSettle();
    expect(find.text('Do you want to save order'), findsOneWidget);
    await tester.tap(byTestId(SaleIds.saveOrderOk));
    await tester.pumpAndSettle();
    expect(sale.savedOrders, ['CPX0001']);
  });
}
