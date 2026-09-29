import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_checkout_page.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_payment_page.dart';
import 'package:kp_pos/features/sale/presentation/handheld/handheld_sale_view.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/checkout_page.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_page.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../helpers/test_id_finders.dart';
import '../fake_sale_repository.dart';
import 'currency_fixtures.dart';
import 'handheld/sale_test_helpers.dart';

/// Legacy parity: the order currency on handheld Sale and both Checkouts
/// (`SalePage` / `CheckoutPage.changeCurrency()`), and change in another
/// currency (`ChangePage`, `SaleEngine/ExchangeCurrency`).
void main() {
  late FakeSaleRepository repo;

  SaleCartViewModel viewModel({String shoppingCard = 'CPX0001'}) {
    repo = FakeSaleRepository(
      cartResult: sampleCart,
      currencies: branchCurrencies,
      currencyCartResult: usdCart,
      exchangeQuote: quoteAtBranchRates,
    );
    return buildSaleViewModel(repo, cart: sampleCart, session: currencySession)
      ..attachShoppingCard(shoppingCard);
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  Future<void> pickUsd(WidgetTester tester) async {
    await tester.tap(byTestId(CurrencyIds.orderButton));
    await tester.pumpAndSettle();
    expect(byTestId(CurrencyIds.picker), findsOneWidget);
    await tester.tap(byTestId(CurrencyIds.option('USD')));
    await tester.pumpAndSettle();
  }

  Future<void> pushCheckout(
    WidgetTester tester,
    void Function(BuildContext) open,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => open(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('handheld Sale', () {
    Future<SaleCartViewModel> pump(
      WidgetTester tester, {
      String shoppingCard = 'CPX0001',
    }) async {
      setDeviceSize(tester, compactSize);
      final vm = viewModel(shoppingCard: shoppingCard);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HandheldSaleView(
              viewModel: vm,
              onExit: () {},
              onCustomer: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return vm;
    }

    testWidgets('the header currency button waits for a customer', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, shoppingCard: '');
      expect(
        tester.getSemantics(byTestId(CurrencyIds.orderButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('picking USD reprices the order; header and Checkout bar '
        'follow it', (tester) async {
      await pump(tester);
      expect(textIn(tester, SaleIds.netPay), '฿21,500.00');

      await pickUsd(tester);

      expect(repo.lastCurrencyCode, 'USD');
      expect(repo.lastCurrencyShoppingCard, 'CPX0001');
      expect(textIn(tester, SaleIds.netPay), 'USD 166.20');
      expect(find.textContaining('Checkout · USD 166.20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('desktop Checkout', () {
    testWidgets('currency button on Amount due; USD amounts reach Payment', (
      tester,
    ) async {
      setDeviceSize(tester, const Size(1440, 900));
      final vm = viewModel();
      await pushCheckout(
        tester,
        (context) => openDesktopCheckoutPage(context, viewModel: vm),
      );

      await pickUsd(tester);

      expect(textIn(tester, CheckoutIds.netPay), 'USD 166.20');
      expect(textIn(tester, CurrencyIds.netPayBase), '= ฿5,900.00');
      expect(textIn(tester, CurrencyIds.rate), '35.50000');

      await tester.tap(byTestId(CheckoutIds.takePaymentButton));
      await tester.pumpAndSettle();
      expect(textIn(tester, PaymentIds.netPay), 'USD 166.20');
    });
  });

  group('handheld Checkout', () {
    testWidgets('currency button on Amounts; USD amounts reach Payment', (
      tester,
    ) async {
      setDeviceSize(tester, const Size(400, 1400));
      final vm = viewModel();
      await pushCheckout(
        tester,
        (context) => openCheckoutPage(context, viewModel: vm),
      );

      await pickUsd(tester);

      expect(textIn(tester, CheckoutIds.netPay), 'USD 166.20');
      expect(textIn(tester, CurrencyIds.netPayBase), '฿5,900.00');

      await tester.tap(byTestId(CheckoutIds.takePaymentButton));
      await tester.pumpAndSettle();
      expect(textIn(tester, PaymentIds.netPay), 'USD 166.20');
    });
  });

  group('CHANGE in another currency (desktop Payment)', () {
    Future<void> pump(WidgetTester tester) async {
      setDeviceSize(tester, const Size(1440, 1000));
      final vm = viewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: DesktopPaymentPage(
            netPay: 900,
            loadCurrencies: vm.listCurrencies,
            exchangeChange: vm.exchangeChange,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> tender(WidgetTester tester, String amount) async {
      await tester.enterText(
        find.descendant(
          of: byTestId(DesktopPaymentIds.tenderedField),
          matching: find.byType(TextField),
        ),
        amount,
      );
      await tester.pump();
    }

    testWidgets('only offered when there is change due', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tender(tester, '500');
      expect(
        tester.getSemantics(byTestId(CurrencyIds.changeButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('quotes the change, re-quotes a picked currency and a typed '
        'amount; Save stays inert', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await tender(tester, '1000'); // ฿100 change due
      await tester.tap(byTestId(CurrencyIds.changeButton));
      await tester.pumpAndSettle();

      expect(byTestId(CurrencyIds.changeScreen), findsOneWidget);
      // Opens on THB with the whole change quoted (legacy isChangeButton).
      expect(repo.exchangeCalls.first, (
        code: 'THB',
        amount: 100.0,
        change: 100.0,
        button: true,
      ));
      expect(textIn(tester, CurrencyIds.changeAmountThb), '100.00');

      await tester.tap(byTestId(CurrencyIds.changeCurrency('USD')));
      await tester.pumpAndSettle();
      expect(repo.exchangeCalls.last.code, 'USD');
      expect(repo.exchangeCalls.last.button, isTrue);
      expect(textIn(tester, CurrencyIds.changeRate), '35.500');

      await tester.enterText(
        find.descendant(
          of: byTestId(CurrencyIds.changeCurrencyField),
          matching: find.byType(TextField),
        ),
        '2',
      );
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();
      expect(repo.exchangeCalls.last, (
        code: 'USD',
        amount: 2.0,
        change: 100.0,
        button: false,
      ));
      expect(textIn(tester, CurrencyIds.changeCurrencyThb), '= ฿71.00');
      expect(textIn(tester, CurrencyIds.changeLocal), '29.00');

      expect(
        tester.getSemantics(byTestId(CurrencyIds.changeSaveButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(byTestId(CurrencyIds.changeCancelButton));
      await tester.pumpAndSettle();
      expect(byTestId(CurrencyIds.changeScreen), findsNothing);
      handle.dispose();
    });

    testWidgets('amounts follow the order currency', (tester) async {
      setDeviceSize(tester, const Size(1440, 1000));
      await tester.pumpWidget(
        const MaterialApp(
          home: DesktopPaymentPage(netPay: 166.2, currencyCode: 'USD'),
        ),
      );
      await tester.pumpAndSettle();
      expect(textIn(tester, PaymentIds.netPay), 'USD 166.20');
      expect(textIn(tester, PaymentIds.remaining), 'USD 166.20');
    });
  });

  group('CHANGE in another currency (handheld Payment)', () {
    Future<void> pump(WidgetTester tester, {Size size = compactSize}) async {
      setDeviceSize(tester, size);
      final vm = viewModel();
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentPage(
            netPay: 900,
            loadCurrencies: vm.listCurrencies,
            exchangeChange: vm.exchangeChange,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> cashReceived(WidgetTester tester, String amount) async {
      await tester.tap(byTestId(PaymentIds.method('cash')));
      await tester.pump();
      final field = find.descendant(
        of: byTestId(PaymentIds.cashReceivedField),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, amount);
      await tester.pump();
    }

    testWidgets('the cash block appears only for Cash', (tester) async {
      await pump(tester);
      expect(byTestId(PaymentIds.cashReceivedField), findsNothing);
      await cashReceived(tester, '500');
      expect(textIn(tester, PaymentIds.cashApplied), '฿500.00');
      expect(textIn(tester, PaymentIds.cashChangeDue), '฿0.00');
    });

    for (final (name, size) in [
      ('phone sheet', compactSize),
      ('tablet dialog', mediumSize),
    ]) {
      testWidgets('change due opens the CHANGE screen ($name) and quotes it', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(tester, size: size);
        await cashReceived(tester, '1000'); // ฿100 change due
        expect(textIn(tester, PaymentIds.cashChangeDue), '฿100.00');

        await tester.ensureVisible(byTestId(CurrencyIds.changeButton));
        await tester.tap(byTestId(CurrencyIds.changeButton));
        await tester.pumpAndSettle();

        expect(byTestId(CurrencyIds.changeScreen), findsOneWidget);
        expect(repo.exchangeCalls.first, (
          code: 'THB',
          amount: 100.0,
          change: 100.0,
          button: true,
        ));

        await tester.tap(byTestId(CurrencyIds.changeCurrency('USD')));
        await tester.pumpAndSettle();
        final field = find.descendant(
          of: byTestId(CurrencyIds.changeCurrencyField),
          matching: find.byType(TextField),
        );
        await tester.enterText(field, '2');
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pumpAndSettle();

        expect(repo.exchangeCalls.last, (
          code: 'USD',
          amount: 2.0,
          change: 100.0,
          button: false,
        ));
        expect(textIn(tester, CurrencyIds.changeLocal), '29.00');
        expect(
          tester.getSemantics(byTestId(CurrencyIds.changeSaveButton)),
          isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
        );
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }
  });
}
