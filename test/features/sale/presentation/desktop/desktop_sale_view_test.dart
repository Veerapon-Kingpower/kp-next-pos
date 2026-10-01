import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/desktop/desktop.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/entities/currency.dart';
import 'package:kp_pos/features/sale/domain/entities/sale_order_context.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_sale_view.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeSaleRepository sale;

  Future<SaleCartViewModel> pump(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Cart cartAfterMutation = sampleCart,
    Object? mutationError,
    Size size = const Size(1440 - 84, 900 - 64),
    bool isAirportMpos = false,
    VoidCallback? onExit,
    String shoppingCard = 'CPX0001',
    VoidCallback? onFindCustomer,
    Future<void> Function()? onSignOut,
  }) async {
    setDeviceSize(tester, size);
    sale = FakeSaleRepository(
      cartResult: cartAfterMutation,
      mutationError: mutationError,
    );
    final viewModel = buildSaleViewModel(
      sale,
      cart: cart,
      shoppingCard: shoppingCard,
    );
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: DesktopSaleView(
            viewModel: viewModel,
            isAirportMpos: isAirportMpos,
            onExit: onExit ?? () {},
            onFindCustomer: onFindCustomer,
            onSignOut: onSignOut,
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

  Finder scanField() => find.descendant(
    of: byTestId(SaleIds.scanField),
    matching: find.byType(TextField),
  );

  group('table', () {
    testWidgets('one row per cart line with qty, unit price and net', (
      tester,
    ) async {
      await pump(tester);
      expect(byTestId(DesktopSaleIds.selectAll), findsOneWidget, reason: '#');
      for (final label in [
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

    testWidgets('Edit (F7) opens Edit line for the selected Buying line and '
        'saves it', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(byTestId(DesktopSaleIds.editLineButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(find.text('JOHNNIE WALKER BLUE LABEL 1L'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.f7);
      await tester.pumpAndSettle();

      expect(byTestId(EditLineIds.page), findsOneWidget);
      expect(find.text('Order item · line 2'), findsOneWidget);
      // Nothing changed yet: no Save.
      expect(
        tester.getSemantics(byTestId(EditLineIds.saveButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(byTestId(EditLineIds.qtyIncrease));
      await tester.tap(byTestId(EditLineIds.freezeSwitch));
      await tester.pump();
      expect(
        tester.getSemantics(byTestId(EditLineIds.saveButton)),
        isSemantics(hasEnabledState: true, isEnabled: true),
      );
      await tester.tap(byTestId(EditLineIds.saveCloseButton));
      await tester.pumpAndSettle();

      expect(sale.lineEdits.single.row, '2');
      expect(sale.lineEdits.single.edit.quantity, 3);
      expect(sale.lineEdits.single.edit.isFreeze, isTrue);
      expect(byTestId(EditLineIds.page), findsNothing);
      handle.dispose();
    });

    testWidgets('Edit line hides Pickup on airport mPOS', (tester) async {
      await pump(tester, isAirportMpos: true);
      await tester.tap(find.text('JOHNNIE WALKER BLUE LABEL 1L'));
      await tester.pump();
      await tester.tap(byTestId(DesktopSaleIds.editLineButton));
      await tester.pumpAndSettle();
      expect(byTestId(EditLineIds.page), findsOneWidget);
      expect(byTestId(EditLineIds.pickupCollect), findsNothing);
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

    testWidgets('Discount opens for the ticked lines; Select All ticks all', (
      tester,
    ) async {
      await pump(tester);
      await tester.tap(byTestId(DesktopSaleIds.lineCheck('1')));
      await tester.tap(byTestId(DesktopSaleIds.lineCheck('2')));
      await tester.pump();
      expect(find.text('2 lines ticked for Discount'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.discountButton));
      await tester.pumpAndSettle();
      expect(find.text('Discount · 2 lines'), findsOneWidget);
      expect(
        byTestId(DiscountIds.lineDetail),
        findsNothing,
        reason: 'several lines: the form only, as legacy',
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(byTestId(DesktopSaleIds.selectAll));
      await tester.pump();
      expect(
        tester
            .widget<Checkbox>(
              find.descendant(
                of: byTestId(DesktopSaleIds.selectAll),
                matching: find.byType(Checkbox),
              ),
            )
            .value,
        isFalse,
        reason: 'all were ticked, so Select All clears them',
      );
    });

    testWidgets('the Discount column shows the line discount', (tester) async {
      const discounted = CartItem(
        row: '9',
        articleCode: '1001',
        articleName: 'BAG',
        quantity: 1,
        unitPrice: 6200,
        lineTotal: 5580,
        discountAmount: 620,
      );
      await pump(
        tester,
        cart: const Cart(guid: 'o', isCheckOut: false, items: [discounted]),
      );
      expect(
        find.descendant(
          of: byTestId(SaleIds.line('9')),
          matching: find.text('−620.00'),
        ),
        findsOneWidget,
      );
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
      expect(sale.lastAddedItemCode, '2*8850012345678');
      expect(sale.lastAddedRows, isEmpty);
      expect(tester.widget<TextField>(scanField()).controller!.text, isEmpty);
      expect(tester.widget<TextField>(scanField()).focusNode!.hasFocus, isTrue);
    });

    testWidgets('the ticked line goes along as Rows', (tester) async {
      await pump(tester);
      await tester.tap(byTestId(DesktopSaleIds.lineCheck('2')));
      await tester.pump();
      await tester.enterText(scanField(), '8850012345678');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(sale.lastAddedRows, ['2']);
    });

    testWidgets('scan errors are shown', (tester) async {
      await pump(
        tester,
        mutationError: const ApiException(messageDesc: 'Item not found'),
      );
      await tester.enterText(scanField(), '8850000000000');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanError), findsOneWidget);
    });

    testWidgets('Search submits the typed code, as Enter does', (tester) async {
      await pump(tester, cart: null);
      await tester.enterText(scanField(), '8850012345678');
      await tester.tap(byTestId(DesktopSaleIds.searchButton));
      await tester.pumpAndSettle();
      expect(sale.lastAddedItemCode, '8850012345678');
      expect(tester.widget<TextField>(scanField()).controller!.text, isEmpty);
    });

    testWidgets('F9 searches the typed code', (tester) async {
      await pump(tester, cart: null);
      await tester.enterText(scanField(), '2*8850012345678');
      await tester.sendKeyEvent(LogicalKeyboardKey.f9);
      await tester.pumpAndSettle();
      expect(sale.lastAddedItemCode, '2*8850012345678');
    });
  });

  group('bill summary', () {
    testWidgets('totals from the cart; unknown breakdown as —', (tester) async {
      await pump(tester);
      expect(textIn(tester, DesktopSaleIds.qtyTotal), '3');
      expect(textIn(tester, DesktopSaleIds.lineCount), '2');
      expect(textIn(tester, DesktopSaleIds.mode), 'Normal');
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
      viewModel
        ..selectedPrivilege = const Privilege(
          name: 'Gold Member',
          discount: 10,
          typeCode: 'VIP',
          promoCode: 'PROMO123',
        )
        ..update();
      await tester.pump();
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

      Future<SaleCartViewModel> pumpMember(
        WidgetTester tester, {
        Privilege? privilege,
      }) async {
        final viewModel = await pump(tester);
        await viewModel.openOrder(
          const SaleOrderContext(shoppingCard: 'CPX0001', memberId: 'M1'),
          privilege: privilege,
          privileges: const [gold, elite],
        );
        await tester.pumpAndSettle();
        return viewModel;
      }

      testWidgets('a member without one reads No Privilege', (tester) async {
        await pumpMember(tester);
        final row = byTestId(SaleIds.privilege);
        expect(
          find.descendant(of: row, matching: find.text('No Privilege')),
          findsOneWidget,
        );
        expect(byTestId(SaleIds.privilegeChangeButton), findsOneWidget);
      });

      testWidgets('Change picks another privilege and re-prices the order '
          'through GetOrder', (tester) async {
        final viewModel = await pumpMember(tester, privilege: gold);
        await tester.tap(byTestId(SaleIds.privilegeChangeButton));
        await tester.pumpAndSettle();
        expect(byTestId(SaleIds.privilegePicker), findsOneWidget);
        expect(find.text('Privilege Selection'), findsOneWidget);

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

        await tester.tap(byTestId(SaleIds.privilegeChangeButton));
        await tester.pumpAndSettle();
        await tester.tap(byTestId(SaleIds.privilegeNone));
        await tester.pumpAndSettle();
        expect(sale.lastOrderContext!.tier, isNull);
        expect(viewModel.selectedPrivilege, isNull);
      });

      testWidgets('a rejected change keeps the privilege and says why', (
        tester,
      ) async {
        final viewModel = await pumpMember(tester, privilege: gold);
        sale.mutationError = const ApiException(messageDesc: 'Not allowed');
        await tester.tap(byTestId(SaleIds.privilegeChangeButton));
        await tester.pumpAndSettle();
        await tester.tap(byTestId(SaleIds.privilegeOption(1)));
        await tester.pumpAndSettle();
        expect(find.text('Not allowed'), findsOneWidget);
        expect(viewModel.selectedPrivilege, gold);
      });

      testWidgets('a long name fits the narrow summary: two lines, the code '
          'on its own line, Change on the heading above, room below', (
        tester,
      ) async {
        final viewModel = await pump(tester, size: const Size(1100, 700));
        await viewModel.openOrder(
          const SaleOrderContext(shoppingCard: 'CPX0001', memberId: 'M1'),
          privilege: const Privilege(
            name:
                'King Power Platinum Member Exclusive Privilege Discount '
                'For All Luxury Categories 15 Percent',
            discount: 15,
            typeCode: 'PLATINUM',
            promoCode: 'KPPLAT15ALLLUX',
          ),
          privileges: const [gold],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final name = tester.widget<Text>(
          find.descendant(
            of: byTestId(SaleIds.privilege),
            matching: find.textContaining('King Power Platinum'),
          ),
        );
        expect(name.maxLines, 2);
        expect(name.overflow, TextOverflow.ellipsis);
        final code = tester.getRect(find.text('[PLATINUM]:KPPLAT15ALLLUX'));

        final nameRect = tester.getRect(find.textContaining('King Power'));
        final change = tester.getRect(byTestId(SaleIds.privilegeChangeButton));
        final card = tester.getRect(byTestId(SaleIds.privilege));
        expect(code.top, greaterThanOrEqualTo(nameRect.bottom));
        expect(code.left, closeTo(nameRect.left, 1));
        final label = tester.getRect(find.text('APPLIED PRIVILEGE'));
        expect(change.center.dy, closeTo(label.center.dy, 12));
        expect(change.bottom, lessThanOrEqualTo(card.top), reason: 'above');
        final visible = tester.getSize(
          find
              .descendant(
                of: byTestId(SaleIds.privilegeChangeButton),
                matching: find.byType(Material),
              )
              .first,
        );
        expect(visible.height, 30);
        final pay = tester.getRect(byTestId(SaleIds.checkoutButton));
        expect(pay.top - card.bottom, greaterThanOrEqualTo(12));
      });

      testWidgets('a non-member has no privilege row', (tester) async {
        await pump(tester);
        expect(byTestId(SaleIds.privilege), findsNothing);
      });
    });

    testWidgets('Take payment (F12) opens Checkout', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.f12);
      await tester.pumpAndSettle();
      expect(byTestId(CheckoutIds.page), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Take payment is disabled on an empty bill', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: null);
      expect(
        tester.getSemantics(byTestId(SaleIds.checkoutButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });

  group('Basket tab (S4)', () {
    testWidgets('Buying and Basket split the order by IsBasket', (
      tester,
    ) async {
      await pump(tester, cart: mixedCart, cartAfterMutation: mixedCart);
      expect(byTestId(SaleIds.line('1')), findsOneWidget, reason: 'Buying');
      expect(byTestId(SaleIds.line('b1')), findsNothing);

      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.line('1')), findsNothing);
      expect(byTestId(SaleIds.line('b1')), findsOneWidget);
      expect(textIn(tester, DesktopSaleIds.lineFulfilment('b1')), 'Take');
      expect(textIn(tester, DesktopSaleIds.lineFulfilment('b2')), 'Collect');
      expect(byTestId(DesktopSaleIds.lineCancelled('b2')), findsOneWidget);
      expect(byTestId(DesktopSaleIds.lineFreeze('b2')), findsOneWidget);
      expect(byTestId(DesktopSaleIds.lineLock('b2')), findsOneWidget);
      expect(
        tester.widget<TextField>(scanField()).enabled,
        isFalse,
        reason: 'legacy scans on Buying only',
      );
    });

    testWidgets('a Basket line is cancelled (not removed) after confirming', (
      tester,
    ) async {
      await pump(tester, cart: mixedCart, cartAfterMutation: mixedCart);
      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();
      await tester.tap(find.text('SAVED PERFUME'));
      await tester.pump();
      await tester.tap(byTestId(DesktopSaleIds.removeButton));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to cancel selected item'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
      await tester.pumpAndSettle();

      expect(sale.lineActions.single.action, 'cancel');
      expect(sale.lineActions.single.value, '1');
      expect(sale.lineActions.single.rows, ['b1']);
      expect(sale.lastRemovedRow, isNull);
    });

    testWidgets('Basket has only the legacy actions — no print basket, '
        'claim check or Edit', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: mixedCart);
      await tester.tap(byTestId(SaleIds.tabBasket));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(SaleIds.tabBasket)),
        isSemantics(isSelected: true),
      );
      // Legacy Sale has neither; Claim Check lives in Enquiry.
      expect(find.text('Print basket'), findsNothing);
      expect(find.text('Claim check'), findsNothing);
      expect(byTestId(SaleIds.discountButton), findsOneWidget);
      expect(byTestId(DesktopSaleIds.removeButton), findsOneWidget);
      // Legacy has no Edit Detail on Basket lines.
      expect(byTestId(DesktopSaleIds.editLineButton), findsNothing);
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

  for (final size in [
    const Size(1366 - 84, 768 - 64),
    const Size(1280 - 84, 720 - 64),
  ]) {
    testWidgets('short ${size.height.toInt()} dp screen with a privilege: '
        'no overflow, bill summary scrolls to Take payment', (tester) async {
      final viewModel = await pump(tester, size: size);
      viewModel
        ..selectedPrivilege = const Privilege(
          name: 'Gold Member',
          discount: 10,
          typeCode: 'VIP',
          promoCode: 'PROMO123',
        )
        ..update();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(byTestId(SaleIds.checkoutButton));
      await tester.pumpAndSettle();
      final summary = tester.getRect(byTestId(DesktopSaleIds.summary));
      final button = tester.getRect(byTestId(SaleIds.checkoutButton));
      expect(button.bottom, lessThanOrEqualTo(summary.bottom));
    });
  }

  testWidgets('scan field and Search are standard field height', (
    tester,
  ) async {
    await pump(tester);
    for (final id in [SaleIds.scanField, DesktopSaleIds.searchButton]) {
      expect(
        tester.getSize(byTestId(id)).height,
        DesktopMetrics.fieldHeight,
        reason: id,
      );
    }
  });

  group('currency (legacy Sale header / CurrencyPickerPage)', () {
    const permitted = UserSession(
      sessionKey: 'abc123',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [
        AuthorizedAction(
          moduleCode: 'SALE',
          authCode: 'actCurrency',
          action: 'Currency',
        ),
      ],
    );
    const currencies = [
      Currency(code: 'THB', description: 'Thai Baht', rate: 1),
      Currency(code: 'USD', description: 'US Dollar', rate: 35.5, symbol: r'$'),
      Currency(code: 'EUR', description: 'Euro', rate: 38.2),
    ];
    const usdCart = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [
        CartItem(
          row: '1',
          articleCode: '3145891255607',
          articleName: 'CHANEL N°5 EAU DE PARFUM 100ML',
          quantity: 1,
          unitPrice: 166.2,
          lineTotal: 166.2,
        ),
      ],
      billing: CartBilling(
        currencyCode: 'USD',
        currencyDescription: 'US Dollar',
        currencyRate: 35.5,
        total: 166.2,
        grand: 166.2,
        discount: 0,
        cashD: 0,
        netPay: 166.2,
        netPayBase: 5900,
      ),
    );

    Future<(SaleCartViewModel, FakeSaleRepository)> open(
      WidgetTester tester, {
      UserSession session = permitted,
      String shoppingCard = 'CPX0001',
    }) async {
      setDeviceSize(tester, const Size(1440 - 84, 900 - 64));
      final repo = FakeSaleRepository(
        cartResult: sampleCart,
        currencies: currencies,
        currencyCartResult: usdCart,
      );
      final viewModel = buildSaleViewModel(
        repo,
        cart: sampleCart,
        session: session,
      )..attachShoppingCard(shoppingCard);
      await tester.pumpWidget(
        TestApp(
          home: Scaffold(body: DesktopSaleView(viewModel: viewModel)),
        ),
      );
      await tester.pumpAndSettle();
      return (viewModel, repo);
    }

    testWidgets('inert until a customer (shopping card) is attached', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, shoppingCard: '');
      expect(
        tester.getSemantics(byTestId(CurrencyIds.orderButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('no actCurrency permission: legacy "Oops !" and no picker', (
      tester,
    ) async {
      await open(tester, session: testSession);
      await tester.tap(byTestId(CurrencyIds.orderButton));
      await tester.pumpAndSettle();
      expect(find.text("Sorry, you don't have permission."), findsOneWidget);
      expect(byTestId(CurrencyIds.picker), findsNothing);
    });

    testWidgets('picker lists the branch currencies, THB first, and filters '
        'by code or name', (tester) async {
      await open(tester);
      await tester.tap(byTestId(CurrencyIds.orderButton));
      await tester.pumpAndSettle();

      expect(byTestId(CurrencyIds.picker), findsOneWidget);
      expect(
        tester.getTopLeft(byTestId(CurrencyIds.option('THB'))).dy,
        lessThan(tester.getTopLeft(byTestId(CurrencyIds.option('USD'))).dy),
      );
      await tester.enterText(
        find.descendant(
          of: byTestId(CurrencyIds.search),
          matching: find.byType(TextField),
        ),
        'euro',
      );
      await tester.pump();
      expect(byTestId(CurrencyIds.option('EUR')), findsOneWidget);
      expect(byTestId(CurrencyIds.option('USD')), findsNothing);
    });

    testWidgets('picking USD reprices the order through the sale engine and '
        'shows its amounts', (tester) async {
      final (_, repo) = await open(tester);
      expect(textIn(tester, SaleIds.netPay), '฿21,500.00');

      await tester.tap(byTestId(CurrencyIds.orderButton));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(CurrencyIds.option('USD')));
      await tester.pumpAndSettle();

      expect(repo.lastCurrencyShoppingCard, 'CPX0001');
      expect(repo.lastCurrencyCode, 'USD');
      expect(textIn(tester, SaleIds.netPay), 'USD 166.20');
      expect(textIn(tester, CurrencyIds.netPayBase), '= ฿5,900.00');
      expect(textIn(tester, CurrencyIds.rate), '35.50000');
      expect(find.text('Net (USD)'), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(CurrencyIds.orderButton),
          matching: find.text('USD'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Exit sale (legacy showBeforeLeave)', () {
    Future<void> tapExit(WidgetTester tester) async {
      await tester.ensureVisible(byTestId(DesktopSaleIds.exitButton));
      await tester.tap(byTestId(DesktopSaleIds.exitButton));
      await tester.pumpAndSettle();
    }

    testWidgets('with lines it asks to save; Cancel stays', (tester) async {
      var exited = false;
      await pump(tester, onExit: () => exited = true);
      await tapExit(tester);

      expect(find.text('Do you want to save order?'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.leaveCancel));
      await tester.pumpAndSettle();

      expect(exited, isFalse);
      expect(sale.savedOrders, isEmpty);
      expect(sale.reverseVirtualStockCalls, 0);
    });

    testWidgets('Yes saves the order, then leaves', (tester) async {
      var exited = false;
      final viewModel = await pump(tester, onExit: () => exited = true);
      await tapExit(tester);
      await tester.tap(byTestId(SaleIds.leaveYes));
      await tester.pumpAndSettle();

      expect(sale.savedOrders, ['CPX0001']);
      expect(exited, isTrue);
      expect(viewModel.shoppingCard, isEmpty);
    });

    testWidgets('No reverses the reserved stock, then leaves', (tester) async {
      var exited = false;
      await pump(tester, onExit: () => exited = true);
      await tapExit(tester);
      await tester.tap(byTestId(SaleIds.leaveNo));
      await tester.pumpAndSettle();

      expect(sale.reverseVirtualStockCalls, 1);
      expect(sale.savedOrders, isEmpty);
      expect(exited, isTrue);
    });

    testWidgets('a failed save stays on Sale with the message', (tester) async {
      var exited = false;
      await pump(tester, onExit: () => exited = true);
      sale.saveOrderError = const ApiException(messageDesc: 'Cannot save');
      await tapExit(tester);
      await tester.tap(byTestId(SaleIds.leaveYes));
      await tester.pumpAndSettle();

      expect(exited, isFalse);
      expect(find.text('Cannot save'), findsOneWidget);
    });

    testWidgets('an unlock without network asks before logging out', (
      tester,
    ) async {
      var exited = false;
      var signedOut = false;
      final viewModel = await pump(
        tester,
        cartAfterMutation: const Cart(
          guid: 'order-1',
          isCheckOut: false,
          items: [chanel, johnnie],
          orderNo: '42',
        ),
        onExit: () => exited = true,
        onSignOut: () async => signedOut = true,
      );
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      await tester.pumpAndSettle();
      sale.orderStatusError = const ApiException(
        messageDesc: 'No network connection.',
      );

      await tapExit(tester);
      await tester.tap(byTestId(SaleIds.leaveNo));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.unlockFailedDialog), findsOneWidget);
      await tester.tap(byTestId(SaleIds.unlockFailedCancel));
      await tester.pumpAndSettle();
      expect(exited, isFalse, reason: 'Cancel stays on Sale');
      expect(signedOut, isFalse);
      expect(viewModel.shoppingCard, 'CPX0001', reason: 'still locked');

      await tapExit(tester);
      await tester.tap(byTestId(SaleIds.leaveNo));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(SaleIds.unlockFailedLogout));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
      expect(exited, isFalse);
    });

    testWidgets('airport mPOS only asks to go back', (tester) async {
      var exited = false;
      await pump(tester, isAirportMpos: true, onExit: () => exited = true);
      await tapExit(tester);

      expect(find.text('Do you want to go back?'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.leaveOk));
      await tester.pumpAndSettle();

      expect(exited, isTrue);
      expect(sale.reverseVirtualStockCalls, 0);
    });
  });

  testWidgets('without a customer: scan is off and Find customer leads back', (
    tester,
  ) async {
    var found = false;
    await pump(
      tester,
      cart: null,
      shoppingCard: '',
      onFindCustomer: () => found = true,
    );
    expect(byTestId(SaleIds.noCustomerNotice), findsOneWidget);
    expect(tester.widget<TextField>(scanField()).enabled, isFalse);
    expect(find.text(SaleCartViewModel.noCustomer), findsOneWidget);

    await tester.tap(byTestId(SaleIds.findCustomerButton));
    expect(found, isTrue);
  });

  testWidgets('with a customer there is no notice', (tester) async {
    await pump(tester);
    expect(byTestId(SaleIds.noCustomerNotice), findsNothing);
    expect(tester.widget<TextField>(scanField()).enabled, isTrue);
  });

  group('Save order (legacy saveOrder, in place of Suspend bill)', () {
    Future<void> tapSave(WidgetTester tester) async {
      await tester.ensureVisible(byTestId(SaleIds.saveOrderButton));
      await tester.tap(byTestId(SaleIds.saveOrderButton));
      await tester.pumpAndSettle();
    }

    testWidgets('confirms, saves, then signs out', (tester) async {
      var signedOut = false;
      await pump(tester, onSignOut: () async => signedOut = true);
      await tapSave(tester);
      expect(find.text('Do you want to save order'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.saveOrderOk));
      await tester.pumpAndSettle();
      expect(sale.savedOrders, ['CPX0001']);
      expect(signedOut, isTrue);
    });

    testWidgets('Cancel saves nothing', (tester) async {
      var signedOut = false;
      await pump(tester, onSignOut: () async => signedOut = true);
      await tapSave(tester);
      await tester.tap(byTestId(SaleIds.saveOrderCancel));
      await tester.pumpAndSettle();
      expect(sale.savedOrders, isEmpty);
      expect(signedOut, isFalse);
    });

    testWidgets('a failed save stays, with the message', (tester) async {
      var signedOut = false;
      await pump(tester, onSignOut: () async => signedOut = true);
      sale.saveOrderError = const ApiException(messageDesc: 'Cannot save');
      await tapSave(tester);
      await tester.tap(byTestId(SaleIds.saveOrderOk));
      await tester.pumpAndSettle();
      expect(signedOut, isFalse);
      expect(find.text('Cannot save'), findsOneWidget);
    });

    testWidgets('nothing to save: disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, cart: null);
      expect(
        tester.getSemantics(byTestId(SaleIds.saveOrderButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });
  });
}
