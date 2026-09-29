import 'package:flutter/material.dart';

import '../../../../core/presentation/handheld/handheld.dart';
import '../../../../core/presentation/test_ids.dart';
import '../../../../core/presentation/widgets/test_id.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flight/domain/entities/flight.dart';
import '../../domain/entities/customer.dart';

/// Traveller details — passport & flight (mockup screen 9).
///
/// Passport data comes from the customer record; MRZ reading is deferred
/// (see project memory) so the scan button is inert and expiry shows "—".
/// Flight search is real ([searchFlights], the registration flow's
/// `Flight/GetFlightByCode`) and a result can be selected locally. There is
/// no "departures today" feed or gate / delay status, and no API to attach
/// a flight to the customer outside the registration Update, so Save
/// details is inert.
// TODO(pos-handheld): MRZ scan, departures-today feed with gate / status,
// and saving the chosen flight to the customer + Collect lines.
class TravellerDetailsPage extends StatefulWidget {
  final Customer customer;
  final Future<List<Flight>> Function(String query) searchFlights;

  const TravellerDetailsPage({
    super.key,
    required this.customer,
    required this.searchFlights,
  });

  @override
  State<TravellerDetailsPage> createState() => _TravellerDetailsPageState();
}

class _TravellerDetailsPageState extends State<TravellerDetailsPage> {
  final _query = TextEditingController();
  List<Flight> _results = const [];
  bool _searching = false;
  String? _error;
  int? _selected;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
      _selected = null;
    });
    try {
      final results = await widget.searchFlights(query);
      if (!mounted) return;
      setState(() => _results = results);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _error = 'Could not search flights.';
      });
    }
    if (mounted) setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.customer.person;
    return TestId(
      TravellerIds.page,
      child: HandheldScaffold(
        header: const HandheldHeader(
          title: 'Traveller details',
          subtitle: 'Passport & departing flight',
          leading: BackButton(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TestId(
                TravellerIds.passportCard,
                child: HandheldSection(
                  title: 'Passport',
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TestId(
                            TravellerIds.mrzScanButton,
                            child: Semantics(
                              button: true,
                              enabled: false,
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cream,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.goldMuted,
                                    width: 2,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.qr_code_scanner,
                                      size: 16,
                                      color: AppColors.goldDark,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'MRZ scan not available yet',
                                        style: TextStyle(
                                          color: AppColors.goldDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _Pair(
                            'Name',
                            person.englishName.isEmpty
                                ? '—'
                                : person.englishName.toUpperCase(),
                          ),
                          _Pair(
                            'Passport',
                            person.passportNo.isEmpty ? '—' : person.passportNo,
                          ),
                          _Pair(
                            'Nationality',
                            person.nationality.isEmpty
                                ? '—'
                                : person.nationality,
                          ),
                          const _Pair('Expiry', '—'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'DEPARTING FLIGHT',
                style: HandheldText.overline.copyWith(
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 8),
              TestId(
                TravellerIds.flightSearch,
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.flight_takeoff),
                    hintText: 'Search flight code, e.g. TG916',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_searching)
                const LinearProgressIndicator(minHeight: 2)
              else if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.danger))
              else if (_results.isEmpty)
                const TestId(
                  TravellerIds.flightEmpty,
                  child: Text(
                    'Search a flight code to link the departing flight.',
                    style: HandheldText.bodySmall,
                  ),
                )
              else
                for (var i = 0; i < _results.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _FlightRow(
                    id: TravellerIds.flight(i),
                    flight: _results[i],
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
                ],
              const SizedBox(height: 12),
              const Text(
                'Saving the flight here is not available yet — use Edit on '
                'the customer profile to change the registered flight.',
                style: HandheldText.bodySmall,
              ),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: const HandheldPrimaryButton(
            id: TravellerIds.saveButton,
            label: 'Save details',
          ),
          secondary: HandheldSecondaryButton(
            id: TravellerIds.cancelButton,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  final String label;
  final String value;

  const _Pair(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlightRow extends StatelessWidget {
  final String id;
  final Flight flight;
  final bool selected;
  final VoidCallback onTap;

  const _FlightRow({
    required this.id,
    required this.flight,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateTime.tryParse(flight.flightDate);
    final hhmm = time == null
        ? ''
        : '${time.hour.toString().padLeft(2, '0')}:'
              '${time.minute.toString().padLeft(2, '0')}';
    return TestId(
      id,
      child: Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: true,
        child: Material(
          color: selected ? AppColors.cream : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            side: BorderSide(
              color: selected ? AppColors.goldDark : AppColors.line,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(HandheldMetrics.radius),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    child: Text(
                      flight.flightCode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          flight.flightDescription.isEmpty
                              ? '${flight.arrDepAirportName} → '
                                    '${flight.destAirportName}'
                              : flight.flightDescription,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (flight.arrDepAirportName.isNotEmpty)
                          Text(
                            flight.arrDepAirportName,
                            style: HandheldText.bodySmall.copyWith(
                              fontSize: 11.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    hhmm,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
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
