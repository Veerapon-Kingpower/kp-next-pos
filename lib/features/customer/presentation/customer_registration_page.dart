import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/presentation/handheld/handheld.dart';
import '../../../core/presentation/test_ids.dart';
import '../../../core/presentation/widgets/app_buttons.dart';
import '../../../core/presentation/widgets/app_card.dart';
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
import 'handheld/flight_date_picker.dart';

/// Manual-entry "Register new customer" form, fields ordered to match
/// `customer-form.html`'s non-airport layout. Doubles as the edit-existing-
/// customer form when [existingCustomer] is given — ports
/// `customer-form.ts`'s shared add/edit page (`REGISTER_ADD`/
/// `REGISTER_EDIT`), which prefills every field from the found customer
/// rather than using a separate page. Passport/MRZ scan is still deferred
/// (see the `customer-register-deferred` project memory).
class CustomerRegistrationPage extends StatefulWidget {
  final CustomerRegistrationViewModel viewModel;
  final String userCode;
  final bool isAirportMpos;
  final Customer? existingCustomer;

  const CustomerRegistrationPage({
    super.key,
    required this.viewModel,
    required this.userCode,
    required this.isAirportMpos,
    this.existingCustomer,
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
  bool _allowTakeAway = false;
  // Echoed back verbatim on submit only when the found customer already
  // has a shopping card — see `initState`'s assignment and
  // `CustomerPerson.listIdentity`'s doc comment for why.
  List<Map<String, dynamic>> _listIdentity = const [];
  String _provinceCode = '';
  String _cityCode = '';

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

  @override
  void initState() {
    super.initState();
    final customer = widget.existingCustomer;
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
    if (person.flightCode.isNotEmpty) {
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

  // Resolves candidate dates for a flight prefilled from an existing
  // customer, same as `_onFlightSelected` picking the first candidate — but
  // without that method's own `setState()` for `_flight`/reset, since
  // [initState] already set `_flight` directly (before the first build, so
  // no `setState()` is needed — or safe to call — for that part yet).
  Future<void> _prefillFlightDates(String flightCode) async {
    final dates = await widget.viewModel.getDatesForFlight(flightCode);
    if (!mounted) return;
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

  static final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  // Matches legacy's `englishName` format check in `validateRegister()`.
  static final _englishNameFormat = RegExp(r'^[A-Za-z \-]*$');

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
    if (englishName.isNotEmpty && !_englishNameFormat.hasMatch(englishName)) {
      return 'Invalid name format. Please enter the name in the format (a-z),(-)';
    }
    if (_customerTypeController.text.trim().isEmpty && !widget.isAirportMpos) {
      return 'Please input Customer Type.';
    }
    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_emailFormat.hasMatch(email)) {
      return 'Email address in invalid format.';
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
    return _emailFormat.hasMatch(value) ? null : 'Invalid email address.';
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
    if (!mounted) return;
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
  // change the DATE via its ion2-calendar modal (approximated here with
  // Flutter's built-in Material date picker) — the TIME always stays
  // whatever the flight's first resolved candidate carries, so there is no
  // time-picking step. Only the exact dates `getDateByFlight` resolved are
  // selectable (legacy's `from: filghtDateFirst` plus its — functionally
  // inert — per-day `daysConfig` list, ported here as an actual
  // restriction via `selectableDayPredicate`).
  Future<void> _pickFlightDate() async {
    final anchor =
        _parseFlightDate(_flightDates.first.flightDate) ?? DateTime.now();
    final anchorDateOnly = _dateOnly(anchor);
    final allowedDates = _candidateDateOnlySet(_flightDates);
    final lastDateOnly = allowedDates.isEmpty
        ? anchorDateOnly
        : allowedDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final currentDateOnly = _selectedFlightDate == null
        ? null
        : _parseDisplayedDateOnly(_selectedFlightDate!);
    final initialDate =
        currentDateOnly != null && allowedDates.contains(currentDateOnly)
        ? currentDateOnly
        : anchorDateOnly;

    // Handheld widths use the mockup's own picker (screen 13) with the same
    // rules: fixed schedule time, first candidate date as the floor, only
    // resolved candidate dates selectable.
    final DateTime? picked;
    if (AppBreakpoints.isWide(context)) {
      picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: anchorDateOnly,
        lastDate: lastDateOnly.isBefore(anchorDateOnly)
            ? anchorDateOnly
            : lastDateOnly,
        selectableDayPredicate: allowedDates.isEmpty
            ? null
            : (day) => allowedDates.contains(_dateOnly(day)),
      );
    } else {
      picked = await showFlightDatePicker(
        context,
        flightCode: _flight?.flightCode ?? '',
        firstDate: anchorDateOnly,
        initialDate: initialDate,
        time: TimeOfDay(hour: anchor.hour, minute: anchor.minute),
        allowedDates: allowedDates,
      );
    }
    final chosen = picked;
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

  Future<void> _submit() async {
    final validationError = _validateRegister();
    if (validationError != null) {
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
    // flight was picked (see [_wireFlightDate]'s doc comment).
    final wireDateTime =
        (_selectedFlightDate == null
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
      flightCode: _flight?.flightCode ?? '',
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
    );
    if (!mounted || !success) return;

    final outputs = widget.viewModel.result?.outputs ?? const [];
    final shoppingCard = outputs.isEmpty ? '' : outputs.first.shoppingCard;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEdit ? 'Customer updated' : 'Customer registered'),
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
    Navigator.of(context).pop();
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Customer profile' : 'Register new customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _manualEntryNote,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._spaced([
                    _passportField(),
                    _englishNameField(),
                    _genderField(),
                    _nationalityField(viewModel),
                    _flightField(viewModel),
                    _flightDateField(),
                    _emailField(),
                    _mobileField(),
                    _weChatField(),
                    _agentField(viewModel),
                    _guideField(viewModel),
                    _customerTypeField(),
                    _takeAwaySwitch(),
                  ]),
                  ?_errorText(viewModel),
                  AppPrimaryButton(
                    // Never disabled by field validity — matches legacy,
                    // which always allows tapping Save/Update and
                    // validates on tap via [_validateRegister] instead.
                    // Only in-flight submission blocks a repeat tap.
                    label: _isEdit ? 'Update' : 'Register',
                    onPressed: _isSubmitting(viewModel) ? null : _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
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
          title: _isEdit ? 'Customer profile' : 'Register customer',
          subtitle: _isEdit
              ? 'Update this shopping card'
              : 'New shopping card · attaches to this sale',
          leading: const BackButton(color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(HandheldMetrics.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
            label: _isEdit ? 'Update' : 'Register',
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
    controller: _passportNoController,
    label: 'Passport no.',
    onChanged: (_) => setState(() {}),
  );

  Widget _englishNameField() => AppTextField(
    controller: _englishNameController,
    label: 'English name',
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
    controller: _emailController,
    label: 'Email',
    keyboardType: TextInputType.emailAddress,
    errorText: _emailError,
    onChanged: (_) => setState(() {}),
  );

  Widget _mobileField() => AppTextField(
    controller: _mobileController,
    label: 'Mobile',
    keyboardType: TextInputType.phone,
    onChanged: (_) => setState(() {}),
  );

  Widget _weChatField() => AppTextField(
    controller: _weChatController,
    label: 'WeChat',
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
      );

  Widget _customerTypeField() => AppTextField(
    controller: _customerTypeController,
    label: 'Customer type',
    onChanged: (_) => setState(() {}),
  );

  Widget _takeAwaySwitch() => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: const Text('Allow take-away'),
    value: _allowTakeAway,
    onChanged: (value) => setState(() => _allowTakeAway = value),
  );
}
