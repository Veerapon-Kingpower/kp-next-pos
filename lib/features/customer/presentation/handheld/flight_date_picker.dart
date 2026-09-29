import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `Wed 26 Aug 2026`.
String formatFlightPickerDate(DateTime date) =>
    '${_weekdays[date.weekday - 1]} ${date.day} '
    '${_months[date.month - 1].substring(0, 3)} ${date.year}';

/// Flight date & time picker (mockup screen 13) — bottom sheet on phones,
/// dialog on tablets. Resolves to the picked date (date-only), or null.
///
/// Mirrors the registration page's legacy rules: the TIME is fixed by the
/// flight schedule (shown, not editable); days before [firstDate] are
/// unavailable, and when [allowedDates] (the flight's resolved operating
/// dates, date-only) is non-empty only those days can be picked.
Future<DateTime?> showFlightDatePicker(
  BuildContext context, {
  required String flightCode,
  required DateTime firstDate,
  required DateTime initialDate,
  required TimeOfDay time,
  Set<DateTime> allowedDates = const {},
}) {
  return showHandheldSheet<DateTime>(
    context,
    id: FlightPickerIds.sheet,
    builder: (_) => _FlightDatePicker(
      flightCode: flightCode,
      firstDate: _dateOnly(firstDate),
      initialDate: _dateOnly(initialDate),
      time: time,
      allowedDates: allowedDates.map(_dateOnly).toSet(),
    ),
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class _FlightDatePicker extends StatefulWidget {
  final String flightCode;
  final DateTime firstDate;
  final DateTime initialDate;
  final TimeOfDay time;
  final Set<DateTime> allowedDates;

  const _FlightDatePicker({
    required this.flightCode,
    required this.firstDate,
    required this.initialDate,
    required this.time,
    required this.allowedDates,
  });

  @override
  State<_FlightDatePicker> createState() => _FlightDatePickerState();
}

class _FlightDatePickerState extends State<_FlightDatePicker> {
  late DateTime _selected = widget.initialDate;
  late DateTime _month = DateTime(
    widget.initialDate.year,
    widget.initialDate.month,
  );

  bool _selectable(DateTime day) {
    if (day.isBefore(widget.firstDate)) return false;
    return widget.allowedDates.isEmpty || widget.allowedDates.contains(day);
  }

  bool get _canGoBack => DateTime(
    _month.year,
    _month.month,
  ).isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final hh = widget.time.hour.toString().padLeft(2, '0');
    final mm = widget.time.minute.toString().padLeft(2, '0');

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.flight_takeoff,
                size: 19,
                color: AppColors.goldDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Flight date & time',
                      style: HandheldText.title.copyWith(fontSize: 18),
                    ),
                    Text(
                      '${widget.flightCode} · departure time from schedule',
                      style: HandheldText.bodySmall.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              TestId(
                FlightPickerIds.closeButton,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    id: FlightPickerIds.selectedDate,
                    label: 'Selected',
                    labelColor: AppColors.gold,
                    value: formatFlightPickerDate(_selected),
                  ),
                ),
                _SummaryValue(
                  id: FlightPickerIds.selectedTime,
                  label: 'Time',
                  labelColor: Colors.white.withValues(alpha: 0.6),
                  value: '$hh:$mm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TestId(
                FlightPickerIds.previousMonth,
                child: IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous month',
                  onPressed: _canGoBack ? () => _shiftMonth(-1) : null,
                ),
              ),
              Expanded(
                child: TestId(
                  FlightPickerIds.monthLabel,
                  child: Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              TestId(
                FlightPickerIds.nextMonth,
                child: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next month',
                  onPressed: () => _shiftMonth(1),
                ),
              ),
            ],
          ),
          _MonthGrid(
            month: _month,
            selected: _selected,
            selectable: _selectable,
            onSelect: (day) => setState(() => _selected = day),
          ),
          const SizedBox(height: 8),
          const Text(
            'Past dates are unavailable — a flight must depart today or '
            'later. Only days this flight operates can be picked.',
            style: TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: HandheldPrimaryButton(
                  id: FlightPickerIds.confirmButton,
                  label: 'Confirm',
                  onPressed: () => Navigator.of(context).pop(_selected),
                ),
              ),
              const SizedBox(width: 10),
              HandheldSecondaryButton(
                id: FlightPickerIds.cancelButton,
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  final String id;
  final String label;
  final Color labelColor;
  final String value;

  const _SummaryValue({
    required this.id,
    required this.label,
    required this.labelColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: HandheldText.overline.copyWith(color: labelColor),
        ),
        const SizedBox(height: 4),
        TestId(
          id,
          child: Text(
            value,
            style: HandheldText.title.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final bool Function(DateTime day) selectable;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.selectable,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Sunday-first grid, as in the mockup.
    final leading = DateTime(month.year, month.month).weekday % 7;
    final cells = <Widget>[
      for (final d in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
        Center(
          child: Text(
            d,
            style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          selected: selected == DateTime(month.year, month.month, day),
          enabled: selectable(DateTime(month.year, month.month, day)),
          onTap: onSelect,
        ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < cells.length; i += 7) {
      final slice = cells.sublist(i, (i + 7).clamp(0, cells.length));
      rows.add(
        SizedBox(
          height: i == 0 ? 28 : 44,
          child: Row(
            children: [
              for (var j = 0; j < 7; j++)
                Expanded(child: j < slice.length ? slice[j] : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool selected;
  final bool enabled;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.date,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : const Color(0xFFC3C9D2);
    return TestId(
      FlightPickerIds.day(date),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: formatFlightPickerDate(date),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: selected ? AppColors.goldDark : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: enabled ? () => onTap(date) : null,
              borderRadius: BorderRadius.circular(8),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: selected ? 15 : 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
