import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/presentation/handheld/traveller_details_page.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';

import '../../../../helpers/test_id_finders.dart';
import 'customer_profile_page_test.dart' show sofia;

const _flights = [
  Flight(
    flightCode: 'TG916',
    flightDescription: 'Bangkok - Frankfurt',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Frankfurt',
    flightType: 'I',
    airlineCode: 'TG',
    flightNo: '916',
    flightDate: '2026-08-26T23:45:00',
  ),
  Flight(
    flightCode: 'TG920',
    flightDescription: 'Bangkok - London',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'London',
    flightType: 'I',
    airlineCode: 'TG',
    flightNo: '920',
    flightDate: '2026-08-27T00:20:00',
  ),
];

void main() {
  String? lastQuery;

  Future<void> open(WidgetTester tester, {Size size = compactSize}) async {
    lastQuery = null;
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        home: TravellerDetailsPage(
          customer: sofia,
          searchFlights: (q) async {
            lastQuery = q;
            return q.isEmpty ? const [] : _flights;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('passport block from the customer; MRZ scan inert', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    final card = byTestId(TravellerIds.passportCard);
    expect(
      find.descendant(of: card, matching: find.text('SOFIA ALMEIDA')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('CB912447')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card, matching: find.text('PRT')),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(byTestId(TravellerIds.mrzScanButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    handle.dispose();
  });

  testWidgets('flight search lists results and selects one', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(byTestId(TravellerIds.flightEmpty), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: byTestId(TravellerIds.flightSearch),
        matching: find.byType(TextField),
      ),
      'TG9',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(lastQuery, 'TG9');
    expect(byTestId(TravellerIds.flight(0)), findsOneWidget);
    expect(find.text('Bangkok - London'), findsOneWidget);

    await tester.ensureVisible(byTestId(TravellerIds.flight(1)));
    await tester.tap(byTestId(TravellerIds.flight(1)));
    await tester.pump();
    expect(
      tester.getSemantics(byTestId(TravellerIds.flight(1))),
      isSemantics(isSelected: true),
    );
    handle.dispose();
  });

  testWidgets('Save details is inert; Cancel closes', (tester) async {
    final handle = tester.ensureSemantics();
    setDeviceSize(tester, compactSize);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TravellerDetailsPage(
                  customer: sofia,
                  searchFlights: (_) async => const [],
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(byTestId(TravellerIds.saveButton)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    await tester.tap(byTestId(TravellerIds.cancelButton));
    await tester.pumpAndSettle();
    expect(byTestId(TravellerIds.page), findsNothing);
    handle.dispose();
  });

  testWidgets('iPad portrait renders without overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(tester.takeException(), isNull);
  });
}
