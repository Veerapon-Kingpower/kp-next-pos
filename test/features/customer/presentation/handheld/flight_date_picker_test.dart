import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/features/customer/presentation/handheld/flight_date_picker.dart';

import '../../../../helpers/test_id_finders.dart';
import '../../../../helpers/test_app.dart';

void main() {
  DateTime? picked;
  var closed = false;

  Future<void> open(
    WidgetTester tester, {
    Set<DateTime>? allowed,
    Size size = compactSize,
  }) async {
    picked = null;
    closed = false;
    setDeviceSize(tester, size);
    await tester.pumpWidget(
      TestApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await showFlightDatePicker(
                  context,
                  flightCode: 'TG916',
                  firstDate: DateTime(2026, 8, 26),
                  initialDate: DateTime(2026, 8, 26),
                  time: const TimeOfDay(hour: 23, minute: 45),
                  allowedDates:
                      allowed ??
                      {
                        DateTime(2026, 8, 26),
                        DateTime(2026, 8, 27),
                        DateTime(2026, 8, 29),
                        DateTime(2026, 9, 2),
                      },
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

  bool enabled(WidgetTester tester, DateTime day) {
    final semantics = tester.getSemantics(byTestId(FlightPickerIds.day(day)));
    return semantics.flagsCollection.isEnabled.toBoolOrNull() ?? false;
  }

  String textIn(WidgetTester tester, String id) => tester
      .widget<Text>(
        find.descendant(of: byTestId(id), matching: find.byType(Text)).last,
      )
      .data!;

  test('formatFlightPickerDate', () {
    expect(formatFlightPickerDate(DateTime(2026, 8, 26)), 'Wed 26 Aug 2026');
    expect(formatFlightPickerDate(DateTime(2026, 9, 2)), 'Wed 2 Sep 2026');
  });

  testWidgets('shows the flight, selected date, schedule time and month', (
    tester,
  ) async {
    await open(tester);
    expect(byTestId(FlightPickerIds.sheet), findsOneWidget);
    expect(find.text('TG916 · departure time from schedule'), findsOneWidget);
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Wed 26 Aug 2026');
    expect(textIn(tester, FlightPickerIds.selectedTime), '23:45');
    expect(textIn(tester, FlightPickerIds.monthLabel), 'August 2026');
  });

  testWidgets('past and non-operating days are disabled', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(enabled(tester, DateTime(2026, 8, 25)), isFalse, reason: 'past');
    expect(
      enabled(tester, DateTime(2026, 8, 28)),
      isFalse,
      reason: 'no flight',
    );
    expect(enabled(tester, DateTime(2026, 8, 27)), isTrue);
    expect(find.textContaining('Past dates are unavailable'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('with no candidate list, any future day is selectable', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester, allowed: const {});
    expect(enabled(tester, DateTime(2026, 8, 28)), isTrue);
    expect(enabled(tester, DateTime(2026, 8, 25)), isFalse);
    handle.dispose();
  });

  testWidgets('tapping a day updates the summary; Confirm returns it', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 8, 29))));
    await tester.pump();
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Sat 29 Aug 2026');

    await tester.tap(byTestId(FlightPickerIds.confirmButton));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(picked, DateTime(2026, 8, 29));
  });

  testWidgets('month navigation; cannot go before the first month', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await open(tester);
    expect(
      tester.getSemantics(byTestId(FlightPickerIds.previousMonth)),
      isSemantics(hasEnabledState: true, isEnabled: false),
    );
    await tester.tap(byTestId(FlightPickerIds.nextMonth));
    await tester.pump();
    expect(textIn(tester, FlightPickerIds.monthLabel), 'September 2026');
    await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 9, 2))));
    await tester.pump();
    expect(textIn(tester, FlightPickerIds.selectedDate), 'Wed 2 Sep 2026');
    handle.dispose();
  });

  testWidgets('Cancel returns null', (tester) async {
    await open(tester);
    await tester.tap(byTestId(FlightPickerIds.cancelButton));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(picked, isNull);
  });

  testWidgets('iPad portrait: dialog, no overflow', (tester) async {
    await open(tester, size: mediumSize);
    expect(find.byType(Dialog), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
