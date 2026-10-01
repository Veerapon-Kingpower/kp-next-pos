import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/presentation/widgets/desktop_data_table.dart';
import 'package:kp_pos/features/enquiry/presentation/enquiry_page.dart';

import '../../../helpers/test_id_finders.dart';
import '../../../helpers/test_app.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(1440, 900),
  }) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      TestApp(
        home: Scaffold(body: EnquiryPage(today: DateTime(2026, 8, 26))),
      ),
    );
  }

  testWidgets('filter row, results table and detail panel', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(find.byType(DesktopDataTable), findsOneWidget);
    for (final label in [
      'Shopping card',
      'Time',
      'Customer',
      'Lines',
      'Net paid',
      'Status',
    ]) {
      expect(find.text(label), findsWidgets, reason: label);
    }
    for (final id in [
      EnquiryIds.searchField,
      DesktopIds.enquiryDateRange,
      DesktopIds.enquiryStatus,
      DesktopIds.enquirySearchButton,
      EnquiryIds.reprintButton,
      EnquiryIds.refundButton,
      DesktopIds.enquiryOpenBillButton,
    ]) {
      expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
    }
    expect(
      find.descendant(
        of: byTestId(DesktopIds.enquiryDateRange),
        matching: find.text('26 Aug 2026'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: byTestId(DesktopIds.enquiryDetail),
        matching: find.textContaining('Select a bill'),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('Search (button or Enter) reports search as unavailable', (
    tester,
  ) async {
    await pump(tester);
    final field = find.descendant(
      of: byTestId(EnquiryIds.searchField),
      matching: find.byType(TextField),
    );
    await tester.enterText(field, '8823-');
    await tester.tap(byTestId(DesktopIds.enquirySearchButton));
    await tester.pump();
    expect(
      find.descendant(
        of: byTestId(EnquiryIds.resultsNotice),
        matching: find.textContaining('"8823-"'),
      ),
      findsOneWidget,
    );

    await tester.enterText(field, 'CPX0001');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.textContaining('"CPX0001"'), findsOneWidget);
    expect(find.textContaining('not available yet'), findsOneWidget);
  });

  testWidgets('status filter is a local choice', (tester) async {
    await pump(tester);
    await tester.tap(byTestId(DesktopIds.enquiryStatus));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Refunded').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: byTestId(DesktopIds.enquiryStatus),
        matching: find.text('Refunded'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Reprint, Refund and Open bill are inert', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [
      EnquiryIds.reprintButton,
      EnquiryIds.refundButton,
      DesktopIds.enquiryOpenBillButton,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    handle.dispose();
  });

  for (final size in [
    const Size(1024 - 84, 768),
    const Size(1920 - 84, 1016),
  ]) {
    testWidgets('no overflow at ${size.width.toInt()} dp body width', (
      tester,
    ) async {
      await pump(tester, size: size);
      expect(tester.takeException(), isNull);
    });
  }
}
