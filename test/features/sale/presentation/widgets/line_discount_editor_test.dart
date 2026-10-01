import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/entities/line_discount.dart';
import 'package:kp_pos/features/sale/domain/entities/promotion.dart';
import 'package:kp_pos/features/sale/domain/usecases/line_discount_usecases.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_discount_overlay.dart';
import 'package:kp_pos/features/sale/presentation/handheld/discount_sheet.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../fake_sale_repository.dart';
import '../handheld/sale_test_helpers.dart';
import '../../../../helpers/test_app.dart';

const _privilege = LineDiscount(
  guid: 'va-1',
  code: 'PRIV10',
  description: 'Member privilege 10%',
  isPercent: true,
  percent: 10,
  calculatedAmount: 620,
  allowOverwrite: true,
  type: 'Privilege',
  raw: {
    'Guid': 'va-1',
    'Type': 'D',
    'VADetail': {'Code': 'PRIV10', 'Desc': 'Member privilege 10%'},
    'Amount': {'CurrAmt': 0, 'CurrAmtForCal': 620},
    'Percent': 10,
    'IsPercent': true,
    'isAllowOverwrite': true,
    'typeDiscount': 'Privilege',
  },
);

const _promo = LineDiscount(
  guid: 'va-2',
  code: 'SUMMER',
  description: 'Summer 500',
  isPercent: false,
  amount: 500,
);

const _line = CartItem(
  row: 'line-1',
  articleCode: '1001',
  articleName: 'GUCCI GG MARMONT SMALL SHOULDER BAG',
  quantity: 1,
  unitPrice: 6200,
  lineTotal: 5080,
  discounts: [_privilege, _promo],
  discountAmount: 1120,
  maxPercentDiscount: 20,
);

const _promotions = [
  Promotion(code: 'P10', name: 'Promo 10%', discountRate: 10),
  Promotion(
    code: 'B500',
    name: 'Baht 500 off',
    discountAmount: 500,
    allowOverwrite: true,
  ),
];

const _noPermission = UserSession(
  sessionKey: 'abc123',
  branchNo: '03',
  userCode: 'U001',
  userName: 'Test User',
  authorizedActions: [],
);

void main() {
  late FakeSaleRepository sale;

  Future<void> open(
    WidgetTester tester, {
    bool desktop = false,
    UserSession session = testSession,
    List<CartItem> lines = const [_line],
  }) async {
    setDeviceSize(tester, desktop ? const Size(1440, 1000) : compactSize);
    final cart = Cart(guid: 'order-1', isCheckOut: false, items: lines);
    sale = FakeSaleRepository(cartResult: cart)..promotions = _promotions;
    final viewModel = buildSaleViewModel(sale, cart: cart, session: session);
    final title = lines.length == 1
        ? 'Discount · line 1'
        : 'Discount · ${lines.length} lines';
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => desktop
                  ? showDesktopDiscountOverlay(
                      context,
                      viewModel: viewModel,
                      lines: lines,
                      title: title,
                    )
                  : showDiscountSheet(
                      context,
                      viewModel: viewModel,
                      lines: lines,
                      title: title,
                    ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String id) =>
      find.descendant(of: byTestId(id), matching: find.byType(TextField));

  TextField textField(WidgetTester tester, String id) =>
      tester.widget<TextField>(field(id));

  Future<void> tapId(WidgetTester tester, String id) async {
    await tester.ensureVisible(byTestId(id));
    await tester.tap(byTestId(id));
    await tester.pumpAndSettle();
  }

  Future<void> typeCode(WidgetTester tester, String code) async {
    await tester.enterText(field(DiscountIds.codeField), code);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the line and its applied discounts', (tester) async {
    await open(tester);
    expect(find.text('Discount · line 1'), findsOneWidget);
    expect(byTestId(DiscountIds.lineDetail), findsOneWidget);
    expect(find.text('20%'), findsOneWidget, reason: 'Max Disc');
    expect(find.text('Member privilege 10%'), findsOneWidget);
    expect(find.text('Summer 500'), findsOneWidget);
  });

  testWidgets('only Per. and THB; Save stays off until a promotion is '
      'chosen', (tester) async {
    await open(tester);
    expect(byTestId(DiscountIds.percentField), findsOneWidget);
    expect(byTestId(DiscountIds.amountField), findsOneWidget);
    await tester.enterText(field(DiscountIds.percentField), '5');
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(DiscountIds.saveButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
  });

  testWidgets('a typed code comes from GetPromotion and fills Per.', (
    tester,
  ) async {
    await open(tester);
    await typeCode(tester, 'P10');

    expect(find.text('Promo 10%'), findsOneWidget);
    expect(textField(tester, DiscountIds.percentField).controller!.text, '10');
    expect(
      textField(tester, DiscountIds.percentField).enabled,
      isFalse,
      reason: 'the promotion does not allow overwriting',
    );
    expect(textField(tester, DiscountIds.amountField).enabled, isFalse);
    expect(sale.lastExcludeMember, isFalse);

    await tapId(tester, DiscountIds.saveButton);
    final action = sale.lineActions.single;
    expect(action.rows, ['line-1']);
    expect(action.action, LineDiscountAction.add);
    expect(jsonDecode(action.value), {
      'Amount': {'CurrAmt': 0},
      'Percent': 10,
      'VADetail': {'Code': 'P10', 'Desc': 'Promo 10%'},
      'typeDiscount': '',
      'IsPercent': true,
    });
    expect(byTestId(DiscountIds.sheet), findsOneWidget, reason: 'Save stays');
  });

  testWidgets('an unknown code says not found and clears it', (tester) async {
    await open(tester);
    await typeCode(tester, 'NOPE');
    expect(find.text('Promotion code : NOPE not found.'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(textField(tester, DiscountIds.codeField).controller!.text, isEmpty);
  });

  testWidgets('a GetPromotion failure shows the server message', (
    tester,
  ) async {
    await open(tester);
    sale.promotionError = const ApiException(
      messageDesc: 'Promotion expired',
      messageCode: 'P02',
    );
    await typeCode(tester, 'P10');
    expect(find.textContaining('Promotion expired'), findsOneWidget);
  });

  testWidgets('the picker lists the promotion master; a baht promotion '
      'fills THB, editable when it allows overwrite', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.codeSearchButton);
    expect(byTestId(DiscountIds.picker), findsOneWidget);
    final row = byTestId(DiscountIds.pickerRow('B500'));
    expect(
      find.descendant(of: row, matching: find.text('Baht 500 off')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('500.00')),
      findsOneWidget,
    );

    await tapId(tester, DiscountIds.pickerRow('B500'));
    expect(textField(tester, DiscountIds.amountField).controller!.text, '500');
    expect(textField(tester, DiscountIds.amountField).enabled, isTrue);
    expect(textField(tester, DiscountIds.percentField).enabled, isFalse);

    await tester.enterText(field(DiscountIds.amountField), '300');
    await tapId(tester, DiscountIds.saveCloseButton);
    final sent = jsonDecode(sale.lineActions.single.value) as Map;
    expect(sent['IsPercent'], isFalse);
    expect(sent['Amount'], {'CurrAmt': 300});
    expect(byTestId(DiscountIds.sheet), findsNothing, reason: 'Save & Close');
  });

  testWidgets('a scanned promotion QR is added by code', (tester) async {
    await open(tester);
    await tester.enterText(field(DiscountIds.scanField), 'QR-123');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(sale.lineActions.single.action, LineDiscountAction.addByQrCode);
    expect(sale.lineActions.single.value, 'QR-123');
  });

  testWidgets('removing a discount sends its Guid', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.discountRemove(1));
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(sale.lineActions.single.action, LineDiscountAction.remove);
    expect(sale.lineActions.single.value, '["va-2"]');
  });

  testWidgets('Clear All clears the line', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.clearAllButton);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(sale.lineActions.single.action, LineDiscountAction.clearAll);
  });

  testWidgets('an overwritable privilege is edited with '
      'update_item_discount', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.discountRow(0));
    expect(textField(tester, DiscountIds.percentField).controller!.text, '10');
    await tester.enterText(field(DiscountIds.percentField), '15');
    await tapId(tester, DiscountIds.saveButton);

    final action = sale.lineActions.single;
    expect(action.action, LineDiscountAction.update);
    final sent = jsonDecode(action.value) as Map;
    expect(sent['Guid'], 'va-1', reason: 'the original ValueAdjust');
    expect(sent['Percent'], 15);
    expect(sent['typeDiscount'], 'Privilege');
  });

  testWidgets('any other discount is not editable', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.discountRow(1));
    expect(find.text('Promotion not allow to edit discount'), findsOneWidget);
  });

  testWidgets('a rejected save shows the server message and stays', (
    tester,
  ) async {
    await open(tester);
    await typeCode(tester, 'P10');
    sale.mutationError = const ApiException(
      messageDesc: 'Over max discount',
      messageCode: 'D01',
    );
    await tapId(tester, DiscountIds.saveCloseButton);
    expect(find.text('D01: Over max discount'), findsOneWidget);
  });

  testWidgets('without a discount permission it does not open', (tester) async {
    await open(tester, session: _noPermission);
    expect(find.text("Sorry, you don't have permission."), findsOneWidget);
    expect(byTestId(DiscountIds.sheet), findsNothing);
  });

  testWidgets('project design: net bar shows the line net; a quick-set chip '
      'fills Per.; Cancel closes', (tester) async {
    await open(tester);
    expect(
      find.descendant(
        of: byTestId(DiscountIds.netPreview),
        matching: find.text('฿5,080.00'),
      ),
      findsOneWidget,
    );
    await tapId(tester, DiscountIds.preset(5));
    expect(textField(tester, DiscountIds.percentField).controller!.text, '5');
    expect(
      textField(tester, DiscountIds.amountField).enabled,
      isFalse,
      reason: 'a percent locks THB, as typing does',
    );
    await tapId(tester, DiscountIds.cancelButton);
    expect(byTestId(DiscountIds.sheet), findsNothing);
    expect(sale.lineActions, isEmpty);
  });

  testWidgets('the picker (currency picker frame) re-queries the promotion '
      'master as the cashier types; Close picks nothing', (tester) async {
    await open(tester);
    await tapId(tester, DiscountIds.codeSearchButton);
    expect(find.text('Promotions'), findsOneWidget);
    await tester.enterText(field(DiscountIds.pickerSearch), 'B5');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(sale.lastPromotionQuery, 'B5');
    expect(byTestId(DiscountIds.pickerRow('B500')), findsOneWidget);
    expect(byTestId(DiscountIds.pickerRow('P10')), findsNothing);

    await tapId(tester, DiscountIds.pickerClearButton);
    expect(textField(tester, DiscountIds.pickerSearch).controller!.text, '');
    expect(sale.lastPromotionQuery, '', reason: 'lists the master again');
    expect(byTestId(DiscountIds.pickerRow('P10')), findsOneWidget);
    expect(byTestId(DiscountIds.pickerClearButton), findsNothing);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.picker), findsNothing);
    expect(textField(tester, DiscountIds.codeField).controller!.text, isEmpty);
  });

  testWidgets('desktop: the picker is a dialog and fills the form', (
    tester,
  ) async {
    await open(tester, desktop: true);
    await tapId(tester, DiscountIds.codeSearchButton);
    expect(byTestId(DiscountIds.picker), findsOneWidget);
    await tapId(tester, DiscountIds.pickerRow('P10'));
    expect(find.text('Promo 10%'), findsOneWidget);
    expect(textField(tester, DiscountIds.percentField).controller!.text, '10');
  });

  testWidgets('tapping Per. clears THB and tapping THB clears Per., even '
      'while it is locked', (tester) async {
    await open(tester);
    final percent = textField(tester, DiscountIds.percentField).controller!;
    final amount = textField(tester, DiscountIds.amountField).controller!;

    await tester.enterText(field(DiscountIds.percentField), '10');
    await tester.pump();
    expect(textField(tester, DiscountIds.amountField).enabled, isFalse);

    await tapId(tester, DiscountIds.amountField);
    expect(percent.text, isEmpty);
    expect(textField(tester, DiscountIds.amountField).enabled, isTrue);

    await tester.enterText(field(DiscountIds.amountField), '300');
    await tester.pump();
    await tapId(tester, DiscountIds.percentField);
    expect(amount.text, isEmpty);
    expect(textField(tester, DiscountIds.percentField).enabled, isTrue);
  });

  testWidgets('a baht promotion keeps THB: tapping Per. does nothing', (
    tester,
  ) async {
    await open(tester);
    await tapId(tester, DiscountIds.codeSearchButton);
    await tapId(tester, DiscountIds.pickerRow('B500'));
    await tapId(tester, DiscountIds.percentField);
    expect(textField(tester, DiscountIds.amountField).controller!.text, '500');
    expect(textField(tester, DiscountIds.percentField).enabled, isFalse);
  });

  testWidgets('Per. cannot go above 100%', (tester) async {
    await open(tester);
    final percent = textField(tester, DiscountIds.percentField).controller!;
    await tester.enterText(field(DiscountIds.percentField), '10');
    await tester.enterText(field(DiscountIds.percentField), '101');
    expect(percent.text, '10', reason: 'the keystroke over 100 is refused');
    await tester.enterText(field(DiscountIds.percentField), '100');
    expect(percent.text, '100');
    await tester.enterText(field(DiscountIds.percentField), '100.5');
    expect(percent.text, '100');
  });

  testWidgets('desktop: form and line detail side by side', (tester) async {
    await open(tester, desktop: true);
    expect(byTestId(DiscountIds.sheet), findsOneWidget);
    final form = tester.getRect(byTestId(DiscountIds.codeField));
    final detail = tester.getRect(byTestId(DiscountIds.lineDetail));
    expect(detail.left, greaterThan(form.right));
  });
}
