import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_models.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_page.dart';

import '../../../../../helpers/test_id_finders.dart';

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
      MaterialApp(
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

  testWidgets('iPad portrait: centred content, no overflow', (tester) async {
    await pump(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
    final grid = tester.getRect(byTestId(PaymentIds.method('card')));
    expect(grid.left, greaterThanOrEqualTo(50));
  });
}
