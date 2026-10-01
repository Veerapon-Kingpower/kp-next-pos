import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/finish_payment.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_payment_page.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../../../helpers/test_app.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';

void main() {
  group('signature and Complete sale (legacy goSignaturePage / '
      'onFinishPayment)', () {
    const paidSigned = Cart(
      guid: 'order-1',
      isCheckOut: true,
      items: [chanel],
      requireSignature: true,
      remaining: 0,
    );

    late FakeSaleRepository repo;
    var signedOut = 0;

    Future<void> pumpOrder(WidgetTester tester, Cart cart) async {
      setDeviceSize(tester, const Size(1440, 900));
      signedOut = 0;
      repo = FakeSaleRepository(cartResult: cart);
      final viewModel = buildSaleViewModel(repo, cart: cart);
      await tester.pumpWidget(
        TestApp(
          home: DesktopPaymentPage(
            netPay: 5900,
            viewModel: viewModel,
            onSignOut: () async => signedOut++,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> sign(WidgetTester tester) async {
      await tester.tap(byTestId(PaymentIds.signatureButton));
      await tester.pumpAndSettle();
      final pad = tester.getCenter(byTestId(SignatureIds.customerPad));
      await tester.dragFrom(pad - const Offset(60, 0), const Offset(120, 8));
      await tester.pump();
      await tester.tap(byTestId(SignatureIds.bottomSaveButton));
      await tester.pumpAndSettle();
    }

    Future<void> complete(WidgetTester tester) async {
      await tester.tap(byTestId(PaymentIds.completeSaleButton));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to confirm payments'), findsOneWidget);
      await tester.tap(byTestId(PaymentIds.finishConfirmOk));
      await tester.pumpAndSettle();
    }

    testWidgets('signed: ValidateGWP, FinishPaymentOrder with the customer '
        'signature (code 1), Save Complete, then sign out', (tester) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      await complete(tester);

      expect(repo.gwpValidations.single, 'order-1');
      final sent = repo.finishes.single;
      expect(sent.orderGuid, 'order-1');
      expect(sent.signatures!.single.code, '1');
      expect(sent.signatures!.single.value, startsWith('data:image/png'));
      expect(byTestId(PaymentIds.finishSaved), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
    });

    testWidgets('Cancel on "Confirm Payment" does nothing', (tester) async {
      await pumpOrder(tester, paidSigned);
      await tester.tap(byTestId(PaymentIds.completeSaleButton));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(PaymentIds.finishConfirmCancel));
      await tester.pumpAndSettle();
      expect(repo.gwpValidations, isEmpty);
      expect(repo.finishes, isEmpty);
    });

    testWidgets('no signature required: OrderSignature is null', (
      tester,
    ) async {
      await pumpOrder(
        tester,
        const Cart(
          guid: 'order-1',
          isCheckOut: true,
          items: [chanel],
          remaining: 0,
        ),
      );
      await complete(tester);
      expect(repo.finishes.single.signatures, isNull);
    });

    testWidgets('GWP blocks with its message; nothing is finished', (
      tester,
    ) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      repo.gwpAnswer = const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(
            type: 'Warning',
            code: 'GWP',
            desc: 'Take the gift first.',
          ),
        ],
      );
      await complete(tester);
      expect(find.text('Take the gift first.'), findsOneWidget);
      expect(repo.finishes, isEmpty);
    });

    testWidgets('GWP_authorize asks; Yes finishes', (tester) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      repo.gwpAnswer = const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(
            type: 'Confirm',
            code: 'GWP_authorize',
            desc: 'Skip the gift?',
          ),
        ],
      );
      await complete(tester);
      expect(find.text('Skip the gift?'), findsOneWidget);
      await tester.tap(byTestId(PaymentIds.finishConfirmOk));
      await tester.pumpAndSettle();
      expect(repo.finishes, hasLength(1));
    });

    testWidgets('a FinishPaymentOrder error is shown and the cashier stays; '
        'SESSION_EXPIRE signs out', (tester) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      repo.finishAnswer = const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(type: 'Error', code: 'E77', desc: 'Not balanced.'),
        ],
      );
      await complete(tester);
      expect(find.text('Error Code:  E77'), findsOneWidget);
      expect(find.text('Not balanced.'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(signedOut, 0);

      repo.finishAnswer = const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(
            type: 'Error',
            code: 'SESSION_EXPIRE',
            desc: 'Session expired.',
          ),
        ],
      );
      await complete(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
    });

    testWidgets('EARN_ERROR counts as done (legacy prints and signs out)', (
      tester,
    ) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      repo.finishAnswer = const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(
            type: 'Error',
            code: 'EARN_ERROR',
            desc: 'Points not earned.',
          ),
        ],
      );
      await complete(tester);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(byTestId(PaymentIds.finishSaved), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
    });

    testWidgets('no network on FinishPaymentOrder: alert, then sign out', (
      tester,
    ) async {
      await pumpOrder(tester, paidSigned);
      await sign(tester);
      repo.finishError = const ApiException(
        messageDesc: 'No network connection.',
      );
      await complete(tester);
      expect(find.text('Network not connection'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(signedOut, 1);
    });

    testWidgets('paid but not signed: Complete sale asks for the signature', (
      tester,
    ) async {
      await pumpOrder(tester, paidSigned);
      expect(byTestId(PaymentIds.signatureButton), findsOneWidget);
      await complete(tester);
      expect(repo.finishes, isEmpty);
      expect(
        find.text('This shopping card is require signature.'),
        findsOneWidget,
      );
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

    testWidgets('an order without isRequireSignature has no Signature', (
      tester,
    ) async {
      await pumpOrder(tester, sampleCart);
      expect(byTestId(PaymentIds.signatureButton), findsNothing);
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(TestApp(home: DesktopPaymentPage(netPay: 27370)));
    await tester.pumpAndSettle();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  String tendered(WidgetTester tester) => tester
      .widget<TextField>(
        find.descendant(
          of: byTestId(DesktopPaymentIds.tenderedField),
          matching: find.byType(TextField),
        ),
      )
      .controller!
      .text;

  testWidgets('step 3: net pay / tendered / remaining and empty ledger', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(textIn(tester, PaymentIds.netPay), '฿27,370.00');
    expect(textIn(tester, PaymentIds.tendered), '฿0.00');
    expect(textIn(tester, PaymentIds.remaining), '฿27,370.00');
    expect(byTestId(PaymentIds.ledgerEmpty), findsOneWidget);
  });

  testWidgets('Cash is the default method; F-keys switch methods', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('cash'))),
      isSemantics(isSelected: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f1);
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(PaymentIds.method('card'))),
      isSemantics(isSelected: true),
    );
    expect(
      find.descendant(
        of: byTestId(DesktopPaymentIds.detailPanel),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pump();
    expect(byTestId(DesktopPaymentIds.tenderedField), findsOneWidget);
    handle.dispose();
  });

  testWidgets('quick amount previews applied-to-bill and change due', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.quick(30000)));
    await tester.pump();
    expect(tendered(tester), '30000');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿27,370.00');
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿2,630.00');
  });

  testWidgets('Exact tenders the remaining amount with no change', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.exactChip));
    await tester.pump();
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿0.00');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿27,370.00');
  });

  testWidgets('keypad types, 00 appends, backspace deletes', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopPaymentIds.keypad('5')));
    await tester.tap(byTestId(DesktopPaymentIds.keypad('00')));
    await tester.tap(byTestId(DesktopPaymentIds.keypad('0')));
    await tester.pump();
    expect(tendered(tester), '5000');
    await tester.tap(byTestId(DesktopPaymentIds.keypadBackspace));
    await tester.pump();
    expect(tendered(tester), '500');
    expect(textIn(tester, DesktopPaymentIds.appliedToBill), '฿500.00');
    expect(textIn(tester, DesktopPaymentIds.changeDue), '฿0.00');
  });

  testWidgets('only THB is selectable until exchange rates exist', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(DesktopPaymentIds.currency('THB'))),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(byTestId(DesktopPaymentIds.currency('USD'))),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('Add tender, Open drawer and Complete sale are inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      DesktopPaymentIds.addTenderButton,
      DesktopPaymentIds.openDrawerButton,
      PaymentIds.completeSaleButton,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    expect(
      find.text('Complete sale unlocks when remaining hits ฿0.00'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('fits 1024 dp without overflow', (tester) async {
    await pump(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });
}
