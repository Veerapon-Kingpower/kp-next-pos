import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/home/presentation/home_dashboard_page.dart';

import '../../../helpers/test_id_finders.dart';

void main() {
  late List<String> events;
  late TextEditingController controller;

  setUp(() {
    events = [];
    controller = TextEditingController();
  });
  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardPage(
            userName: 'Somchai P.',
            now: DateTime(2026, 8, 26, 14, 26),
            scanController: controller,
            onScan: (v) => events.add('scan $v'),
            onNewSale: () => events.add('sale'),
            onRegister: () => events.add('register'),
            onEnquiry: () => events.add('enquiry'),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  testWidgets('greets by first name and time of day', (tester) async {
    await pump(tester);
    expect(textIn(tester, DesktopIds.homeGreeting), 'Good afternoon, Somchai');
  });

  testWidgets('shift and KPI figures are unavailable, not invented', (
    tester,
  ) async {
    await pump(tester);
    expect(textIn(tester, DesktopIds.homeBillsKpi), '—');
    expect(textIn(tester, DesktopIds.homeNetSalesKpi), '—');
    expect(textIn(tester, DesktopIds.homeAvgBillKpi), '—');
    expect(
      find.descendant(
        of: byTestId(DesktopIds.homeShiftLine),
        matching: find.textContaining('not available yet'),
      ),
      findsOneWidget,
    );
    for (final id in [
      DesktopIds.homeSuspendedBills,
      DesktopIds.homePromotions,
    ]) {
      expect(
        find.descendant(
          of: byTestId(id),
          matching: find.textContaining('not available yet'),
        ),
        findsOneWidget,
        reason: id,
      );
    }
  });

  testWidgets('scanning a card submits it for customer lookup', (tester) async {
    await pump(tester);
    await tester.enterText(
      find.descendant(
        of: byTestId(DesktopIds.homeScanField),
        matching: find.byType(TextField),
      ),
      'CPX0001',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(events, ['scan CPX0001']);
  });

  testWidgets('tiles and New sale route to their destinations', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopIds.homeNewSaleButton));
    await tester.tap(byTestId(DesktopIds.homeTileSale));
    await tester.tap(byTestId(DesktopIds.homeTileRegistration));
    await tester.tap(byTestId(DesktopIds.homeTileEnquiry));
    expect(events, ['sale', 'sale', 'register', 'enquiry']);
  });

  testWidgets('F2 / F3 / F4 hotkeys work', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    expect(events, ['sale', 'register', 'enquiry']);
  });

  testWidgets('all interactive elements expose semantics ids', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      DesktopIds.homeScanField,
      DesktopIds.homeNewSaleButton,
      DesktopIds.homeTileSale,
      DesktopIds.homeTileRegistration,
      DesktopIds.homeTileEnquiry,
    ]) {
      expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
    }
    handle.dispose();
  });

  for (final size in [const Size(1024, 768), const Size(1920, 1080)]) {
    testWidgets('lays out without overflow at ${size.width.toInt()} dp', (
      tester,
    ) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
