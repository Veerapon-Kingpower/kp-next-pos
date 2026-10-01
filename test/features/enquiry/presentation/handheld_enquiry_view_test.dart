import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/enquiry/presentation/handheld_enquiry_view.dart';

import '../../../helpers/test_id_finders.dart';
import '../../../helpers/test_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, {Size size = compactSize}) async {
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      TestApp(home: Scaffold(body: HandheldEnquiryView())),
    );
  }

  testWidgets('dark header with search, filters and automation ids', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(find.text('Enquiry'), findsOneWidget);
    expect(find.text('Bills, claim checks & refunds'), findsOneWidget);
    for (final id in [
      EnquiryIds.searchField,
      EnquiryIds.filterToday,
      EnquiryIds.filterMine,
      EnquiryIds.filterNotPicked,
      EnquiryIds.filterRefunded,
      EnquiryIds.reprintButton,
      EnquiryIds.refundButton,
    ]) {
      expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
    }
    handle.dispose();
  });

  testWidgets('Today is on by default; filters toggle locally', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSemantics(byTestId(EnquiryIds.filterToday)),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(byTestId(EnquiryIds.filterMine)),
      isSemantics(isSelected: false),
    );
    await tester.tap(byTestId(EnquiryIds.filterMine));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(EnquiryIds.filterMine)),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('searching says bill search is not available yet', (
    tester,
  ) async {
    await pump(tester);
    expect(
      find.descendant(
        of: byTestId(EnquiryIds.resultsNotice),
        matching: find.textContaining('Search by bill number'),
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.descendant(
        of: byTestId(EnquiryIds.searchField),
        matching: find.byType(TextField),
      ),
      '8823-',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(
      find.descendant(
        of: byTestId(EnquiryIds.resultsNotice),
        matching: find.textContaining('"8823-"'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('not available yet'), findsOneWidget);
  });

  testWidgets('Reprint and Refund are inert', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    for (final id in [EnquiryIds.reprintButton, EnquiryIds.refundButton]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    handle.dispose();
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await pump(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
  });
}
