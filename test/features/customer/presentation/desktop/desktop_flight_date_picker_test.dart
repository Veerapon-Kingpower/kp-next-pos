import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/presentation/desktop/desktop_flight_date_picker.dart';

import '../../../../helpers/test_id_finders.dart';

void main() {
  // TG916 operates on the 26th at 23:45 and the 28th at 22:10 — no 27th.
  final departures = [
    DateTime(2026, 8, 26, 23, 45),
    DateTime(2026, 8, 28, 22, 10),
  ];

  late DateTime? result;
  late bool closed;

  Future<void> open(WidgetTester tester, {DateTime? initial}) async {
    setDeviceSize(tester, const Size(1440, 900));
    closed = false;
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDesktopFlightDatePicker(
                  context,
                  flightCode: 'TG916',
                  route: 'Bangkok → Frankfurt',
                  departures: departures,
                  initial: initial,
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

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).first,
      )
      .data!;

  bool enabled(WidgetTester tester, DateTime day) {
    final data = tester.getSemantics(byTestId(FlightPickerIds.day(day)));
    return data.flagsCollection.isEnabled.toBoolOrNull() ?? false;
  }

  testWidgets('opens on the first departure with its scheduled time', (
    tester,
  ) async {
    await open(tester);
    expect(byTestId(DesktopCustomerIds.flightPicker), findsOneWidget);
    expect(find.text('TG916 · Bangkok → Frankfurt'), findsOneWidget);
    expect(textIn(tester, FlightPickerIds.monthLabel), 'August 2026');
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Wed 26 Aug 2026');
    expect(textIn(tester, FlightPickerIds.selectedTime), '23:45');
  });

  testWidgets('only the flight\'s operating days from the first are pickable', (
    tester,
  ) async {
    await open(tester);
    expect(enabled(tester, DateTime(2026, 8, 25)), isFalse);
    expect(enabled(tester, DateTime(2026, 8, 26)), isTrue);
    expect(enabled(tester, DateTime(2026, 8, 27)), isFalse);
    expect(enabled(tester, DateTime(2026, 8, 28)), isTrue);
    // Nothing before the first departure's month.
    expect(
      tester
          .widget<IconButton>(
            find.descendant(
              of: byTestId(FlightPickerIds.previousMonth),
              matching: find.byType(IconButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('picking a day takes that day\'s departure time from the '
      'schedule', (tester) async {
    await open(tester);
    await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 8, 28))));
    await tester.pump();
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Fri 28 Aug 2026');
    expect(textIn(tester, FlightPickerIds.selectedTime), '22:10');
    expect(byTestId(DesktopCustomerIds.departure(0)), findsOneWidget);

    await tester.tap(byTestId(FlightPickerIds.confirmButton));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, DateTime(2026, 8, 28, 22, 10));
  });

  testWidgets('Enter confirms, starting from the initial selection', (
    tester,
  ) async {
    await open(tester, initial: DateTime(2026, 8, 28, 22, 10));
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Fri 28 Aug 2026');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(result, DateTime(2026, 8, 28, 22, 10));
  });

  testWidgets('Esc and Cancel close without a result', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(result, isNull);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(FlightPickerIds.cancelButton));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });
}
