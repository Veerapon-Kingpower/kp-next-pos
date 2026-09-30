import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/presentation/desktop/desktop.dart';
import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/form_inputs.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/app_text_field.dart';
import '../../../core/presentation/widgets/autocomplete_field.dart';
import '../../../core/presentation/widgets/test_id.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../flight/domain/entities/flight.dart';
import '../../nationality/domain/entities/nationality.dart';
import '../domain/entities/agent.dart';
import '../domain/entities/customer.dart';
import 'customer_registration_view_model.dart';
import 'desktop/desktop_flight_date_picker.dart';
import 'desktop/desktop_traveller_overlay.dart';
import 'handheld/flight_date_picker.dart';

/// Manual-entry "Register new customer" form, fields ordered to match
/// `customer-form.html`'s non-airport layout. Doubles as the edit-existing-
/// customer form when [existingCustomer] is given — ports
/// `customer-form.ts`'s shared add/edit page (`REGISTER_ADD`/
/// `REGISTER_EDIT`), which prefills every field from the found customer
/// rather than using a separate page. Passport/MRZ scan is still deferred
/// (see the `customer-register-deferred` project memory).
///
/// At desktop width it is the POS Desktop Customer form (mockup screens 8,
/// 12, 13): pushed, inside a [DesktopPageFrame]; [embedded], just the form
/// panel for the Customer tab, which then gets [onSaved] (the saved
/// shopping card) instead of the page closing.
class CustomerRegistrationPage extends StatefulWidget {
  final CustomerRegistrationViewModel viewModel;
  final String userCode;
  final bool isAirportMpos;
  final Customer? existingCustomer;
  final bool embedded;
  final ValueChanged<String>? onSaved;

  const CustomerRegistrationPage({
    super.key,
    required this.viewModel,
    required this.userCode,
    required this.isAirportMpos,
    this.existingCustomer,
    this.embedded = false,
    this.onSaved,
  });

  @override
  State<CustomerRegistrationPage> createState() =>
      _CustomerRegistrationPageState();
}

class _CustomerRegistrationPageState extends State<CustomerRegistrationPage> {
  final _passportNoController = TextEditingController();
  final _englishNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _weChatController = TextEditingController();
  final _customerTypeController = TextEditingController();
  String _gender = 'M';
  Nationality? _nationality;
  Agent? _agent;
  Agent? _guide;
  Flight? _flight;
  List<Flight> _flightDates = [];
  String? _selectedFlightDate;
  // Not user-entered — matches legacy's `this.airlineCode = data.Data[0]
  // .airlineCode` in `getFlightDate()`: sourced from the first resolved
  // flight-date candidate, not the flight-search result itself.
  String _airlineCode = '';
  // A loaded take-away customer's `OP000`, re-sent while Allow take-away
  // stays on.
  String _takeAwayFlightCode = '';
  bool _allowTakeAway = false;
  // Echoed back verbatim on submit only when the found customer already
  // has a shopping card — see `initState`'s assignment and
  // `CustomerPerson.listIdentity`'s doc comment for why.
  List<Map<String, dynamic>> _listIdentity = const [];
  String _provinceCode = '';
  String _cityCode = '';
  Object? _dateOfBirth;

  // Whether this submits as an edit is driven by the found customer's own
  // `action` field from `GetCustomer` — NOT by "did the user tap the edit
  // icon". Ports `customer-form.ts`'s `setFormCustomerData()`: `this.action
  // = customerParam.action`, later gating both the header/button text and
  // `REGISTER_ADD`/`REGISTER_EDIT` on submit. A shopping card that exists
  // but was never completed (`isFound: false`) comes back with `action:
  // "REGISTER_ADD"` even though it was reached via search+edit — sending
  // `REGISTER_EDIT` for that card gets rejected server-side as a duplicate
  // shopping card (confirmed via a real `M076` response during testing).
  bool get _isEdit => widget.existingCustomer?.action == 'REGISTER_EDIT';

  // A found customer the server already reports as registered
  // (`isActivate`) — shown as a status banner.
  bool get _isRegistered => widget.existingCustomer?.person.isActivate ?? false;

  // Labels say "Update" for an edit or an already-registered customer; the
  // wire `action` still follows [_isEdit] exactly as legacy does.
  bool get _isUpdate => _isEdit || _isRegistered;

  @override
  void initState() {
    super.initState();
    _load(widget.existingCustomer);
  }

  // Fills every field from [customer], or clears them for a new one — used
  // on open and by desktop Undo.
  void _load(Customer? customer) {
    _passportNoController.clear();
    _englishNameController.clear();
    _customerTypeController.clear();
    _emailController.clear();
    _mobileController.clear();
    _weChatController.clear();
    _gender = 'M';
    _nationality = null;
    _agent = null;
    _guide = null;
    _flight = null;
    _flightDates = [];
    _selectedFlightDate = null;
    _airlineCode = '';
    _allowTakeAway = false;
    _takeAwayFlightCode = '';
    _listIdentity = const [];
    _provinceCode = '';
    _cityCode = '';
    _dateOfBirth = null;
    if (customer == null) return;
    final person = customer.person;

    _passportNoController.text = person.passportNo;
    _englishNameController.text = person.englishName;
    _customerTypeController.text = person.customerTypeCode;
    _emailController.text = _contactValue(person.contacts, 'E-MAIL');
    _mobileController.text = _contactValue(person.contacts, 'MOBILE');
    _weChatController.text = _contactValue(person.contacts, 'WECHAT');
    _gender = person.gender;
    // Matches legacy's `if (this.shoppingCard != "")` gate exactly — keyed
    // on the existing shopping card being present, not on add-vs-edit mode.
    if (person.shoppingCard.isNotEmpty) {
      _listIdentity = person.listIdentity;
      _provinceCode = person.provinceCode;
      _cityCode = person.cityCode;
      _dateOfBirth = person.dateOfBirth;
    }
    if (person.nationality.isNotEmpty) {
      _nationality = Nationality(
        countryCode: person.nationality,
        countryName: person.nationality,
      );
    }
    if (customer.agentCode.isNotEmpty) {
      _agent = Agent(
        subAgentCode: '',
        subAgentDesc: '',
        agentCode: customer.agentCode,
        agentDesc: customer.agentCode,
        customerType: '',
        customerTypeDesc: '',
      );
    }
    if (customer.subAgentCode.isNotEmpty) {
      _guide = Agent(
        subAgentCode: customer.subAgentCode,
        subAgentDesc: customer.subAgentCode,
        agentCode: '',
        agentDesc: '',
        customerType: '',
        customerTypeDesc: '',
      );
    }
    // Ports `setFormCustomerData()`: a saved take-away comes back as flight
    // `OP000` / airline `OP` and re-checks Allow take-away (never on
    // airport mPOS) instead of showing that placeholder flight.
    // Legacy keeps the found customer's airline (`this.airlineCode =
    // personInfo.airlineCode`); `getDateByFlight` may replace it below.
    _airlineCode = person.airlineCode;
    if (person.flightCode == 'OP000' &&
        person.airlineCode == 'OP' &&
        !widget.isAirportMpos) {
      _allowTakeAway = true;
      // Sent back as-is, as legacy's `airlineflightCode` is.
      _takeAwayFlightCode = person.flightCode;
    } else if (person.flightCode.isNotEmpty) {
      // Legacy shows the customer's saved flight date and time
      // (`flightDate.replace("00:00:00", flightTime)`) — only when all
      // three are present.
      final saved = _savedFlightDateTime(person.flightDate, person.flightTime);
      if (saved != null) _selectedFlightDate = _formatFlightDate(saved);
      _flight = Flight(
        flightCode: person.flightCode,
        flightDescription: '',
        arrDepAirportName: '',
        destAirportName: '',
        flightType: '',
        airlineCode: '',
        flightNo: '',
        flightDate: person.flightDate,
      );
      unawaited(_prefillFlightDates(person.flightCode));
    }
  }

  // Matches `customer-form.ts`'s `addDatatoModel()` contact-type strings —
  // the inverse of `CustomerRegistrationViewModel._buildListContact()`.
  static String _contactValue(
    List<Map<String, dynamic>> contacts,
    String contactType,
  ) {
    for (final contact in contacts) {
      if (contact['contactType'] == contactType) {
        return contact['contactValue'] as String? ?? '';
      }
    }
    return '';
  }

  // Legacy `getFlightDate(airlineflightCode)` on load — called without an
  // `action`, so it loads the candidate dates and the airline
  // (`data.Data[0].airlineCode`) but never replaces the saved flight date.
  Future<void> _prefillFlightDates(String flightCode) async {
    final dates = await widget.viewModel.getDatesForFlight(flightCode);
    // Dropped if Undo / a new pick replaced the flight meanwhile.
    if (!mounted || _flight?.flightCode != flightCode) return;
    setState(() {
      _flightDates = dates;
      if (dates.isNotEmpty) _airlineCode = dates.first.airlineCode;
    });
  }

  // `PersonInfo.flightDate` (a date, e.g. `2026-08-18T00:00:00`) with
  // `flightTime` (`HH:mm`) as its time; null unless both are usable.
  static DateTime? _savedFlightDateTime(String date, String time) {
    final day = DateTime.tryParse(date);
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(time);
    if (day == null || match == null) return null;
    return DateTime(
      day.year,
      day.month,
      day.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
  }

  @override
  void dispose() {
    _passportNoController.dispose();
    _englishNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _weChatController.dispose();
    _customerTypeController.dispose();
    super.dispose();
  }

  // Direct port of `customer-form.ts`'s `validateRegister()` — checked on
  // submit (not used to disable the button; legacy's Save/Update is never
  // disabled, it always validates on tap and shows an alert). Returns the
  // first failing message, or null when the form is valid. The
  // passport/name/nationality/flight requiredness is gated on
  // `!allowTakeAway` and Customer Type's on `!isAirportMpos`, exactly as
  // legacy has it — neither is required unconditionally.
  String? _validateRegister() {
    if (!_allowTakeAway) {
      if (_passportNoController.text.trim().isEmpty) {
        return 'Please input passport.';
      }
      if (_englishNameController.text.trim().isEmpty) {
        return 'Please input englishName.';
      }
      if (_nationality == null) {
        return 'Please input nationality.';
      }
      if (_flight == null) {
        return 'Please input flightCode.';
      }
      if (_selectedFlightDate == null || _selectedFlightDate!.isEmpty) {
        return 'Please input flightDate.';
      }
    }
    final englishName = _englishNameController.text.trim();
    // Legacy's `englishName` format check in `validateRegister()`.
    if (englishName.isNotEmpty && !FormInputs.isEnglishName(englishName)) {
      return 'Invalid name format. Please enter the name in the format (a-z),(-)';
    }
    // Not in legacy: the passport field only accepts A–Z / 0–9, but a
    // prefilled customer can still carry other characters.
    final passport = _passportNoController.text.trim();
    if (passport.isNotEmpty && !FormInputs.isPassport(passport)) {
      return 'Invalid passport format. Please use (A-Z),(0-9) only.';
    }
    if (_customerTypeController.text.trim().isEmpty && !widget.isAirportMpos) {
      return 'Please input Customer Type.';
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !FormInputs.isEmail(email)) {
      return 'Email address in invalid format.';
    }
    final mobile = _mobileController.text.trim();
    if (mobile.isNotEmpty && !FormInputs.isPhone(mobile)) {
      return 'Mobile number in invalid format.';
    }
    if (_weChatController.text.trim().isEmpty &&
        (_nationality?.countryCode.toUpperCase() ?? '') == 'CHN' &&
        !widget.isAirportMpos) {
      return 'Please input wechat.';
    }
    return null;
  }

  String? get _emailError {
    final value = _emailController.text.trim();
    if (value.isEmpty) return null;
    return FormInputs.isEmail(value) ? null : 'Invalid email address.';
  }

  String? get _mobileError {
    final value = _mobileController.text.trim();
    if (value.isEmpty) return null;
    return FormInputs.isPhone(value)
        ? null
        : 'Invalid mobile number (8–15 digits, may start with +).';
  }

  // Ports `customer-form.ts`'s `getFlightDate()` callback: the moment a
  // flight resolves candidate dates, the first one auto-fills Flight date —
  // same as legacy's `this.flightDate = datepipe.transform(flightDateLists[0], ...)`.
  Future<void> _onFlightSelected(Flight flight) async {
    setState(() {
      _flight = flight;
      _flightDates = [];
      _selectedFlightDate = null;
      _airlineCode = '';
    });
    final dates = await widget.viewModel.getDatesForFlight(flight.flightCode);
    if (!mounted || !identical(_flight, flight)) return;
    final firstCandidate = dates.isEmpty
        ? null
        : _parseFlightDate(dates.first.flightDate);
    setState(() {
      _flightDates = dates;
      _selectedFlightDate = firstCandidate == null
          ? null
          : _formatFlightDate(firstCandidate);
      _airlineCode = dates.isEmpty ? '' : dates.first.airlineCode;
    });
  }

  // `Flight.flightDate` is assumed ISO-8601, matching the only concrete
  // format evidence for this backend (`flight/ValidateFlight`'s
  // `flightDateTime` example in `api-contracts.md`).
  static DateTime? _parseFlightDate(String raw) => DateTime.tryParse(raw);

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  // Formatted to match what legacy's `datepipe.transform(..., 'dd-MM-yyyy
  // HH:mm')` sends as `PersonInfo.flightDate` on `RegisterAPI`.
  static String _formatFlightDate(DateTime dateTime) =>
      '${_twoDigits(dateTime.day)}-${_twoDigits(dateTime.month)}-${dateTime.year} '
      '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';

  static DateTime _dateOnly(DateTime dateTime) =>
      DateTime(dateTime.year, dateTime.month, dateTime.day);

  static final _displayedDatePattern = RegExp(r'^(\d{2})-(\d{2})-(\d{4})');

  static DateTime? _parseDisplayedDateOnly(String value) {
    final match = _displayedDatePattern.firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
    );
  }

  static final _displayedDateTimePattern = RegExp(
    r'^(\d{2})-(\d{2})-(\d{4}) (\d{2}):(\d{2})$',
  );

  static DateTime? _parseDisplayedDateTime(String value) {
    final match = _displayedDateTimePattern.firstMatch(value);
    if (match == null) return null;
    return DateTime(
      int.parse(match.group(3)!),
      int.parse(match.group(2)!),
      int.parse(match.group(1)!),
      int.parse(match.group(4)!),
      int.parse(match.group(5)!),
    );
  }

  // `PersonInfo.flightDate`/`flightTime` go over the wire as separate
  // fields — `yyyy-MM-dd` and `HH:mm` — NOT the combined `dd-MM-yyyy HH:mm`
  // string shown on screen. Ports `addDatatoModel()`'s `convDate` handling
  // (`customer-form.ts:906-935`) exactly, down to its fallback: when no
  // flight was picked, legacy still sends *today's* date/time rather than
  // leaving these fields empty (`this.airlineflightCode == ""` branch) —
  // the server apparently requires a value here regardless.
  static String _wireFlightDate(DateTime dateTime) =>
      '${dateTime.year.toString().padLeft(4, '0')}-${_twoDigits(dateTime.month)}-${_twoDigits(dateTime.day)}';

  static String _wireFlightTime(DateTime dateTime) =>
      '${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}';

  // The distinct dates among the resolved candidates — `getDateByFlight`
  // returns specific departures, not a continuous availability range, so
  // only those exact dates should be pickable (see `selectableDayPredicate`
  // below), not every day between the earliest and latest one.
  static Set<DateTime> _candidateDateOnlySet(List<Flight> dates) {
    final set = <DateTime>{};
    for (final f in dates) {
      final parsed = _parseFlightDate(f.flightDate);
      if (parsed == null) continue;
      set.add(_dateOnly(parsed));
    }
    return set;
  }

  // Ports `customer-form.ts`'s `openCalendar()`: legacy only lets the user
  // change the DATE via its ion2-calendar modal — the TIME always stays
  // whatever the flight's first resolved candidate carries, so there is no
  // time-picking step. Only the exact dates `getDateByFlight` resolved are
  // selectable (legacy's `from: filghtDateFirst` plus its — functionally
  // inert — per-day `daysConfig` list, ported here as an actual
  // restriction). Handheld (mockup screen 13) keeps that fixed time; the
  // desktop picker (screen 12) takes each day's time from its own resolved
  // departure instead — the same value whenever the flight departs at one
  // time daily.
  Future<void> _pickFlightDate() async {
    if (AppBreakpoints.isWide(context)) return _pickDesktopFlightDate();
    final anchor =
        _parseFlightDate(_flightDates.first.flightDate) ?? DateTime.now();
    final anchorDateOnly = _dateOnly(anchor);
    final allowedDates = _candidateDateOnlySet(_flightDates);
    final currentDateOnly = _selectedFlightDate == null
        ? null
        : _parseDisplayedDateOnly(_selectedFlightDate!);
    final initialDate =
        currentDateOnly != null && allowedDates.contains(currentDateOnly)
        ? currentDateOnly
        : anchorDateOnly;

    final chosen = await showFlightDatePicker(
      context,
      flightCode: _flight?.flightCode ?? '',
      firstDate: anchorDateOnly,
      initialDate: initialDate,
      time: TimeOfDay(hour: anchor.hour, minute: anchor.minute),
      allowedDates: allowedDates,
    );
    if (chosen == null || !mounted) return;
    setState(
      () => _selectedFlightDate = _formatFlightDate(
        DateTime(
          chosen.year,
          chosen.month,
          chosen.day,
          anchor.hour,
          anchor.minute,
        ),
      ),
    );
  }

  Future<void> _pickDesktopFlightDate() async {
    final departures = [
      for (final f in _flightDates) ?_parseFlightDate(f.flightDate),
    ];
    if (departures.isEmpty) return;
    final picked = await showDesktopFlightDatePicker(
      context,
      flightCode: _flight?.flightCode ?? '',
      route: _flightRoute(_flight),
      departures: departures,
      initial: _selectedFlightDate == null
          ? null
          : _parseDisplayedDateTime(_selectedFlightDate!),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedFlightDate = _formatFlightDate(picked));
  }

  static String _flightRoute(Flight? flight) {
    if (flight == null) return '';
    if (flight.flightDescription.isNotEmpty) return flight.flightDescription;
    if (flight.arrDepAirportName.isEmpty && flight.destAirportName.isEmpty) {
      return '';
    }
    return '${flight.arrDepAirportName} → ${flight.destAirportName}';
  }

  // Desktop "Non-international flight (take away)": the same Allow
  // take-away flag, but turning it on also clears the flight fields, as the
  // mockup labels it.
  void _setNonInternational(bool value) {
    setState(() {
      _allowTakeAway = value;
      if (value) {
        _flight = null;
        _flightDates = [];
        _selectedFlightDate = null;
        _airlineCode = '';
      }
    });
  }

  // Screen 9 edits the same passport / name / nationality / flight fields;
  // a newly picked flight resolves its dates exactly as the Flight code
  // lookup does.
  Future<void> _openTraveller(CustomerRegistrationViewModel viewModel) async {
    final details = await showDesktopTravellerOverlay(
      context,
      initial: TravellerDetails(
        passportNo: _passportNoController.text,
        englishName: _englishNameController.text,
        nationality: _nationality,
        flight: _flight,
      ),
      searchFlights: viewModel.searchFlights,
      searchNationalities: viewModel.searchNationalities,
    );
    if (details == null || !mounted) return;
    setState(() {
      _passportNoController.text = details.passportNo;
      _englishNameController.text = details.englishName;
      _nationality = details.nationality;
    });
    final flight = details.flight;
    if (flight != null && flight.flightCode != _flight?.flightCode) {
      await _onFlightSelected(flight);
    }
  }

  // Clearing the flight drops everything resolved from it.
  void _clearFlight() => setState(() {
    _flight = null;
    _flightDates = [];
    _selectedFlightDate = null;
    _airlineCode = '';
  });

  // Changing the agent clears the sub agent (guide) picked under it.
  void _onAgentSelected(Agent agent) {
    setState(() {
      if (agent.agentCode != _agent?.agentCode) _guide = null;
      _agent = agent;
    });
  }

  Future<void> _submit() async {
    if (kDebugMode) {
      final existing = widget.existingCustomer;
      debugPrint(
        '[CustomerRegistrationPage._submit] '
        'mode=${_isEdit ? 'REGISTER_EDIT' : 'REGISTER_ADD'} '
        'existing.action=${existing?.action} '
        'existing.isFound=${existing?.isFound} '
        'shoppingCard=${existing?.person.shoppingCard} '
        'isActivate=${existing?.person.isActivate}\n'
        '  form: passport=${_passportNoController.text} '
        'name=${_englishNameController.text} '
        'nationality=${_nationality?.countryCode} gender=$_gender '
        'customerType=${_customerTypeController.text} '
        'agent=${_agent?.agentCode} guide=${_guide?.subAgentCode} '
        'flight=${_flight?.flightCode} flightDate=$_selectedFlightDate '
        'airline=$_airlineCode takeAway=$_allowTakeAway '
        'takeAwayFlight=$_takeAwayFlightCode',
      );
    }
    final validationError = _validateRegister();
    if (validationError != null) {
      if (kDebugMode) {
        debugPrint(
          '[CustomerRegistrationPage._submit] invalid: $validationError',
        );
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error!'),
          content: Text(validationError),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Never sent empty — legacy falls back to today's date/time when no
    // flight was picked or the flight is `OP000` (see [_wireFlightDate]'s
    // doc comment).
    final flightCode =
        _flight?.flightCode ?? (_allowTakeAway ? _takeAwayFlightCode : '');
    final wireDateTime =
        (_selectedFlightDate == null || flightCode == 'OP000'
            ? null
            : _parseDisplayedDateTime(_selectedFlightDate!)) ??
        DateTime.now();

    final success = await widget.viewModel.submit(
      englishName: _englishNameController.text.trim(),
      passportNo: _passportNoController.text.trim(),
      nationality: _nationality?.countryCode ?? '',
      gender: _gender,
      customerTypeCode: _customerTypeController.text.trim(),
      agentCode: _agent?.agentCode ?? '',
      subAgentCode: _guide?.subAgentCode ?? '',
      flightCode: flightCode,
      flightDate: _wireFlightDate(wireDateTime),
      flightTime: _wireFlightTime(wireDateTime),
      airlineCode: _airlineCode,
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      weChat: _weChatController.text.trim(),
      allowTakeAway: _allowTakeAway,
      isAirportMpos: widget.isAirportMpos,
      userCode: widget.userCode,
      isEdit: _isEdit,
      // Echoed from the found customer's current value — matches legacy's
      // `this.isActivate = this.personInfo.isActivate` in
      // `setFormCustomerData()`; `false` when there's no existing customer
      // (a brand-new registration), same as that method's own default.
      isActivate: widget.existingCustomer?.person.isActivate ?? false,
      listIdentity: _listIdentity,
      provinceCode: _provinceCode,
      cityCode: _cityCode,
      dateOfBirth: _dateOfBirth,
      tour: widget.existingCustomer?.tour,
    );
    if (!mounted || !success) return;

    final outputs = widget.viewModel.result?.outputs ?? const [];
    final shoppingCard = outputs.isEmpty ? '' : outputs.first.shoppingCard;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isUpdate ? 'Customer updated' : 'Customer registered'),
        content: Text('Shopping card: $shoppingCard'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (widget.embedded) {
      widget.onSaved?.call(shoppingCard);
      return;
    }
    // The saved card goes back to whoever pushed the form (Home).
    Navigator.of(context).pop(shoppingCard);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CustomerRegistrationViewModel>(
      init: widget.viewModel,
      global: false,
      builder: (viewModel) => AppBreakpoints.isWide(context)
          ? _buildDesktop(context, viewModel)
          : _buildHandheld(context, viewModel),
    );
  }

  bool _isSubmitting(CustomerRegistrationViewModel viewModel) =>
      viewModel.status == CustomerRegistrationStatus.submitting;

  Widget _buildDesktop(
    BuildContext context,
    CustomerRegistrationViewModel viewModel,
  ) {
    final form = _desktopForm(viewModel);
    if (widget.embedded) return form;
    return DesktopPageFrame(
      title: _isUpdate ? 'Customer profile' : 'Register new customer',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DesktopMetrics.pagePadding),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: form,
          ),
        ),
      ),
    );
  }

  /// Mockup screen 8's form: two-column fields, the five searchable ones as
  /// [DesktopLookupField]s (screen 13), flight date via screen 12.
  Widget _desktopForm(CustomerRegistrationViewModel viewModel) {
    // Legacy's `validateRegister()` requires these only when take-away is
    // off (international flight); Customer type only off Airport mode.
    final international = !_allowTakeAway;
    Widget pair(Widget left, Widget right) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );

    return DesktopPanel(
      id: DesktopCustomerIds.form,
      title: _isUpdate ? 'Update customer' : 'New customer',
      trailing: const Text(
        '* required for international flight',
        style: TextStyle(fontSize: 12, color: AppColors.mutedText),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?_statusBanner(bottom: 16),
          pair(
            DesktopLookupField<Flight>(
              id: DesktopCustomerIds.flightCode,
              label: 'Flight code',
              required: international,
              hint: 'e.g. TG916',
              value: _flight,
              search: viewModel.searchFlights,
              code: (f) => f.flightCode,
              name: _flightRoute,
              trailing: (f) {
                final departs = _parseFlightDate(f.flightDate);
                return departs == null ? '' : _wireFlightTime(departs);
              },
              onSelected: _onFlightSelected,
              onCleared: _clearFlight,
            ),
            _desktopFlightDateField(required: international),
          ),
          pair(
            _desktopTextField(
              DesktopCustomerIds.passportNo,
              'Passport no.',
              _passportNoController,
              required: international,
              inputFormatters: FormInputs.passport,
            ),
            _desktopTextField(
              DesktopCustomerIds.englishName,
              'English name',
              _englishNameController,
              required: international,
              inputFormatters: FormInputs.englishName,
            ),
          ),
          pair(
            _desktopGenderField(),
            DesktopLookupField<Nationality>(
              id: DesktopCustomerIds.nationality,
              label: 'Nationality',
              required: international,
              value: _nationality,
              search: viewModel.searchNationalities,
              code: (n) => n.countryCode,
              name: (n) => n.countryName,
              onSelected: (n) => setState(() => _nationality = n),
              onCleared: () => setState(() => _nationality = null),
            ),
          ),
          pair(
            _desktopTextField(
              DesktopCustomerIds.email,
              'Email',
              _emailController,
              keyboardType: TextInputType.emailAddress,
              errorText: _emailError,
              inputFormatters: FormInputs.email,
            ),
            _desktopTextField(
              DesktopCustomerIds.mobile,
              'Mobile',
              _mobileController,
              keyboardType: TextInputType.phone,
              errorText: _mobileError,
              inputFormatters: FormInputs.phone,
            ),
          ),
          pair(
            _desktopTextField(
              DesktopCustomerIds.weChat,
              'WeChat',
              _weChatController,
              inputFormatters: FormInputs.weChat,
            ),
            DesktopLookupField<Agent>(
              id: DesktopCustomerIds.customerType,
              label: 'Customer type',
              required: !widget.isAirportMpos,
              value: _customerTypeController.text.isEmpty
                  ? null
                  : Agent(
                      subAgentCode: '',
                      subAgentDesc: '',
                      agentCode: '',
                      agentDesc: '',
                      customerType: _customerTypeController.text,
                      customerTypeDesc: '',
                    ),
              search: viewModel.searchCustomerTypes,
              code: (a) => a.customerType,
              name: (a) => a.customerTypeDesc,
              onSelected: (a) =>
                  setState(() => _customerTypeController.text = a.customerType),
              onCleared: () => setState(_customerTypeController.clear),
            ),
          ),
          pair(
            DesktopLookupField<Agent>(
              id: DesktopCustomerIds.agentCode,
              label: 'Agent code',
              value: _agent,
              search: viewModel.searchAgents,
              code: (a) => a.agentCode,
              name: (a) => a.agentDesc,
              onSelected: _onAgentSelected,
              onCleared: () => setState(() {
                _agent = null;
                _guide = null;
              }),
            ),
            DesktopLookupField<Agent>(
              id: DesktopCustomerIds.subAgentCode,
              label: 'Sub agent code',
              enabled: _agent != null,
              disabledHint: 'Choose an agent code first',
              value: _guide,
              search: viewModel.searchGuides,
              code: (a) => a.subAgentCode,
              name: (a) => a.subAgentDesc,
              onSelected: (a) => setState(() => _guide = a),
              onCleared: () => setState(() => _guide = null),
            ),
          ),
          TestId(
            DesktopCustomerIds.nonInternational,
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.goldDark,
              value: _allowTakeAway,
              onChanged: (value) => _setNonInternational(value ?? false),
              title: const Text(
                'Non-international flight (take away)',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          ?_errorText(viewModel),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DesktopButton(
                  id: RegisterIds.submitButton,
                  // Never disabled by field validity — matches legacy,
                  // which always allows tapping Save/Update and validates
                  // on tap via [_validateRegister] instead. Only in-flight
                  // submission blocks a repeat tap.
                  label: _isUpdate ? 'Update customer' : 'Register customer',
                  icon: Icons.check,
                  height: 56,
                  onPressed: _isSubmitting(viewModel) ? null : _submit,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: DesktopCustomerIds.travellerButton,
                  label: 'Flight & passport',
                  icon: Icons.flight_takeoff,
                  secondary: true,
                  height: 56,
                  onPressed: () => _openTraveller(viewModel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DesktopButton(
                  id: DesktopCustomerIds.undoButton,
                  label: 'Undo',
                  icon: Icons.undo,
                  secondary: true,
                  height: 56,
                  onPressed: () =>
                      setState(() => _load(widget.existingCustomer)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            _manualEntryNote,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText),
          ),
        ],
      ),
    );
  }

  static InputDecoration _desktopDecoration({String? errorText}) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      errorText: errorText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      border: border(const Color(0xFFD8DDE5), 1),
      enabledBorder: border(const Color(0xFFD8DDE5), 1),
      focusedBorder: border(AppColors.goldMuted, 2),
    );
  }

  static Widget _desktopLabel(String label, {bool required = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      '${label.toUpperCase()}${required ? ' *' : ''}',
      style: DesktopText.fieldLabel,
    ),
  );

  Widget _desktopTextField(
    String id,
    String label,
    TextEditingController controller, {
    bool required = false,
    TextInputType? keyboardType,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
  }) => TestId(
    id,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _desktopLabel(label, required: required),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: TextCapitalization.characters,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          decoration: _desktopDecoration(errorText: errorText).copyWith(
            suffixIcon: controller.text.isEmpty
                ? null
                : ClearFieldButton(
                    id: FieldIds.clear(id),
                    controller: controller,
                    onCleared: (_) => setState(() {}),
                  ),
          ),
        ),
      ],
    ),
  );

  Widget _desktopGenderField() => TestId(
    DesktopCustomerIds.gender,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _desktopLabel('Gender'),
        DropdownButtonFormField<String>(
          // Keyed on the value so Undo's reset is shown.
          key: ValueKey(_gender),
          initialValue: _gender,
          decoration: _desktopDecoration(),
          items: const [
            DropdownMenuItem(value: 'M', child: Text('Male')),
            DropdownMenuItem(value: 'F', child: Text('Female')),
          ],
          onChanged: (value) => setState(() => _gender = value ?? 'M'),
        ),
      ],
    ),
  );

  Widget _desktopFlightDateField({required bool required}) {
    final enabled = _flightDates.isNotEmpty;
    final selected = _selectedFlightDate == null
        ? null
        : _parseDisplayedDateTime(_selectedFlightDate!);
    return TestId(
      DesktopCustomerIds.flightDate,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _desktopLabel('Flight date & time', required: required),
          Semantics(
            button: true,
            enabled: enabled,
            child: Material(
              color: enabled ? AppColors.surface : AppColors.surfaceAlt,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFD8DDE5)),
              ),
              child: InkWell(
                onTap: enabled ? _pickFlightDate : null,
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: DesktopMetrics.fieldHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            selected != null
                                ? formatFlightPickerDate(selected)
                                : enabled
                                ? 'Pick a date'
                                : 'Pick a flight first',
                            style: selected != null
                                ? const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  )
                                : const TextStyle(
                                    fontSize: 14.5,
                                    color: AppColors.hintText,
                                  ),
                          ),
                        ),
                        if (selected != null)
                          Text(
                            _wireFlightTime(selected),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: AppColors.hintText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _manualEntryNote =
      "Manual entry — passport/MRZ scan isn't available yet";

  /// Handheld layout (mockup screen 12): dark header, the same fields
  /// grouped into Traveller / Contact / Agent sections under an (inert)
  /// passport scan, and a fixed Register / Cancel bar. Validation and
  /// submit are shared with desktop.
  Widget _buildHandheld(
    BuildContext context,
    CustomerRegistrationViewModel viewModel,
  ) {
    Widget section(String id, String title, List<Widget> children) =>
        HandheldSection(
          id: id,
          title: title,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _spaced(children),
              ),
            ),
          ],
        );

    return TestId(
      RegisterIds.page,
      child: HandheldScaffold(
        header: HandheldHeader(
          title: _isUpdate ? 'Update customer' : 'Register customer',
          subtitle: _isUpdate
              ? 'Update this shopping card'
              : 'New shopping card · attaches to this sale',
          leading: const BackButton(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?_statusBanner(bottom: AppSpacing.md),
              // TODO(pos-handheld): MRZ / boarding-pass scan (deferred —
              // see project memory); inert until a reader is wired.
              TestId(
                RegisterIds.scanPassportButton,
                child: Semantics(
                  button: true,
                  enabled: false,
                  child: Container(
                    height: HandheldMetrics.primaryActionHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(
                        HandheldMetrics.radius,
                      ),
                      border: Border.all(color: AppColors.goldMuted, width: 2),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 18,
                          color: AppColors.goldDark,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Scan passport or boarding pass',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.goldDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(_manualEntryNote, style: HandheldText.bodySmall),
              const SizedBox(height: AppSpacing.md),
              section(RegisterIds.travellerSection, 'Traveller', [
                _flightField(viewModel),
                _flightDateField(),
                _passportField(),
                _englishNameField(),
                _genderField(),
                _nationalityField(viewModel),
              ]),
              const SizedBox(height: AppSpacing.md),
              section(RegisterIds.contactSection, 'Contact', [
                _emailField(),
                _mobileField(),
                _weChatField(),
              ]),
              const SizedBox(height: AppSpacing.md),
              section(RegisterIds.agentSection, 'Agent', [
                _agentField(viewModel),
                _guideField(viewModel),
                _customerTypeField(),
                _takeAwaySwitch(),
              ]),
              ?_errorText(viewModel),
            ],
          ),
        ),
        actionBar: HandheldActionBar(
          primary: HandheldPrimaryButton(
            id: RegisterIds.submitButton,
            label: _isUpdate ? 'Update customer' : 'Register',
            icon: Icons.check,
            onPressed: _isSubmitting(viewModel) ? null : _submit,
          ),
          secondary: HandheldSecondaryButton(
            id: RegisterIds.cancelButton,
            label: 'Cancel',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
    );
  }

  /// Registration status of the found customer — green "Registered" with
  /// the shopping card, or amber "Not registered yet". Null for a brand-new
  /// customer (nothing to report).
  Widget? _statusBanner({required double bottom}) {
    final customer = widget.existingCustomer;
    if (customer == null) return null;
    final registered = _isRegistered;
    final color = registered ? AppColors.success : AppColors.warning;
    final card = customer.person.shoppingCard;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: TestId(
        RegisterIds.statusBanner,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color),
          ),
          child: Row(
            children: [
              Icon(
                registered ? Icons.verified : Icons.error_outline,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registered ? 'Registered' : 'Not registered yet',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      [
                        if (card.isNotEmpty) 'Shopping card $card',
                        registered
                            ? 'Saving updates this customer'
                            : 'Saving completes the registration',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.mutedText,
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

  static List<Widget> _spaced(List<Widget> fields) => [
    for (var i = 0; i < fields.length; i++) ...[
      if (i > 0) const SizedBox(height: AppSpacing.sm),
      fields[i],
    ],
  ];

  Widget? _errorText(CustomerRegistrationViewModel viewModel) {
    if (viewModel.status != CustomerRegistrationStatus.failure ||
        viewModel.errorMessage == null) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(
        viewModel.errorMessage!,
        style: const TextStyle(color: AppColors.danger),
      ),
    );
  }

  Widget _passportField() => AppTextField(
    id: RegisterIds.passportField,
    controller: _passportNoController,
    label: 'Passport no.',
    inputFormatters: FormInputs.passport,
    textCapitalization: TextCapitalization.characters,
    onChanged: (_) => setState(() {}),
  );

  Widget _englishNameField() => AppTextField(
    id: RegisterIds.englishNameField,
    controller: _englishNameController,
    label: 'English name',
    inputFormatters: FormInputs.englishName,
    textCapitalization: TextCapitalization.characters,
    onChanged: (_) => setState(() {}),
  );

  Widget _genderField() => DropdownButtonFormField<String>(
    initialValue: _gender,
    decoration: const InputDecoration(
      labelText: 'Gender',
      border: OutlineInputBorder(),
    ),
    items: const [
      DropdownMenuItem(value: 'M', child: Text('Male')),
      DropdownMenuItem(value: 'F', child: Text('Female')),
    ],
    onChanged: (value) => setState(() => _gender = value ?? 'M'),
  );

  Widget _nationalityField(CustomerRegistrationViewModel viewModel) =>
      AutocompleteField<Nationality>(
        label: 'Nationality',
        hintText: 'Type to search nationality',
        initialText: _nationality?.countryCode,
        search: viewModel.searchNationalities,
        itemLabel: (n) => '${n.countryCode} - ${n.countryName}',
        onSelected: (n) => setState(() => _nationality = n),
        onCleared: () => setState(() => _nationality = null),
        id: RegisterIds.nationalityField,
      );

  Widget _flightField(CustomerRegistrationViewModel viewModel) =>
      AutocompleteField<Flight>(
        label: 'Flight',
        hintText: 'Type to search flight code',
        initialText: _flight?.flightCode,
        search: viewModel.searchFlights,
        itemLabel: (f) => f.flightDescription.isEmpty
            ? f.flightCode
            : '${f.flightCode} — ${f.flightDescription}',
        onSelected: _onFlightSelected,
        onCleared: _clearFlight,
        id: RegisterIds.flightField,
      );

  Widget _flightDateField() => InkWell(
    key: const Key('flightDateField'),
    onTap: _flightDates.isEmpty ? null : _pickFlightDate,
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Flight date',
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.calendar_today),
      ),
      child: Text(_selectedFlightDate ?? ''),
    ),
  );

  Widget _emailField() => AppTextField(
    id: RegisterIds.emailField,
    controller: _emailController,
    label: 'Email',
    keyboardType: TextInputType.emailAddress,
    errorText: _emailError,
    inputFormatters: FormInputs.email,
    textCapitalization: TextCapitalization.characters,
    onChanged: (_) => setState(() {}),
  );

  Widget _mobileField() => AppTextField(
    id: RegisterIds.mobileField,
    controller: _mobileController,
    label: 'Mobile',
    keyboardType: TextInputType.phone,
    errorText: _mobileError,
    inputFormatters: FormInputs.phone,
    onChanged: (_) => setState(() {}),
  );

  Widget _weChatField() => AppTextField(
    id: RegisterIds.weChatField,
    controller: _weChatController,
    label: 'WeChat',
    inputFormatters: FormInputs.weChat,
    textCapitalization: TextCapitalization.characters,
    onChanged: (_) => setState(() {}),
  );

  Widget _agentField(CustomerRegistrationViewModel viewModel) =>
      AutocompleteField<Agent>(
        label: 'Agent',
        hintText: 'Type to search agent',
        initialText: _agent?.agentCode,
        search: viewModel.searchAgents,
        itemLabel: (a) => a.agentDesc.isEmpty ? a.agentCode : a.agentDesc,
        onSelected: (a) => setState(() => _agent = a),
        onCleared: () => setState(() => _agent = null),
        id: RegisterIds.agentField,
      );

  Widget _guideField(CustomerRegistrationViewModel viewModel) =>
      AutocompleteField<Agent>(
        label: 'Guide',
        hintText: 'Type to search guide',
        initialText: _guide?.subAgentCode,
        search: viewModel.searchGuides,
        itemLabel: (a) =>
            a.subAgentDesc.isEmpty ? a.subAgentCode : a.subAgentDesc,
        onSelected: (a) => setState(() => _guide = a),
        onCleared: () => setState(() => _guide = null),
        id: RegisterIds.guideField,
      );

  Widget _customerTypeField() => AppTextField(
    controller: _customerTypeController,
    label: 'Customer type',
    inputFormatters: FormInputs.upperCase,
    textCapitalization: TextCapitalization.characters,
    onChanged: (_) => setState(() {}),
  );

  Widget _takeAwaySwitch() => TestId(
    RegisterIds.takeAwaySwitch,
    child: SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Allow take-away'),
      value: _allowTakeAway,
      onChanged: (value) => setState(() => _allowTakeAway = value),
    ),
  );
}
