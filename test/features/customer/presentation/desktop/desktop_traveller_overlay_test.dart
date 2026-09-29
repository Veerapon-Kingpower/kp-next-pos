import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/presentation/desktop/desktop_traveller_overlay.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';
import 'package:kp_pos/features/nationality/domain/entities/nationality.dart';

import '../../../../helpers/test_id_finders.dart';

Flight _flight(String code, String dest, String departs) => Flight(
  flightCode: code,
  flightDescription: '',
  arrDepAirportName: 'Suvarnabhumi',
  destAirportName: dest,
  flightType: 'I',
  airlineCode: code.substring(0, 2),
  flightNo: code.substring(2),
  flightDate: departs,
);

final _flights = [
  _flight('TG916', 'Frankfurt', '2026-08-18T23:45:00'),
  _flight('TG920', 'London', '2026-08-19T00:20:00'),
  _flight('TG101', 'Tokyo', '2026-08-18T10:00:00'),
];

const _portugal = Nationality(countryCode: 'PRT', countryName: 'Portugal');

void main() {
  late TravellerDetails? result;
  late bool closed;
  late List<String> flightQueries;

  Future<void> open(
    WidgetTester tester, {
    TravellerDetails initial = const TravellerDetails(),
  }) async {
    setDeviceSize(tester, const Size(1600, 1000));
    result = null;
    closed = false;
    flightQueries = [];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDesktopTravellerOverlay(
                  context,
                  initial: initial,
                  today: DateTime(2026, 8, 18),
                  searchFlights: (q) async {
                    flightQueries.add(q);
                    return _flights;
                  },
                  searchNationalities: (_) async => const [_portugal],
                );
                closed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder input(String id) =>
      find.descendant(of: byTestId(id), matching: find.byType(TextField));

  Future<void> searchFlights(WidgetTester tester, String query) async {
    await tester.enterText(input(TravellerIds.flightSearch), query);
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  testWidgets('passport pane: MRZ and boarding pass are inert, manual entry '
      'is the working path', (tester) async {
    final handle = tester.ensureSemantics();
    await open(
      tester,
      initial: const TravellerDetails(
        passportNo: 'CB912447',
        englishName: 'SOFIA ALMEIDA',
      ),
    );
    expect(byTestId(DesktopCustomerIds.traveller), findsOneWidget);
    for (final id in [
      TravellerIds.mrzScanButton,
      DesktopCustomerIds.boardingPassButton,
    ]) {
      expect(
        tester.getSemantics(byTestId(id)),
        isSemantics(hasEnabledState: true, isEnabled: false),
        reason: id,
      );
    }
    expect(
      tester
          .widget<TextField>(input(DesktopCustomerIds.travellerPassportNo))
          .controller!
          .text,
      'CB912447',
    );
    expect(find.textContaining('not checked yet'), findsOneWidget);
    expect(byTestId(TravellerIds.flightEmpty), findsOneWidget);
    handle.dispose();
  });

  testWidgets('flight search lists departures; quick filters narrow them', (
    tester,
  ) async {
    await open(tester);
    await searchFlights(tester, 'TG');
    expect(flightQueries.last, 'TG');
    expect(byTestId(TravellerIds.flight(2)), findsOneWidget);
    expect(find.text('Suvarnabhumi → Frankfurt'), findsOneWidget);

    await tester.tap(byTestId(DesktopCustomerIds.travellerFilter('tomorrow')));
    await tester.pump();
    expect(find.text('TG920'), findsOneWidget);
    expect(find.text('TG916'), findsNothing);

    await tester.tap(byTestId(DesktopCustomerIds.travellerFilter('today')));
    await tester.tap(byTestId(DesktopCustomerIds.travellerFilter('after20')));
    await tester.pump();
    expect(find.text('TG916'), findsOneWidget);
    expect(find.text('TG101'), findsNothing);
    expect(find.text('TG920'), findsNothing);
  });

  testWidgets('picking a flight shows its collection point; Save returns '
      'the details', (tester) async {
    await open(tester);
    await tester.enterText(
      input(DesktopCustomerIds.travellerPassportNo),
      'CB912447',
    );
    await tester.enterText(
      input(DesktopCustomerIds.travellerName),
      'SOFIA ALMEIDA',
    );
    await tester.enterText(input(DesktopCustomerIds.travellerNationality), 'p');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(
      byTestId(
        DesktopLookupIds.option(DesktopCustomerIds.travellerNationality, 0),
      ),
    );
    await tester.pumpAndSettle();

    await searchFlights(tester, 'TG');
    await tester.tap(byTestId(TravellerIds.flight(0)));
    await tester.pump();
    expect(
      find.descendant(
        of: byTestId(DesktopCustomerIds.collectionPoint),
        matching: find.text('Suvarnabhumi'),
      ),
      findsOneWidget,
    );

    await tester.tap(byTestId(TravellerIds.saveButton));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result!.passportNo, 'CB912447');
    expect(result!.englishName, 'SOFIA ALMEIDA');
    expect(result!.nationality!.countryCode, 'PRT');
    expect(result!.flight!.flightCode, 'TG916');
  });

  testWidgets('keeps the current flight selected; Enter saves, Esc cancels', (
    tester,
  ) async {
    await open(tester, initial: TravellerDetails(flight: _flights[2]));
    expect(
      tester.getSemantics(byTestId(TravellerIds.flight(0))),
      isSemantics(
        isSelected: true,
        isButton: true,
        hasTapAction: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result!.flight!.flightCode, 'TG101');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
