import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/home/presentation/handheld/handheld_home_view.dart';

import '../../../../helpers/test_id_finders.dart';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  Widget build({
    ValueChanged<String>? onSearch,
    VoidCallback? onRegister,
    VoidCallback? onSale,
    VoidCallback? onEnquiry,
    Widget results = const SizedBox.shrink(),
    DateTime? now,
    bool offlineMode = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            HandheldHomeHeader(
              userName: 'Somchai P.',
              module: 'PosKpi',
              branch: '03',
              offlineMode: offlineMode,
              now: now ?? DateTime(2026, 8, 26, 14, 26),
            ),
            Expanded(
              child: HandheldHomeView(
                searchController: controller,
                onSearch: onSearch ?? (_) {},
                searchResults: results,
                onRegister: onRegister ?? () {},
                onSale: onSale ?? () {},
                onEnquiry: onEnquiry ?? () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  group('HandheldHomeHeader', () {
    testWidgets('greets by time of day and shows the session line', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());

      expect(find.text('Good afternoon'), findsOneWidget);
      expect(find.text('PosKpi · Branch 03 · Somchai P.'), findsOneWidget);
      expect(find.text('SP'), findsOneWidget, reason: 'avatar initials');
      expect(byTestId(HomeIds.greeting), findsOneWidget);
      expect(byTestId(HomeIds.sessionLine), findsOneWidget);
    });

    testWidgets('morning and evening greetings', (tester) async {
      await tester.pumpWidget(build(now: DateTime(2026, 8, 26, 9)));
      expect(find.text('Good morning'), findsOneWidget);
      await tester.pumpWidget(build(now: DateTime(2026, 8, 26, 19)));
      expect(find.text('Good evening'), findsOneWidget);
    });

    testWidgets('shift stats render as — until a shift API exists', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());
      expect(find.text('BILLS'), findsOneWidget);
      expect(find.text('NET SALES'), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(HomeIds.billsStat),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(HomeIds.netSalesStat),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('sale mode badge reflects the offline-mode setting', (
      tester,
    ) async {
      await tester.pumpWidget(build());
      expect(
        find.descendant(
          of: byTestId(HomeIds.onlineStatus),
          matching: find.text('ONLINE'),
        ),
        findsOneWidget,
      );
      await tester.pumpWidget(build(offlineMode: true));
      expect(
        find.descendant(
          of: byTestId(HomeIds.onlineStatus),
          matching: find.text('OFFLINE'),
        ),
        findsOneWidget,
      );
    });
  });

  group('HandheldHomeView', () {
    testWidgets('scan field submits the scanned / typed code', (tester) async {
      setDeviceSize(tester, compactSize);
      String? searched;
      await tester.pumpWidget(build(onSearch: (v) => searched = v));

      expect(find.text('Scan shopping card or passport'), findsOneWidget);
      await tester.enterText(
        find.descendant(
          of: byTestId(HomeIds.scanField),
          matching: find.byType(TextField),
        ),
        'CPX0001',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      expect(searched, 'CPX0001');
    });

    testWidgets('the scan field has focus on open and keeps it after a scan', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());
      await tester.pump();
      bool focused() => tester
          .state<EditableTextState>(
            find.descendant(
              of: byTestId(HomeIds.scanField),
              matching: find.byType(EditableText),
            ),
          )
          .widget
          .focusNode
          .hasFocus;
      expect(focused(), isTrue);

      await tester.enterText(
        find.descendant(
          of: byTestId(HomeIds.scanField),
          matching: find.byType(TextField),
        ),
        'CPX0001',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();
      expect(focused(), isTrue);
    });

    testWidgets('the ✕ shows with text and empties the scan field', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());
      final clear = byTestId(FieldIds.clear(HomeIds.scanField));
      expect(clear, findsNothing);

      await tester.enterText(
        find.descendant(
          of: byTestId(HomeIds.scanField),
          matching: find.byType(TextField),
        ),
        'CPX0001',
      );
      await tester.pump();
      await tester.tap(clear);
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(clear, findsNothing);
    });

    testWidgets('renders the search results slot under the scan field', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build(results: const Text('Jane Doe')));
      final scanY = tester.getBottomLeft(byTestId(HomeIds.scanField)).dy;
      final resultY = tester.getTopLeft(find.text('Jane Doe')).dy;
      expect(resultY > scanY, isTrue);
    });

    testWidgets('tiles route Register / Sale / Enquiry; Checkout is inert', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      final calls = <String>[];
      await tester.pumpWidget(
        build(
          onRegister: () => calls.add('register'),
          onSale: () => calls.add('sale'),
          onEnquiry: () => calls.add('enquiry'),
        ),
      );

      await tester.tap(byTestId(HomeIds.tileRegister));
      await tester.tap(byTestId(HomeIds.tileSale));
      await tester.tap(byTestId(HomeIds.tileEnquiry));
      await tester.tap(byTestId(HomeIds.tileCheckout));
      expect(calls, ['register', 'sale', 'enquiry']);
    });

    testWidgets('all tiles expose semantics identifiers for automation', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());
      for (final id in [
        HomeIds.scanField,
        HomeIds.tileRegister,
        HomeIds.tileSale,
        HomeIds.tileCheckout,
        HomeIds.tileEnquiry,
        HomeIds.suspendedBills,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      expect(
        tester.getSemantics(byTestId(HomeIds.tileCheckout)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('suspended bills shows an honest unavailable state', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(build());
      expect(find.text('Suspended bills'), findsOneWidget);
      expect(
        find.text('Suspended bills are not available on this device yet.'),
        findsOneWidget,
      );
    });

    testWidgets('medium (iPad portrait): tiles stay 4-up and fit', (
      tester,
    ) async {
      setDeviceSize(tester, mediumSize);
      await tester.pumpWidget(build());
      final register = tester.getRect(byTestId(HomeIds.tileRegister));
      final enquiry = tester.getRect(byTestId(HomeIds.tileEnquiry));
      expect(register.top, enquiry.top, reason: 'same row');
      expect(tester.takeException(), isNull);
    });
  });
}
