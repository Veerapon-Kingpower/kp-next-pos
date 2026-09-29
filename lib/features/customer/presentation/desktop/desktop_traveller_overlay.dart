import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/presentation/desktop/desktop.dart';
import '../../../../core/presentation/form_inputs.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/app_text_field.dart'
    show ClearFieldButton;
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../../nationality/domain/entities/nationality.dart';

/// What the Flight & passport overlay captures — the customer form's own
/// passport / name / nationality / flight fields.
class TravellerDetails {
  final String passportNo;
  final String englishName;
  final Nationality? nationality;
  final Flight? flight;

  const TravellerDetails({
    this.passportNo = '',
    this.englishName = '',
    this.nationality,
    this.flight,
  });
}

/// Flight & passport capture (POS Desktop mockup screen 9), over the
/// customer form. Resolves to the entered details on Save (Enter), or null
/// on Cancel / Esc.
///
/// Real: manual passport no. / English name / nationality, flight search
/// ([searchFlights], `Flight/GetFlightByCode`) with Today / Tomorrow /
/// After 20:00 filters on the results' departure times, and the picked
/// flight's departure airport as the collection point. Not available, so
/// inert or left out rather than invented: MRZ and boarding-pass reads,
/// date of birth / expiry (not on the register API), flight status / gate,
/// region filters, the pickup counter and allowance checks.
// TODO(pos-desktop): camera MRZ scan and boarding-pass barcode (openspec
// 7.9); departures feed with status / gate; allowance checks.
Future<TravellerDetails?> showDesktopTravellerOverlay(
  BuildContext context, {
  required TravellerDetails initial,
  required Future<List<Flight>> Function(String query) searchFlights,
  required Future<List<Nationality>> Function(String query) searchNationalities,
  DateTime? today,
}) {
  return showDialog<TravellerDetails>(
    context: context,
    barrierColor: AppColors.ink.withValues(alpha: 0.55),
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(40),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280, maxHeight: 860),
        child: _TravellerOverlay(
          initial: initial,
          searchFlights: searchFlights,
          searchNationalities: searchNationalities,
          today: today ?? DateTime.now(),
        ),
      ),
    ),
  );
}

enum _DayFilter { any, today, tomorrow }

class _TravellerOverlay extends StatefulWidget {
  final TravellerDetails initial;
  final Future<List<Flight>> Function(String query) searchFlights;
  final Future<List<Nationality>> Function(String query) searchNationalities;
  final DateTime today;

  const _TravellerOverlay({
    required this.initial,
    required this.searchFlights,
    required this.searchNationalities,
    required this.today,
  });

  @override
  State<_TravellerOverlay> createState() => _TravellerOverlayState();
}

class _TravellerOverlayState extends State<_TravellerOverlay> {
  late final _passportNo = TextEditingController(
    text: widget.initial.passportNo,
  );
  late final _englishName = TextEditingController(
    text: widget.initial.englishName,
  );
  final _query = TextEditingController();
  late final _queryFocus = FocusNode(onKeyEvent: _onQueryKey);
  late Nationality? _nationality = widget.initial.nationality;
  late Flight? _flight = widget.initial.flight;
  late List<Flight> _results = [?widget.initial.flight];
  Timer? _debounce;
  int _request = 0;
  bool _searching = false;
  String? _error;
  _DayFilter _day = _DayFilter.any;
  bool _after20 = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _passportNo.dispose();
    _englishName.dispose();
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  // Enter in the flight search runs the search rather than saving.
  KeyEventResult _onQueryKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      _search(_query.text);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String value) async {
    _debounce?.cancel();
    final query = value.trim();
    if (query.isEmpty) return;
    final request = ++_request;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await widget.searchFlights(query);
      if (!mounted || request != _request) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _results = const [];
        _error = 'Could not search flights.';
      });
    }
    if (mounted && request == _request) setState(() => _searching = false);
  }

  static DateTime? _departs(Flight f) => DateTime.tryParse(f.flightDate);

  List<Flight> get _visible {
    final today = DateTime(
      widget.today.year,
      widget.today.month,
      widget.today.day,
    );
    return [
      for (final f in _results)
        if (_matches(f, today)) f,
    ];
  }

  bool _matches(Flight flight, DateTime today) {
    if (_day == _DayFilter.any && !_after20) return true;
    final departs = _departs(flight);
    if (departs == null) return false;
    final day = DateTime(departs.year, departs.month, departs.day);
    if (_day == _DayFilter.today && day != today) return false;
    if (_day == _DayFilter.tomorrow &&
        day != DateTime(today.year, today.month, today.day + 1)) {
      return false;
    }
    if (_after20 && departs.hour < 20) return false;
    return true;
  }

  void _save() => Navigator.of(context).pop(
    TravellerDetails(
      passportNo: _passportNo.text.trim(),
      englishName: _englishName.text.trim(),
      nationality: _nationality,
      flight: _flight,
    ),
  );

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    return TestId(
      DesktopCustomerIds.traveller,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): _save,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): _save,
          const SingleActivator(LogicalKeyboardKey.escape): _cancel,
        },
        child: Focus(
          autofocus: true,
          child: Material(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(width: 460, child: _passportPane()),
                        const SizedBox(width: 20),
                        Expanded(child: _flightPane()),
                      ],
                    ),
                  ),
                ),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      color: AppColors.ink,
      padding: const EdgeInsets.fromLTRB(28, 18, 20, 18),
      child: Row(
        children: [
          const Icon(Icons.badge_outlined, color: AppColors.gold, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flight & passport',
                  style: DesktopText.screenTitle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  'Traveller details for this customer',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const DesktopHotkeyChip('ESC', onDark: true),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Close',
            onPressed: _cancel,
            icon: const Icon(Icons.close, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _passportPane() {
    return DesktopPanel(
      title: 'Passport',
      child: Expanded(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InertAction(
                id: TravellerIds.mrzScanButton,
                icon: Icons.document_scanner_outlined,
                label:
                    'MRZ read not available yet — enter the passport '
                    'details below',
              ),
              const SizedBox(height: 18),
              _textField(
                DesktopCustomerIds.travellerPassportNo,
                'Passport no.',
                _passportNo,
                FormInputs.passport,
              ),
              const SizedBox(height: 14),
              _textField(
                DesktopCustomerIds.travellerName,
                'English name',
                _englishName,
                FormInputs.englishName,
              ),
              const SizedBox(height: 14),
              DesktopLookupField<Nationality>(
                id: DesktopCustomerIds.travellerNationality,
                label: 'Nationality',
                value: _nationality,
                search: widget.searchNationalities,
                code: (n) => n.countryCode,
                name: (n) => n.countryName,
                onSelected: (n) => setState(() => _nationality = n),
              ),
              const SizedBox(height: 22),
              const Text('BOARDING PASS', style: DesktopText.fieldLabel),
              const SizedBox(height: 8),
              const _InertAction(
                id: DesktopCustomerIds.boardingPassButton,
                icon: Icons.qr_code_scanner,
                label: 'Boarding-pass scan not available yet',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 17, color: AppColors.info),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Liquor and tobacco allowances (nationality / '
                        'destination) are not checked yet — confirm them '
                        'with the customer.',
                        style: TextStyle(fontSize: 13, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField(
    String id,
    String label,
    TextEditingController c,
    List<TextInputFormatter> inputFormatters,
  ) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
    return TestId(
      id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label.toUpperCase(), style: DesktopText.fieldLabel),
          const SizedBox(height: 6),
          TextField(
            controller: c,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: inputFormatters,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixIcon: c.text.isEmpty
                  ? null
                  : ClearFieldButton(
                      id: FieldIds.clear(id),
                      controller: c,
                      onCleared: (_) => setState(() {}),
                    ),
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 18,
              ),
              border: border(const Color(0xFFD8DDE5), 1),
              enabledBorder: border(const Color(0xFFD8DDE5), 1),
              focusedBorder: border(AppColors.goldMuted, 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _flightPane() {
    final visible = _visible;
    Widget filter(String key, String label, bool on, VoidCallback onTap) =>
        TestId(
          DesktopCustomerIds.travellerFilter(key),
          child: FilterChip(
            label: Text(label),
            selected: on,
            showCheckmark: false,
            selectedColor: AppColors.cream,
            side: BorderSide(
              color: on ? AppColors.goldDark : const Color(0xFFD8DDE5),
            ),
            onSelected: (_) => onTap(),
          ),
        );

    return DesktopPanel(
      title: 'Departure flight',
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TestId(
              TravellerIds.flightSearch,
              child: TextField(
                controller: _query,
                focusNode: _queryFocus,
                onChanged: _onQueryChanged,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, size: 18),
                  hintText: 'Search flight code, e.g. TG916',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                filter(
                  'today',
                  'Today',
                  _day == _DayFilter.today,
                  () => setState(
                    () => _day = _day == _DayFilter.today
                        ? _DayFilter.any
                        : _DayFilter.today,
                  ),
                ),
                filter(
                  'tomorrow',
                  'Tomorrow',
                  _day == _DayFilter.tomorrow,
                  () => setState(
                    () => _day = _day == _DayFilter.tomorrow
                        ? _DayFilter.any
                        : _DayFilter.tomorrow,
                  ),
                ),
                filter(
                  'after20',
                  'After 20:00',
                  _after20,
                  () => setState(() => _after20 = !_after20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_searching) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: _error != null
                  ? Text(
                      _error!,
                      style: const TextStyle(color: AppColors.danger),
                    )
                  : visible.isEmpty
                  ? TestId(
                      TravellerIds.flightEmpty,
                      child: Text(
                        _results.isEmpty
                            ? 'Search a flight code to pick the departing '
                                  'flight.'
                            : 'No flights match these filters.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _FlightRow(
                        id: TravellerIds.flight(i),
                        flight: visible[i],
                        departs: _departs(visible[i]),
                        selected: identical(visible[i], _flight),
                        onTap: () => setState(() => _flight = visible[i]),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _collectionPoint(),
          ],
        ),
      ),
    );
  }

  Widget _collectionPoint() {
    final airport = _flight?.arrDepAirportName ?? '';
    return TestId(
      DesktopCustomerIds.collectionPoint,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 18,
              color: AppColors.goldDark,
            ),
            const SizedBox(width: 10),
            const Text('COLLECTION POINT', style: DesktopText.fieldLabel),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _flight == null
                    ? 'Pick a flight to see where it departs.'
                    : airport.isEmpty
                    ? '—'
                    : airport,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _flight == null
                      ? FontWeight.w400
                      : FontWeight.w700,
                  color: _flight == null
                      ? AppColors.mutedText
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (_flight != null)
              const Text(
                'Pickup counter not available yet',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _footer() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          const Spacer(),
          SizedBox(
            width: 140,
            child: DesktopButton(
              id: TravellerIds.cancelButton,
              label: 'Cancel',
              secondary: true,
              height: 56,
              onPressed: _cancel,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 320,
            child: DesktopButton(
              id: TravellerIds.saveButton,
              label: 'Save traveller details',
              icon: Icons.check,
              hotkey: 'ENTER',
              height: 56,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _InertAction extends StatelessWidget {
  final String id;
  final IconData icon;
  final String label;

  const _InertAction({
    required this.id,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TestId(
      id,
      child: Semantics(
        button: true,
        enabled: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.goldMuted),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlightRow extends StatelessWidget {
  final String id;
  final Flight flight;
  final DateTime? departs;
  final bool selected;
  final VoidCallback onTap;

  const _FlightRow({
    required this.id,
    required this.flight,
    required this.departs,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final route = [
      flight.arrDepAirportName,
      flight.destAirportName,
    ].where((s) => s.isNotEmpty).join(' → ');
    final hhmm = departs == null
        ? ''
        : '${departs!.hour.toString().padLeft(2, '0')}:'
              '${departs!.minute.toString().padLeft(2, '0')}';
    final day = departs == null
        ? ''
        : '${departs!.day.toString().padLeft(2, '0')}/'
              '${departs!.month.toString().padLeft(2, '0')}';
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? const Color(0xFFFBF8F1) : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: selected ? AppColors.goldDark : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      flight.flightCode,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.isEmpty ? '—' : route,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (flight.flightDescription.isNotEmpty)
                          Text(
                            flight.flightDescription,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.mutedText,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hhmm,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (day.isNotEmpty)
                        Text(
                          day,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    size: 20,
                    color: selected ? AppColors.success : AppColors.hintText,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
