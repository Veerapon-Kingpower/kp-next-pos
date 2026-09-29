import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_models.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/wallet_query_page.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/wallet_scan_page.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/wallet_void_page.dart';

import '../../../../../helpers/test_id_finders.dart';

const _alipay = Tender(
  method: TenderMethod.wallet,
  title: 'Alipay · B scan C',
  amount: 27370,
  status: TenderStatus.approved,
  reference: 'BSC-260826-77431',
  walletProvider: WalletProvider.alipay,
);

const _visa = Tender(
  method: TenderMethod.card,
  title: 'Visa •••• 4021',
  amount: 60000,
  status: TenderStatus.approved,
);

Future<void> _pumpPage(
  WidgetTester tester,
  Widget page, {
  Size size = compactSize,
}) async {
  setDeviceSize(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute<void>(builder: (_) => page)),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void _expectEnabled(WidgetTester tester, String id, bool enabled) => expect(
  tester.getSemantics(byTestId(id)),
  isSemantics(hasEnabledState: true, isEnabled: enabled),
  reason: id,
);

void main() {
  group('WalletScanPage (B scan C)', () {
    Future<void> scan(WidgetTester tester, String code) async {
      await tester.enterText(
        find.descendant(
          of: byTestId(WalletIds.codeField),
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
    }

    testWidgets('shows the amount to charge and the scan instructions', (
      tester,
    ) async {
      await _pumpPage(tester, const WalletScanPage(amount: 27370));
      expect(byTestId(WalletIds.scanPage), findsOneWidget);
      expect(find.text('฿27,370.00'), findsOneWidget);
      expect(find.textContaining('open their wallet'), findsOneWidget);
    });

    testWidgets('an Alipay code is detected, masked and ticks step 1', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(tester, const WalletScanPage(amount: 27370));
      await scan(tester, '281234567890124417');

      expect(
        find.descendant(
          of: byTestId(WalletIds.detectedCode),
          matching: find.text('28 •••• 4417'),
        ),
        findsOneWidget,
      );
      expect(find.text('Alipay detected'), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(WalletIds.step('scanned')),
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
      // Sending the charge needs 2C2P — inert.
      _expectEnabled(tester, WalletIds.sendChargeButton, false);
      handle.dispose();
    });

    testWidgets('a non-wallet code is rejected', (tester) async {
      await _pumpPage(tester, const WalletScanPage(amount: 27370));
      await scan(tester, '8850012345678');
      expect(byTestId(WalletIds.unknownCode), findsOneWidget);
      expect(byTestId(WalletIds.detectedCode), findsNothing);
    });

    testWidgets('Rescan clears the detected code', (tester) async {
      await _pumpPage(tester, const WalletScanPage(amount: 27370));
      await scan(tester, '134567890123456789');
      expect(find.text('WeChat Pay detected'), findsOneWidget);
      await tester.tap(byTestId(WalletIds.rescanButton));
      await tester.pumpAndSettle();
      expect(byTestId(WalletIds.detectedCode), findsNothing);
    });

    testWidgets('Cancel closes the page', (tester) async {
      await _pumpPage(tester, const WalletScanPage(amount: 27370));
      await tester.tap(byTestId(WalletIds.cancelButton));
      await tester.pumpAndSettle();
      expect(byTestId(WalletIds.scanPage), findsNothing);
    });

    testWidgets('iPad portrait renders without overflow', (tester) async {
      await _pumpPage(
        tester,
        const WalletScanPage(amount: 27370),
        size: mediumSize,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('WalletQueryPage', () {
    testWidgets('lists the tenders and highlights the wallet one', (
      tester,
    ) async {
      await _pumpPage(
        tester,
        const WalletQueryPage(tenders: [_visa, _alipay], focus: _alipay),
      );
      expect(byTestId(WalletIds.queryPage), findsOneWidget);
      expect(find.text('Visa •••• 4021'), findsOneWidget);
      expect(find.text('Alipay · B scan C'), findsOneWidget);
      expect(find.text('BSC-260826-77431'), findsWidgets);
      expect(find.text('2 tenders · 2 approved'), findsOneWidget);
    });

    testWidgets('the 2C2P query is inert and says so', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(
        tester,
        const WalletQueryPage(tenders: [_alipay], focus: _alipay),
      );
      _expectEnabled(tester, WalletIds.queryButton, false);
      expect(
        find.descendant(
          of: byTestId(WalletIds.queryResult),
          matching: find.textContaining('not available yet'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Void opens the void page for a wallet tender', (tester) async {
      await _pumpPage(
        tester,
        const WalletQueryPage(tenders: [_alipay], focus: _alipay),
      );
      await tester.tap(byTestId(WalletIds.voidButton));
      await tester.pumpAndSettle();
      expect(byTestId(WalletIds.voidPage), findsOneWidget);
    });

    testWidgets('Void is disabled for a card tender (voided on the EDC)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(
        tester,
        const WalletQueryPage(tenders: [_visa], focus: _visa),
      );
      _expectEnabled(tester, WalletIds.voidButton, false);
      handle.dispose();
    });
  });

  group('WalletVoidPage', () {
    testWidgets('full amount only, reason picker, gated on manager', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpPage(tester, const WalletVoidPage(tender: _alipay));

      expect(find.text('Void Alipay payment'), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(WalletIds.voidAmount),
          matching: find.text('฿27,370.00'),
        ),
        findsOneWidget,
      );
      expect(find.text('Customer cancelled purchase'), findsOneWidget);
      _expectEnabled(tester, WalletIds.managerApproval, false);
      _expectEnabled(tester, WalletIds.confirmVoidButton, false);
      expect(find.text('Enabled after manager approval'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the reason can be changed locally', (tester) async {
      await _pumpPage(tester, const WalletVoidPage(tender: _alipay));
      await tester.tap(byTestId(WalletIds.voidReason));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duplicate charge').last);
      await tester.pumpAndSettle();
      expect(find.text('Duplicate charge'), findsOneWidget);
    });

    testWidgets('iPad portrait renders without overflow', (tester) async {
      await _pumpPage(
        tester,
        const WalletVoidPage(tender: _alipay),
        size: mediumSize,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
