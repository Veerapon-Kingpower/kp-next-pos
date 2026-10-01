import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_models.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_page.dart';

import '../../../../../helpers/test_id_finders.dart';
import '../../../../../helpers/test_app.dart';
import '../../../fake_sale_repository.dart';
import '../sale_test_helpers.dart';

const _approvedVisa = Tender(
  method: TenderMethod.card,
  title: 'Visa •••• 4021',
  amount: 40000,
  status: TenderStatus.approved,
);
const _approvedAlipay = Tender(
  method: TenderMethod.wallet,
  title: 'Alipay · QR',
  amount: 20000,
  status: TenderStatus.approved,
  reference: 'BSC-1',
  walletProvider: WalletProvider.alipay,
);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    double netPay = 87370,
    List<Tender> tenders = const [],
    Size size = compactSize,
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      TestApp(
        home: PaymentPage(netPay: netPay, tenders: tenders),
      ),
    );
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  String amount(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: byTestId(PaymentIds.amountField),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets('net pay, tendered and remaining with no tenders', (
    tester,
  ) async {
    await pump(tester);
    expect(textIn(tester, PaymentIds.netPay), '฿87,370.00');
    expect(textIn(tester, PaymentIds.tendered), '฿0.00');
    expect(textIn(tester, PaymentIds.remaining), '฿87,370.00');
    expect(byTestId(PaymentIds.ledgerEmpty), findsOneWidget);
  });

  testWidgets('approved tenders reduce remaining and fill the ledger', (
    tester,
  ) async {
    await pump(tester, tenders: const [_approvedVisa, _approvedAlipay]);
    expect(textIn(tester, PaymentIds.tendered), '฿60,000.00');
    expect(textIn(tester, PaymentIds.remaining), '฿27,370.00');
    expect(byTestId(PaymentIds.ledgerRow(0)), findsOneWidget);
    expect(byTestId(PaymentIds.ledgerRow(1)), findsOneWidget);
    expect(amount(tester), '27370.00');
  });

  testWidgets('presets set the amount and never exceed remaining', (
    tester,
  ) async {
    await pump(tester, netPay: 15000);
    await tester.tap(byTestId(PaymentIds.presetHalf));
    await tester.pump();
    expect(amount(tester), '7500.00');

    await tester.tap(byTestId(PaymentIds.preset10000));
    await tester.pump();
    expect(amount(tester), '10000.00');

    await tester.tap(byTestId(PaymentIds.preset20000));
    await tester.pump();
    expect(amount(tester), '15000.00', reason: 'clamped to remaining');

    await tester.tap(byTestId(PaymentIds.presetHalf));
    await tester.tap(byTestId(PaymentIds.presetAllRemaining));
    await tester.pump();
    expect(amount(tester), '15000.00');
  });

  testWidgets('the Charge label follows the amount', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(PaymentIds.preset10000));
    await tester.pump();
    expect(find.text('Charge ฿10,000.00'), findsOneWidget);
  });

  testWidgets('method tiles are single-choice; Card is the default', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('card'))),
      isSemantics(isSelected: true),
    );
    await tester.tap(byTestId(PaymentIds.method('cash')));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('cash'))),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('card'))),
      isSemantics(isSelected: false),
    );
    handle.dispose();
  });

  testWidgets('Card / cash charging is inert and says why', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(PaymentIds.chargeButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    expect(byTestId(PaymentIds.chargeNotice), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Wallet + Charge opens B scan C with the amount', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(PaymentIds.method('wallet')));
    await tester.tap(byTestId(PaymentIds.preset20000));
    await tester.pump();
    await tester.tap(byTestId(PaymentIds.chargeButton));
    await tester.pumpAndSettle();

    expect(byTestId(WalletIds.scanPage), findsOneWidget);
    expect(
      find.descendant(
        of: byTestId(WalletIds.chargeAmount),
        matching: find.text('฿20,000.00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a wallet tender opens its query page', (tester) async {
    await pump(tester, tenders: const [_approvedVisa, _approvedAlipay]);
    await tester.ensureVisible(byTestId(PaymentIds.ledgerRow(1)));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(PaymentIds.ledgerRow(1)));
    await tester.pumpAndSettle();
    expect(byTestId(WalletIds.queryPage), findsOneWidget);
  });

  testWidgets('Complete sale stays disabled while money is remaining', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(PaymentIds.completeSaleButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    expect(
      find.text('Complete sale unlocks when remaining hits ฿0.00'),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('signature and Complete sale (legacy)', () {
    late FakeSaleRepository repo;
    var signedOut = 0;

    Future<void> pumpOrder(WidgetTester tester, Cart cart) async {
      setDeviceSize(tester, compactSize);
      signedOut = 0;
      repo = FakeSaleRepository(cartResult: cart);
      final viewModel = buildSaleViewModel(repo, cart: cart);
      await tester.pumpWidget(
        TestApp(
          home: PaymentPage(
            netPay: 5900,
            viewModel: viewModel,
            onSignOut: () async => signedOut++,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> complete(WidgetTester tester) async {
      await tester.tap(byTestId(PaymentIds.completeSaleButton));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(PaymentIds.finishConfirmOk));
      await tester.pumpAndSettle();
    }

    testWidgets('paid but not signed: Complete sale asks for the signature', (
      tester,
    ) async {
      await pumpOrder(
        tester,
        const Cart(
          guid: 'order-1',
          isCheckOut: true,
          items: [chanel],
          requireSignature: true,
          remaining: 0,
        ),
      );
      await complete(tester);
      expect(
        find.text('This shopping card is require signature.'),
        findsOneWidget,
      );
      expect(repo.finishes, isEmpty);
    });

    testWidgets('signed: FinishPaymentOrder with both signatures (1 and 2), '
        'then sign out', (tester) async {
      await pumpOrder(
        tester,
        const Cart(
          guid: 'order-1',
          orderNo: 'S-1',
          isCheckOut: true,
          items: [chanel],
          requireSignature: true,
          remaining: 0,
        ),
      );
      await tester.tap(byTestId(PaymentIds.signatureButton));
      await tester.pumpAndSettle();
      for (final id in [SignatureIds.paidByPad, SignatureIds.customerPad]) {
        await tester.ensureVisible(byTestId(id));
        final pad = tester.getCenter(byTestId(id));
        await tester.dragFrom(pad - const Offset(60, 0), const Offset(120, 8));
        await tester.pump();
      }
      await tester.ensureVisible(byTestId(SignatureIds.bottomSaveButton));
      await tester.tap(byTestId(SignatureIds.bottomSaveButton));
      await tester.pumpAndSettle();

      await complete(tester);
      expect(repo.finishes.single.signatures!.map((s) => s.code), ['1', '2']);
      expect(repo.invoicePrints.single, 'S-1');
      expect(find.text('Printing original'), findsOneWidget);
      await tester.tap(byTestId(PaymentIds.printPageOk));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
    });

    testWidgets('Complete sale is off while anything is left to pay', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpOrder(
        tester,
        const Cart(
          guid: 'order-1',
          isCheckOut: true,
          items: [chanel],
          remaining: 100,
        ),
      );
      expect(
        tester.getSemantics(byTestId(PaymentIds.completeSaleButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('not paid: Signature says "Please pay first."', (tester) async {
      await pumpOrder(
        tester,
        const Cart(
          guid: 'order-1',
          isCheckOut: true,
          items: [chanel],
          requireSignature: true,
          remaining: 5900,
        ),
      );
      await tester.tap(byTestId(PaymentIds.signatureButton));
      await tester.pumpAndSettle();
      expect(find.text('Please pay first.'), findsOneWidget);
    });

    testWidgets('no signature required: no Signature item', (tester) async {
      await pumpOrder(tester, sampleCart);
      expect(byTestId(PaymentIds.signatureButton), findsNothing);
    });
  });

  testWidgets('iPad portrait: centred content, no overflow', (tester) async {
    await pump(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    final grid = tester.getRect(byTestId(PaymentIds.method('card')));
    expect(grid.left, greaterThanOrEqualTo(50));
  });
}
