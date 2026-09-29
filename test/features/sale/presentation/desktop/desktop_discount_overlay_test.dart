import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/presentation/desktop/desktop_discount_overlay.dart';

import '../../../../helpers/test_id_finders.dart';

const _bag = CartItem(
  row: '5',
  articleCode: '8056376334517',
  articleName: 'GUCCI GG MARMONT SMALL SHOULDER BAG',
  quantity: 1,
  unitPrice: 62000,
  lineTotal: 62000,
);

void main() {
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDesktopDiscountOverlay(
                context,
                line: _bag,
                lineNumber: 5,
                billNet: 93570,
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

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  Finder valueField() => find.descendant(
    of: byTestId(DiscountIds.valueField),
    matching: find.byType(TextField),
  );

  testWidgets('title names the line; preview starts undiscounted', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Discount · line 5'), findsOneWidget);
    expect(find.textContaining('8056376334517'), findsOneWidget);
    expect(textIn(tester, DiscountIds.netPreview), '฿62,000.00');
  });

  testWidgets('quick set 10% previews line net and bill delta', (tester) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.preset(10)));
    await tester.pump();
    expect(textIn(tester, DiscountIds.lineDiscount), '−6,200.00');
    expect(textIn(tester, DiscountIds.netPreview), '฿55,800.00');
    expect(
      find.descendant(
        of: byTestId(DiscountIds.billDelta),
        matching: find.text(
          'Bill net pay would move from ฿93,570.00 to ฿87,370.00',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Amount and New price modes', (tester) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.modeAmount));
    await tester.pump();
    await tester.enterText(valueField(), '6200');
    await tester.pump();
    expect(textIn(tester, DiscountIds.netPreview), '฿55,800.00');

    await tester.tap(byTestId(DiscountIds.modeNewPrice));
    await tester.pump();
    await tester.enterText(valueField(), '60000');
    await tester.pump();
    expect(textIn(tester, DiscountIds.netPreview), '฿60,000.00');
  });

  testWidgets('Promotion code mode leaves the net to the sale engine', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.modePromo));
    await tester.pump();
    await tester.enterText(valueField(), 'ELITE-3X');
    await tester.pump();
    expect(textIn(tester, DiscountIds.netPreview), '฿62,000.00');
  });

  testWidgets('Clear resets the entry', (tester) async {
    await open(tester);
    await tester.tap(byTestId(DiscountIds.preset(10)));
    await tester.pump();
    await tester.tap(byTestId(DiscountIds.clearButton));
    await tester.pump();
    expect(textIn(tester, DiscountIds.netPreview), '฿62,000.00');
  });

  testWidgets('Apply is inert; ceilings and promotions are not invented', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(byTestId(DiscountIds.applyButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    expect(find.textContaining('max'), findsNothing);
    expect(
      find.descendant(
        of: byTestId(DiscountIds.promotions),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Esc and Cancel close the overlay', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(DiscountIds.cancelButton));
    await tester.pumpAndSettle();
    expect(byTestId(DiscountIds.sheet), findsNothing);
  });

  testWidgets('fits 1024 dp without overflow', (tester) async {
    await open(tester, size: const Size(1024, 768));
    expect(tester.takeException(), isNull);
  });
}
