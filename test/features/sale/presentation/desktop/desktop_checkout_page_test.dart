import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_checkout_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';
import '../../../../helpers/test_app.dart';

const _jane = Customer(
  action: 'found',
  isFound: true,
  person: CustomerPerson(
    englishName: 'JANE DOE',
    passportNo: 'P1234567',
    nationality: 'THA',
    contacts: [],
    privileges: [],
    walletMembers: [],
    shoppingCard: 'CPX0001',
    customerTypeCode: 'FIT',
    isActivate: true,
    flightCode: 'TG101',
    flightDate: '2026-08-18',
    flightTime: '10:00',
    flightRouteDetail: 'BKK - NRT',
    flightPickup: 'Gate A1',
  ),
  tour: {},
  agentCode: '',
  isMember: false,
);

void main() {
  late FakeSaleRepository sale;

  Future<SaleCartViewModel> open(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Privilege? privilege,
    Customer? customer,
    bool isAirportMpos = false,
    bool isMember = false,
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    sale = FakeSaleRepository(cartResult: cart ?? sampleCart);
    final viewModel = buildSaleViewModel(sale, cart: cart);
    viewModel
      ..isMember = isMember
      ..selectedPrivilege = privilege
      ..customer = customer
      ..session = testSession;
    await tester.pumpWidget(
      TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openDesktopCheckoutPage(
                context,
                viewModel: viewModel,
                isAirportMpos: isAirportMpos,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return viewModel;
  }

  Finder inCard(String id, Finder finder) =>
      find.descendant(of: byTestId(id), matching: finder);

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

  testWidgets('one compact summary: customer, card and order — no flight', (
    tester,
  ) async {
    await open(tester, customer: _jane);
    for (final text in ['JANE DOE', 'CPX0001']) {
      expect(
        inCard(CheckoutIds.customerCard, find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(find.textContaining('TG101'), findsNothing, reason: 'no flight');
    // Left on the Customer page, so the lines get the room.
    for (final text in [
      'FIT',
      'THA',
      'Registered',
      'P1234567',
      'Gate A1',
      'U001 · Test User',
      'DFA',
    ]) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });

  testWidgets('Net pay is the Sale page size (36 pt)', (tester) async {
    await open(tester);
    final text = tester.widget<Text>(
      find.descendant(
        of: byTestId(CheckoutIds.netPay),
        matching: find.byType(Text),
      ),
    );
    expect(text.style?.fontSize, 36);
  });

  testWidgets('the lines table takes the height left by the summary', (
    tester,
  ) async {
    await open(tester, customer: _jane, size: const Size(1280, 800));
    final summary = tester.getRect(byTestId(CheckoutIds.customerCard));
    final table = tester.getRect(byTestId(DesktopPaymentIds.linesTable));
    expect(summary.height, lessThan(120));
    expect(table.height, greaterThan(400));
  });

  testWidgets('airport mPOS adds DFA and promoter', (tester) async {
    await open(
      tester,
      customer: _jane,
      isAirportMpos: true,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel],
        dfa: 'D01',
        promoter: 'PR9',
      ),
    );
    expect(inCard(CheckoutIds.customerCard, find.text('D01')), findsOneWidget);
    expect(inCard(CheckoutIds.customerCard, find.text('PR9')), findsOneWidget);
  });

  testWidgets('without a customer: shopping card / order only', (tester) async {
    await open(tester);
    expect(
      inCard(CheckoutIds.customerCard, find.text('CPX0001')),
      findsOneWidget,
    );
    expect(inCard(CheckoutIds.customerCard, find.text('FLIGHT')), findsNothing);
  });

  testWidgets('a member without a privilege shows Privilege: None', (
    tester,
  ) async {
    await open(tester, customer: _jane, isMember: true);
    expect(
      inCard(CheckoutIds.customerCard, find.text('PRIVILEGE')),
      findsOneWidget,
    );
    expect(inCard(CheckoutIds.customerCard, find.text('None')), findsOneWidget);
  });

  testWidgets('a member shows Carat and e-Purse; a non-member does not', (
    tester,
  ) async {
    const member = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'JANE DOE',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [],
        walletMembers: [
          {'PaymentCode': 'CARAT', 'Balance': 1250},
          {'PaymentCode': 'CASHW', 'Balance': 300},
        ],
        shoppingCard: 'CPX0001',
        isActivate: true,
      ),
      tour: {},
      agentCode: '',
      isMember: true,
    );
    await open(tester, customer: member, isMember: true);
    expect(
      inCard(CheckoutIds.customerCard, find.text('CARAT')),
      findsOneWidget,
    );
    expect(
      inCard(CheckoutIds.customerCard, find.text('1,250.00')),
      findsOneWidget,
    );
    expect(
      inCard(CheckoutIds.customerCard, find.text('฿300.00')),
      findsOneWidget,
    );
  });

  testWidgets('a non-member has no Carat or e-Purse', (tester) async {
    await open(tester, customer: _jane);
    expect(find.text('CARAT'), findsNothing);
    expect(find.text('E-PURSE'), findsNothing);
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
      inCard(CheckoutIds.customerCard, find.text('Gold Member · [VIP]:P1')),
      findsOneWidget,
    );
  });

  testWidgets('the Discount column shows each line discount', (tester) async {
    await open(
      tester,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [
          CartItem(
            row: '1',
            articleCode: 'A1',
            articleName: 'PERFUME',
            quantity: 1,
            unitPrice: 1000,
            lineTotal: 900,
            discountAmount: 100,
          ),
        ],
      ),
    );
    // formatAmount uses the typographic minus (U+2212).
    expect(textIn(tester, CheckoutIds.lineDiscount('1')), '−100.00');
  });

  testWidgets('bill discount rows, and Bill discount saves through '
      'ActionOrderPayment (legacy SpecialDiscountPage)', (tester) async {
    await open(
      tester,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel],
        billing: CartBilling(
          currencyCode: 'THB',
          currencyDescription: 'Baht',
          currencyRate: 1,
          total: 5900,
          grand: 5900,
          discount: 0,
          cashD: 0,
          netPay: 5310,
          netPayBase: 5310,
          percentDiscountSpecial: 10,
          discountSpecial: 590,
          promotionCode: 'SP10',
          promotionName: 'Special 10%',
        ),
      ),
    );
    expect(
      inCard(CheckoutIds.billDiscountRows, find.text('10.00%')),
      findsOneWidget,
    );
    expect(
      inCard(CheckoutIds.billDiscountRows, find.text('590.00')),
      findsOneWidget,
    );
    expect(
      inCard(CheckoutIds.billDiscountRows, find.text('SP10 | Special 10%')),
      findsOneWidget,
    );

    await tester.tap(byTestId(CheckoutIds.billDiscountButton));
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsOneWidget);
    expect(find.text('Bill discount'), findsWidgets);

    // A scanned promotion QR goes as add_special_discount_by_qrcode.
    await tester.enterText(
      find.descendant(
        of: byTestId(DiscountIds.scanField),
        matching: find.byType(TextField),
      ),
      'QR1',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(sale.orderActions.single.action, 'add_special_discount_by_qrcode');
    expect(sale.orderActions.single.value, 'QR1');
    expect(sale.orderActions.single.orderGuid, '');
  });

  testWidgets('Gift with Purchase lists the offers, applied ones ticked', (
    tester,
  ) async {
    await open(
      tester,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel],
        giftsWithPurchase: [
          GiftWithPurchase(text: 'Free pouch over 5,000', canApply: true),
          GiftWithPurchase(text: 'Tote over 10,000', canApply: false),
        ],
      ),
    );
    expect(
      inCard(CheckoutIds.gwpCard, find.text('Free pouch over 5,000')),
      findsOneWidget,
    );
    expect(
      inCard(CheckoutIds.gwpCard, find.byIcon(Icons.check_circle)),
      findsOneWidget,
    );
  });

  testWidgets('no signature box unless the order requires one', (tester) async {
    await open(tester);
    expect(byTestId(DesktopPaymentIds.signatureBox), findsNothing);
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

  testWidgets('Esc asks first; Cancel stays on Checkout', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.leaveDialog), findsOneWidget);
    expect(find.text('Do you want to go back?'), findsOneWidget);
    await tester.tap(byTestId(CheckoutIds.leaveCancel));
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.page), findsOneWidget);
    expect(sale.orderActions, isEmpty);
    expect(sale.orderStatuses, isEmpty);
  });

  testWidgets('OK aborts the payment session, puts the order back to Sale '
      '(UpdateOrderStatus a) and returns', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(byTestId(CheckoutIds.leaveOk));
    await tester.pumpAndSettle();
    // Legacy sessionAbortPayment(): ActionOrderPayment Abort (2).
    expect(sale.orderActions.single.action, '2');
    expect(sale.orderActions.single.orderGuid, 'order-1');
    expect(sale.orderStatuses.single.status, 'a');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('a failed abort is shown and Checkout stays', (tester) async {
    await open(tester);
    sale.mutationError = const ApiException(
      messageCode: 'E09',
      messageDesc: 'Payment in progress.',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.tap(byTestId(CheckoutIds.leaveOk));
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.leaveError), findsOneWidget);
    expect(find.text('E09: Payment in progress.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.page), findsOneWidget);
    expect(sale.orderStatuses, isEmpty);
  });

  testWidgets('signature box opens the pad', (tester) async {
    await open(
      tester,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel, johnnie],
        requireSignature: true,
      ),
    );
    await tester.tap(byTestId(DesktopPaymentIds.signatureBox));
    await tester.pumpAndSettle();
    expect(byTestId(SignatureIds.page), findsOneWidget);
  });

  testWidgets('no Suspend bill or Print quote', (tester) async {
    await open(tester);
    expect(find.text('Suspend bill'), findsNothing);
    expect(find.text('Print quote'), findsNothing);
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
