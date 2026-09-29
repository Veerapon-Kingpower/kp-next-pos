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
    HomeLookup? lookup,
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeDashboardPage(
            scanController: controller,
            onScan: (v) => events.add('scan $v'),
            onRegister: () => events.add('register'),
            onEnquiry: () => events.add('enquiry'),
            lookup: lookup,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  HomeLookup lookup(HomeLookupStep step) => HomeLookup(
    step: step,
    body: const Text('RESULT'),
    onClear: () => events.add('clear'),
    onStartSale: step == HomeLookupStep.sale ? () => events.add('start') : null,
    onRegister: step == HomeLookupStep.register
        ? () => events.add('register customer')
        : null,
  );

  testWidgets('idle: "Who is the customer?" with the identifiers, checks '
      'after search, Start sale locked', (tester) async {
    await pump(tester);
    expect(find.text('Find customer to start a sale'), findsOneWidget);
    expect(byTestId(DesktopIds.homeIdle), findsOneWidget);
    expect(find.text('Who is the customer?'), findsOneWidget);
    for (final label in ['Shopping card', 'Passport', 'ID card']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('Shown after search.'), findsOneWidget);
    expect(
      tester.getSemantics(byTestId(ProfileIds.goToSaleButton)),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
    expect(
      tester.getSemantics(byTestId(DesktopIds.homeStep(0))),
      isSemantics(isSelected: true),
    );
  });

  testWidgets('Enter and Search both submit the scan field', (tester) async {
    await pump(tester);
    final field = find.descendant(
      of: byTestId(DesktopIds.homeScanField),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, 'CB912447');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.tap(byTestId(DesktopIds.homeSearchButton));
    expect(events, ['scan CB912447', 'scan CB912447']);
  });

  testWidgets('idle hotkeys: F2 does nothing, F3 registers, F4 enquiry', (
    tester,
  ) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    await tester.sendKeyEvent(LogicalKeyboardKey.f4);
    expect(events, ['register', 'enquiry']);
    await tester.tap(byTestId(DesktopIds.homeEnquiryButton));
    expect(events.last, 'enquiry');
  });

  testWidgets('a lookup replaces the idle panel; F2 starts, Esc clears', (
    tester,
  ) async {
    await pump(tester, lookup: lookup(HomeLookupStep.sale));
    expect(byTestId(DesktopIds.homeIdle), findsNothing);
    expect(
      find.descendant(
        of: byTestId(DesktopIds.homeLookup),
        matching: find.text('RESULT'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(byTestId(DesktopIds.homeStep(2))),
      isSemantics(isSelected: true),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(events, ['start', 'clear']);
  });

  testWidgets('an unregistered lookup: F3 registers that customer', (
    tester,
  ) async {
    await pump(tester, lookup: lookup(HomeLookupStep.register));
    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.sendKeyEvent(LogicalKeyboardKey.f3);
    expect(events, ['register customer']);
  });

  testWidgets('interactive elements expose semantics ids', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      DesktopIds.homeScanField,
      DesktopIds.homeSearchButton,
      DesktopIds.homeEnquiryButton,
      ProfileIds.goToSaleButton,
    ]) {
      expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
    }
    handle.dispose();
  });

  testWidgets('idle Home fits an iPad landscape body without scrolling', (
    tester,
  ) async {
    // 1024 × 768 less the desktop shell's 64 dp top bar.
    await pump(tester, size: const Size(1024, 704));
    final scrollable = find
        .descendant(
          of: find.byType(SingleChildScrollView).first,
          matching: find.byType(Scrollable),
        )
        .first;
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      0,
    );
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
