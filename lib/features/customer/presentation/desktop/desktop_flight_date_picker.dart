import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../handheld/flight_date_picker.dart' show formatFlightPickerDate;

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

/// Flight date & time picker overlay (POS Desktop mockup screen 12), over
/// the customer form. [departures] are the flight's resolved departures
/// (`getDateByFlight`) and must not be empty.
///
/// Only days with a departure, from the first one on, can be picked; the
/// time is that day's scheduled departure, never a free clock. Resolves to
/// the picked departure, or null on Cancel / Esc.
Future<DateTime?> showDesktopFlightDatePicker(
  BuildContext context, {
  required String flightCode,
  required List<DateTime> departures,
  String route = '',
  DateTime? initial,
}) {
  assert(departures.isNotEmpty);
  final sorted = [...departures]..sort();
  return showDialog<DateTime>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: _DesktopFlightDatePicker(
          flightCode: flightCode,
          route: route,
          departures: sorted,
          initial: initial,
        ),
      ),
    ),
  );
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';

class _DesktopFlightDatePicker extends StatefulWidget {
  final String flightCode;
  final String route;
  final List<DateTime> departures;
  final DateTime? initial;

  const _DesktopFlightDatePicker({
    required this.flightCode,
    required this.route,
    required this.departures,
    required this.initial,
  });

  @override
  State<_DesktopFlightDatePicker> createState() =>
      _DesktopFlightDatePickerState();
}

class _DesktopFlightDatePickerState extends State<_DesktopFlightDatePicker> {
  late DateTime _selected = _initialDeparture();
  late DateTime _month = DateTime(_selected.year, _selected.month);

  DateTime get _first => widget.departures.first;
  DateTime get _last => widget.departures.last;

  DateTime _initialDeparture() {
    final initial = widget.initial;
    if (initial != null) {
      for (final d in widget.departures) {
        if (d == initial) return d;
      }
      for (final d in widget.departures) {
        if (_dateOnly(d) == _dateOnly(initial)) return d;
      }
    }
    return widget.departures.first;
  }

  List<DateTime> _departuresOn(DateTime day) => [
    for (final d in widget.departures)
      if (_dateOnly(d) == day) d,
  ];

  bool _selectable(DateTime day) =>
      !day.isBefore(_dateOnly(_first)) && _departuresOn(day).isNotEmpty;

  bool get _canGoBack => _month.isAfter(DateTime(_first.year, _first.month));

  bool get _canGoForward => _month.isBefore(DateTime(_last.year, _last.month));

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  void _confirm() => Navigator.of(context).pop(_selected);

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      widget.flightCode,
      widget.route,
    ].where((s) => s.isNotEmpty).join(' · ');
    return TestId(
      DesktopCustomerIds.flightPicker,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _confirm,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _confirm,
          const SingleActivator(LogicalKeyboardKey.escape): _cancel,
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(subtitle: subtitle, onClose: _cancel),
                Flexible(
                  child: SingleChildScrollView(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _calendar()),
                          const VerticalDivider(
                            width: 1,
                            color: Color(0xFFEDEFF3),
                          ),
                          SizedBox(width: 320, child: _side()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _calendar() {
    Widget navButton(String id, IconData icon, String tip, VoidCallback? on) =>
        TestId(
          id,
          child: IconButton(
            tooltip: tip,
            onPressed: on,
            style: IconButton.styleFrom(
              fixedSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFD8DDE5)),
              ),
            ),
            icon: Icon(icon, size: 18),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 24, 30, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              navButton(
                FlightPickerIds.previousMonth,
                Icons.chevron_left,
                'Previous month',
                _canGoBack ? () => _shiftMonth(-1) : null,
              ),
              Expanded(
                child: TestId(
                  FlightPickerIds.monthLabel,
                  child: Text(
                    '${_months[_month.month - 1]} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: DesktopText.sectionTitle.copyWith(fontSize: 18),
                  ),
                ),
              ),
              navButton(
                FlightPickerIds.nextMonth,
                Icons.chevron_right,
                'Next month',
                _canGoForward ? () => _shiftMonth(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MonthGrid(
            month: _month,
            selected: _dateOnly(_selected),
            selectable: _selectable,
            onSelect: (day) =>
                setState(() => _selected = _departuresOn(day).first),
          ),
          const SizedBox(height: 12),
          const Text(
            'Only days this flight departs, from its first scheduled '
            'departure, can be picked.',
            style: TextStyle(fontSize: 12.5, color: AppColors.hintText),
          ),
        ],
      ),
    );
  }

  Widget _side() {
    final day = _dateOnly(_selected);
    final sameDay = _departuresOn(day);
    return Container(
      color: const Color(0xFFFAFBFC),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SELECTED',
                  style: DesktopText.fieldLabel.copyWith(color: AppColors.gold),
                ),
                const SizedBox(height: 9),
                TestId(
                  FlightPickerIds.selectedDate,
                  child: Text(
                    formatFlightPickerDate(_selected),
                    style: DesktopText.heroTitle.copyWith(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TestId(
                  FlightPickerIds.selectedTime,
                  child: Text(
                    _hhmm(_selected),
                    style: DesktopText.heroTitle.copyWith(
                      fontSize: 32,
                      height: 1,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'FROM ${widget.flightCode} SCHEDULE',
            style: DesktopText.fieldLabel,
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < sameDay.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _DepartureRow(
              id: DesktopCustomerIds.departure(i),
              time: _hhmm(sameDay[i]),
              selected: sameDay[i] == _selected,
              onTap: () => setState(() => _selected = sameDay[i]),
            ),
          ],
          const SizedBox(height: 24),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: DesktopButton(
                  id: FlightPickerIds.confirmButton,
                  label: 'Confirm',
                  hotkey: 'ENTER',
                  height: 56,
                  onPressed: _confirm,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: DesktopButton(
                  id: FlightPickerIds.cancelButton,
                  label: 'Cancel',
                  secondary: true,
                  height: 56,
                  onPressed: _cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String subtitle;
  final VoidCallback onClose;

  const _Header({required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 22, 24, 22),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEDEFF3))),
      ),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff, size: 22, color: AppColors.goldDark),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight date & time',
                  style: DesktopText.heroTitle.copyWith(fontSize: 22),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TestId(
            FlightPickerIds.closeButton,
            child: IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final String id;
  final String time;
  final bool selected;
  final VoidCallback onTap;

  const _DepartureRow({
    required this.id,
    required this.time,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: selected ? AppColors.goldDark : const Color(0xFFD8DDE5),
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Scheduled departure',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: AppColors.success,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
    // Sunday-first, as in the mockup.
    final leading = DateTime(month.year, month.month).weekday % 7;
    final cells = <Widget>[
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          date: DateTime(month.year, month.month, day),
          selected: selected == DateTime(month.year, month.month, day),
          enabled: selectable(DateTime(month.year, month.month, day)),
          onTap: onSelect,
        ),
    ];

    Widget row(List<Widget> children, double height) => SizedBox(
      height: height,
      child: Row(
        children: [
          for (var j = 0; j < 7; j++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: j < children.length ? children[j] : const SizedBox(),
              ),
            ),
        ],
      ),
    );

    return Column(
      children: [
        row([
          for (final d in const ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'])
            Center(child: Text(d.toUpperCase(), style: DesktopText.fieldLabel)),
        ], 28),
        for (var i = 0; i < cells.length; i += 7)
          row(cells.sublist(i, (i + 7).clamp(0, cells.length)), 52),
      ],
    );
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
    return TestId(
      FlightPickerIds.day(date),
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: selected,
        label: formatFlightPickerDate(date),
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
                    fontSize: selected ? 17 : 15,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: selected
                        ? Colors.white
                        : enabled
                        ? AppColors.textPrimary
                        : const Color(0xFFC3C9D2),
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
