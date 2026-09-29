import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/presentation/handheld/discount_sheet.dart';

import '../../../../helpers/test_id_finders.dart';

const _line = CartItem(
  row: '5',
  articleCode: '1001',
  articleName: 'GUCCI GG MARMONT SMALL SHOULDER BAG',
  quantity: 1,
  unitPrice: 62000,
  lineTotal: 62000,
);

void main() {
  Widget host() => MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showDiscountSheet(context, line: _line, lineNumber: 5),
          child: const Text('open'),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, {Size size = compactSize}) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  String preview(WidgetTester tester) => tester
      .widget<Text>(
        find
            .descendant(
              of: byTestId(DiscountIds.netPreview),
              matching: find.byType(Text),
            )
            .last,
      )
      .data!;

  testWidgets('shows the line being discounted and its current net', (
    tester,
  ) async {
    await open(tester);
    expect(byTestId(DiscountIds.sheet), findsOneWidget);
    expect(find.text('Discount · line 5'), findsOneWidget);
    expect(find.text('GUCCI GG MARMONT SMALL SHOULDER BAG'), findsOneWidget);
    expect(preview(tester), '฿62,000.00');
  });

  testWidgets('a percent preset updates the net preview', (tester) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.preset(10)));
    await tester.pump();
    expect(preview(tester), '฿55,800.00');
    final field = tester.widget<TextField>(
      find.descendant(
        of: byTestId(DiscountIds.valueField),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller!.text, '10');
  });

  testWidgets('typed percent is clamped to 100', (tester) async {
    await open(tester);
    await tester.enterText(
      find.descendant(
        of: byTestId(DiscountIds.valueField),
        matching: find.byType(TextField),
      ),
      '150',
    );
    await tester.pump();
    expect(preview(tester), '฿0.00');
  });

  testWidgets('Amount mode subtracts baht and hides the % presets', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.modeAmount));
    await tester.pump();
    expect(byTestId(DiscountIds.preset(10)), findsNothing);
    await tester.enterText(
      find.descendant(
        of: byTestId(DiscountIds.valueField),
        matching: find.byType(TextField),
      ),
      '6200',
    );
    await tester.pump();
    expect(preview(tester), '฿55,800.00');
  });

  testWidgets('Promo mode takes a code and leaves the net unchanged', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.modePromo));
    await tester.pump();
    await tester.enterText(
      find.descendant(
        of: byTestId(DiscountIds.valueField),
        matching: find.byType(TextField),
      ),
      'ELITE-3X',
    );
    await tester.pump();
    expect(preview(tester), '฿62,000.00');
  });

  testWidgets('Apply is inert until the sale engine exposes discounts', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(byTestId(DiscountIds.applyButton)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    expect(find.textContaining('not available yet'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('Cancel and the close icon dismiss the sheet', (tester) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.cancelButton));
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(DiscountIds.closeButton));
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsNothing);
  });

  testWidgets('mode tabs are selectable semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(byTestId(DiscountIds.modePercent)),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('iPad portrait: opens as a dialog without overflow', (
    tester,
  ) async {
    await open(tester, size: mediumSize);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
