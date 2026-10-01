import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/checkout_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../../../helpers/test_id_finders.dart';
import '../../../fake_sale_repository.dart';
import '../sale_test_helpers.dart';
import '../../../../../helpers/test_app.dart';

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
    isActivate: true,
    flightCode: 'TG101',
    flightRouteDetail: 'BKK - NRT',
  ),
  tour: {},
  agentCode: '',
  isMember: false,
);

const _member = Customer(
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

// Paid in full — legacy only lets the customer sign then.
const _signedCart = Cart(
  guid: 'order-1',
  isCheckOut: false,
  items: [chanel, johnnie],
  requireSignature: true,
  remaining: 0,
);

void main() {
  late FakeSaleRepository sale;

  Future<SaleCartViewModel> pump(
    WidgetTester tester, {
    Cart? cart = sampleCart,
    Privilege? privilege,
    Customer? customer,
    bool isMember = false,
    Size size = compactSize,
    Future<void> Function()? onSignOut,
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
        home: CheckoutPage(viewModel: viewModel, onSignOut: onSignOut),
      ),
    );
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

  testWidgets('one Customer card: name, card and order — no flight', (
    tester,
  ) async {
    await pump(tester, customer: _jane);
    expect(find.text('TG101'), findsNothing, reason: 'no flight');
    for (final text in ['JANE DOE', 'CPX0001']) {
      expect(
        inCard(CheckoutIds.customerCard, find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    for (final text in ['Registered', 'P1234567', 'U001 · Test User']) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });

  testWidgets('a member shows the privilege in use, Carat and e-Purse', (
    tester,
  ) async {
    await pump(
      tester,
      customer: _member,
      isMember: true,
      privilege: const Privilege(
        name: 'Gold Member',
        discount: 10,
        typeCode: 'VIP',
        promoCode: 'P1',
      ),
    );
    for (final text in ['Gold Member · [VIP]:P1', '1,250.00', '฿300.00']) {
      expect(
        inCard(CheckoutIds.customerCard, find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
  });

  testWidgets('a member without a privilege shows Privilege: None', (
    tester,
  ) async {
    await pump(tester, customer: _member, isMember: true);
    expect(inCard(CheckoutIds.customerCard, find.text('None')), findsOneWidget);
  });

  testWidgets('a non-member has no privilege, Carat or e-Purse', (
    tester,
  ) async {
    await pump(tester, customer: _jane);
    for (final text in ['Privilege', 'Carat', 'e-Purse']) {
      expect(find.text(text), findsNothing, reason: text);
    }
  });

  testWidgets('without a customer: shopping card / order only', (tester) async {
    await pump(tester);
    expect(
      inCard(CheckoutIds.customerCard, find.text('CPX0001')),
      findsOneWidget,
    );
    expect(find.text('Flight'), findsNothing);
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
    expect(
      inCard(
        CheckoutIds.customerCard,
        find.text('Gold Member · [VIP]:PROMO123'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Bill discount opens the bill discount sheet and saves through '
      'ActionOrderPayment', (tester) async {
    await pump(tester);
    await tester.ensureVisible(byTestId(CheckoutIds.billDiscountButton));
    await tester.tap(byTestId(CheckoutIds.billDiscountButton));
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsOneWidget);

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
  });

  testWidgets('Gift with Purchase shows when the order has offers', (
    tester,
  ) async {
    await pump(
      tester,
      cart: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [chanel],
        giftsWithPurchase: [
          GiftWithPurchase(text: 'Free pouch', canApply: true),
        ],
      ),
    );
    await tester.ensureVisible(byTestId(CheckoutIds.gwpCard));
    expect(
      inCard(CheckoutIds.gwpCard, find.text('Free pouch')),
      findsOneWidget,
    );
  });

  testWidgets('no signature row on Checkout — it is on Payment', (
    tester,
  ) async {
    await pump(tester, cart: _signedCart);
    expect(byTestId(CheckoutIds.signatureRow), findsNothing);
  });

  testWidgets('back asks first; OK aborts, puts the order back to Sale and '
      'returns', (tester) async {
    setDeviceSize(tester, compactSize);
    sale = FakeSaleRepository(cartResult: sampleCart);
    final viewModel = buildSaleViewModel(sale, cart: sampleCart);
    await tester.pumpWidget(
      TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => openCheckoutPage(context, viewModel: viewModel),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.leaveDialog), findsOneWidget);
    await tester.tap(byTestId(CheckoutIds.leaveCancel));
    await tester.pumpAndSettle();
    expect(byTestId(CheckoutIds.page), findsOneWidget);
    expect(sale.orderActions, isEmpty);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(CheckoutIds.leaveOk));
    await tester.pumpAndSettle();
    expect(sale.orderActions.single.action, '2');
    expect(sale.orderStatuses.single.status, 'a');
    expect(byTestId(CheckoutIds.page), findsNothing);
    expect(find.text('open'), findsOneWidget);
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

  testWidgets('SESSION_EXPIRE: "Session expired", then log out', (
    tester,
  ) async {
    var signedOut = 0;
    await pump(tester, onSignOut: () async => signedOut++);
    sale.mutationError = const ApiException(
      messageCode: 'SESSION_EXPIRE',
      messageDesc: 'Session expired.',
    );
    await tester.ensureVisible(byTestId(CheckoutIds.billDiscountButton));
    await tester.tap(byTestId(CheckoutIds.billDiscountButton));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: byTestId(DiscountIds.scanField),
        matching: find.byType(TextField),
      ),
      'QR1',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(byTestId(CheckoutIds.sessionExpiredDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: byTestId(CheckoutIds.sessionExpiredDialog),
        matching: find.text('OK'),
      ),
    );
    await tester.pumpAndSettle();
    expect(signedOut, 1);
  });

  testWidgets('no Suspend or Print quote', (tester) async {
    await pump(tester);
    expect(find.text('Suspend'), findsNothing);
    expect(find.text('Print quote'), findsNothing);
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
