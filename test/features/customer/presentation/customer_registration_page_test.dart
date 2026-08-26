import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/customer/domain/entities/agent.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/customer_registration.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/register_customer_usecase.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_page.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_view_model.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/nationality/domain/entities/nationality.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';

import '../../flight/fake_flight_repository.dart';
import '../../nationality/fake_nationality_repository.dart';
import '../fake_customer_repository.dart';

const _nationalities = [Nationality(countryCode: 'THA', countryName: 'Thailand')];
const _agents = [
  Agent(
    subAgentCode: 'GD1',
    subAgentDesc: 'Guide One',
    agentCode: 'AG1',
    agentDesc: 'Agent One',
    customerType: '',
    customerTypeDesc: '',
  ),
];
const _flights = [
  Flight(
    flightCode: 'TG101',
    flightDescription: 'Bangkok - Tokyo',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Narita',
    flightType: 'D',
    airlineCode: 'TG',
    flightNo: '101',
    flightDate: '2026-08-18',
  ),
];
// ISO-8601, matching the format `flight/ValidateFlight`'s `flightDateTime`
// example uses in `api-contracts.md` — the only concrete format evidence
// available for this backend's date fields.
const _flightDates = [
  Flight(
    flightCode: 'TG101',
    flightDescription: 'Bangkok - Tokyo',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Narita',
    flightType: 'D',
    airlineCode: 'TG',
    flightNo: '101',
    flightDate: '2026-08-18T10:00:00',
  ),
  Flight(
    flightCode: 'TG101',
    flightDescription: 'Bangkok - Tokyo',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Narita',
    flightType: 'D',
    airlineCode: 'TG',
    flightNo: '101',
    flightDate: '2026-08-19T14:00:00',
  ),
];
// Has a gap (no candidate on 2026-08-19) to prove the calendar excludes
// in-range days the API didn't actually return, not just days outside
// [firstCandidate, lastCandidate].
const _flightDatesWithGap = [
  Flight(
    flightCode: 'TG101',
    flightDescription: 'Bangkok - Tokyo',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Narita',
    flightType: 'D',
    airlineCode: 'TG',
    flightNo: '101',
    flightDate: '2026-08-18T10:00:00',
  ),
  Flight(
    flightCode: 'TG101',
    flightDescription: 'Bangkok - Tokyo',
    arrDepAirportName: 'Suvarnabhumi',
    destAirportName: 'Narita',
    flightType: 'D',
    airlineCode: 'TG',
    flightNo: '101',
    flightDate: '2026-08-20T09:00:00',
  ),
];

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(800, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  Future<void> enterByLabel(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final finder = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.labelText == label,
    );
    expect(finder, findsOneWidget, reason: 'Field "$label" not found');
    await tester.enterText(finder, value);
  }

  Widget buildHarness({
    RegisterResult? registerResult,
    Object? registerError,
    List<Flight> flightDates = _flightDates,
    Customer? existingCustomer,
    FakeCustomerRepository? repository,
  }) {
    final repo =
        repository ??
        FakeCustomerRepository(
          agentsResult: _agents,
          registerResult: registerResult,
          registerError: registerError,
        );
    final flightRepo = FakeFlightRepository(
      searchResult: _flights,
      dateResult: flightDates,
    );
    final viewModel = CustomerRegistrationViewModel(
      listNationalities: ListNationalitiesUseCase(
        FakeNationalityRepository(searchResult: _nationalities),
      ),
      listAgents: ListAgentsUseCase(repo),
      listGuides: ListGuidesUseCase(repo),
      getFlightByCode: GetFlightByCodeUseCase(flightRepo),
      getDateByFlight: GetDateByFlightUseCase(flightRepo),
      registerCustomer: RegisterCustomerUseCase(repo),
    );
    final page = CustomerRegistrationPage(
      viewModel: viewModel,
      userCode: 'U001',
      isAirportMpos: false,
      existingCustomer: existingCustomer,
    );

    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => page),
              ),
              child: const Text('Open registration'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openPage(WidgetTester tester) async {
    await tester.tap(find.text('Open registration'));
    await tester.pumpAndSettle();
  }

  // Fills every field `validateRegister()` requires when Allow take-away is
  // off — passport/name/nationality/flight code+date, matching legacy's
  // `!allowTakeAway` gate — plus Customer Type (required off Airport mode).
  Future<void> fillRequiredFields(WidgetTester tester) async {
    await enterByLabel(tester, 'Passport no.', 'P1234567');
    await enterByLabel(tester, 'English name', 'Jane Doe');
    await enterByLabel(tester, 'Nationality', 'tha');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('THA - Thailand'));
    await tester.pump();
    await enterByLabel(tester, 'Customer type', 'VIP');
    await tester.pump();
    await enterByLabel(tester, 'Flight', 'TG');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
    await tester.pump();
  }

  testWidgets('shows every form field in legacy order', (tester) async {
    await tester.pumpWidget(buildHarness());
    await openPage(tester);

    expect(find.text('Passport no.'), findsOneWidget);
    expect(find.text('English name'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
    expect(find.text('Nationality'), findsOneWidget);
    expect(find.text('Flight'), findsOneWidget);
    expect(find.text('Flight date'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mobile'), findsOneWidget);
    expect(find.text('WeChat'), findsOneWidget);
    expect(find.text('Agent'), findsOneWidget);
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Customer type'), findsOneWidget);
    expect(find.text('Allow take-away'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);

    // Order matches `customer-form.html:89-239` (non-airport branch): Flight
    // (+ Flight date right after it) sits right after Nationality, and
    // Agent/Guide come after the contact fields, right before Customer Type.
    final labelOrder = [
      'Passport no.',
      'English name',
      'Gender',
      'Nationality',
      'Flight',
      'Flight date',
      'Email',
      'Mobile',
      'WeChat',
      'Agent',
      'Guide',
      'Customer type',
      'Allow take-away',
    ];
    final positions = labelOrder
        .map((label) => tester.getTopLeft(find.text(label)).dy)
        .toList();
    expect(positions, positions.toList()..sort(), reason: 'fields must appear top-to-bottom in legacy order');
  });

  testWidgets(
    'Register is never disabled by field validity — tapping it empty shows a validation alert instead, matching legacy',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      final registerButton = find.widgetWithText(FilledButton, 'Register');
      // Legacy's Save/Update is always tappable; it validates on tap.
      expect(tester.widget<FilledButton>(registerButton).onPressed, isNotNull);

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      // Passport is checked first in `validateRegister()`.
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('Please input passport.'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await fillRequiredFields(tester);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Please input passport.'), findsNothing);
      expect(find.text('Customer registered'), findsOneWidget);
    },
  );

  testWidgets('Gender defaults to Male', (tester) async {
    await tester.pumpWidget(buildHarness());
    await openPage(tester);

    final dropdown = tester.widget<DropdownButtonFormField<String>>(
      find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<String> &&
            w.decoration.labelText == 'Gender',
      ),
    );
    expect(dropdown.initialValue, 'M');
  });

  testWidgets(
    'Flight date is not tappable until a flight resolves at least one candidate date',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      final fieldBefore = tester.widget<InkWell>(
        find.byKey(const Key('flightDateField')),
      );
      expect(fieldBefore.onTap, isNull);

      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      final fieldAfter = tester.widget<InkWell>(
        find.byKey(const Key('flightDateField')),
      );
      expect(fieldAfter.onTap, isNotNull);
    },
  );

  testWidgets(
    'selecting a flight auto-fills Flight date from the first resolved candidate',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      // First candidate is 2026-08-18T10:00:00.
      expect(find.text('18-08-2026 10:00'), findsOneWidget);
    },
  );

  testWidgets(
    "the calendar's selectable range is bounded by the resolved candidate dates, not an arbitrary window",
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('flightDateField')));
      await tester.pumpAndSettle();

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      // _flightDates: first candidate 2026-08-18, last candidate 2026-08-19.
      expect(dialog.firstDate, DateTime(2026, 8, 18));
      expect(dialog.lastDate, DateTime(2026, 8, 19));
    },
  );

  testWidgets(
    'only the exact dates the API resolved are selectable, not every day in the range',
    (tester) async {
      await tester.pumpWidget(buildHarness(flightDates: _flightDatesWithGap));
      await openPage(tester);

      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('flightDateField')));
      await tester.pumpAndSettle();

      final dialog = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      final predicate = dialog.selectableDayPredicate;
      expect(predicate, isNotNull);
      // Candidates are 2026-08-18 and 2026-08-20; 2026-08-19 has no
      // candidate even though it's inside [firstDate, lastDate].
      expect(predicate!(DateTime(2026, 8, 18)), isTrue);
      expect(predicate(DateTime(2026, 8, 19)), isFalse);
      expect(predicate(DateTime(2026, 8, 20)), isTrue);
    },
  );

  testWidgets(
    'tapping Flight date opens only a date picker (no time picker) and keeps the auto-filled time when a new date is confirmed',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      expect(find.text('18-08-2026 10:00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('flightDateField')));
      await tester.pumpAndSettle();

      // A single OK confirms the date picker; there is no follow-up time
      // picker dialog — legacy never lets the user edit the time.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // Confirming the initial date (the first candidate's date) leaves the
      // auto-filled value — including its time — unchanged.
      expect(find.text('18-08-2026 10:00'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Register with a flight selected but no date resolved shows a flightDate validation alert',
    (tester) async {
      await tester.pumpWidget(buildHarness(flightDates: const []));
      await openPage(tester);
      // Picks the flight (via fillRequiredFields), but no candidate dates
      // resolve for it (`flightDates: const []` above), so
      // `_selectedFlightDate` stays null.
      await fillRequiredFields(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();

      expect(find.text('Please input flightDate.'), findsOneWidget);
    },
  );

  testWidgets('an invalid email shows an inline format error', (tester) async {
    await tester.pumpWidget(buildHarness());
    await openPage(tester);

    await enterByLabel(tester, 'Email', 'not-an-email');
    await tester.pump();
    expect(find.text('Invalid email address.'), findsOneWidget);

    await enterByLabel(tester, 'Email', 'jane@example.com');
    await tester.pump();
    expect(find.text('Invalid email address.'), findsNothing);
  });

  testWidgets(
    'submitting the required fields registers the customer and shows the new shopping card',
    (tester) async {
      const registerResult = RegisterResult(
        outputs: [
          RegisterOutput(
            runningNo: '1',
            shoppingCard: 'CPX0099',
            qrShoppingCard: 'QR-CPX0099',
            coupons: [],
          ),
        ],
        messages: [],
        isComplete: true,
      );

      await tester.pumpWidget(buildHarness(registerResult: registerResult));
      await openPage(tester);
      await fillRequiredFields(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();

      expect(find.textContaining('CPX0099'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Open registration'), findsOneWidget);
    },
  );

  testWidgets(
    'submits the airline code and separate yyyy-MM-dd/HH:mm flightDate/flightTime resolved from the flight-date lookup',
    (tester) async {
      final repo = FakeCustomerRepository(
        agentsResult: _agents,
        registerResult: const RegisterResult(
          outputs: [
            RegisterOutput(
              runningNo: '1',
              shoppingCard: 'CPX0099',
              qrShoppingCard: 'QR-CPX0099',
              coupons: [],
            ),
          ],
          messages: [],
          isComplete: true,
        ),
      );

      await tester.pumpWidget(buildHarness(repository: repo));
      await openPage(tester);
      await fillRequiredFields(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      // `_flightDates`'s TG101 candidates carry `airlineCode: 'TG'`, first
      // candidate `2026-08-18T10:00:00` — sent as separate `yyyy-MM-dd`/
      // `HH:mm` fields, not the `18-08-2026 10:00` string shown on screen.
      expect(listPersonal.single['airlineCode'], 'TG');
      expect(listPersonal.single['flightDate'], '2026-08-18');
      expect(listPersonal.single['flightTime'], '10:00');
    },
  );

  testWidgets(
    'never sends an empty flightDate/flightTime — falls back to today when no flight was picked (Allow take-away on)',
    (tester) async {
      final repo = FakeCustomerRepository(
        agentsResult: _agents,
        registerResult: const RegisterResult(
          outputs: [
            RegisterOutput(
              runningNo: '1',
              shoppingCard: 'CPX0099',
              qrShoppingCard: 'QR-CPX0099',
              coupons: [],
            ),
          ],
          messages: [],
          isComplete: true,
        ),
      );

      await tester.pumpWidget(buildHarness(repository: repo));
      await openPage(tester);

      // Allow take-away skips passport/name/nationality/flight
      // requiredness entirely — Customer Type is still required off
      // Airport mode.
      await tester.tap(find.widgetWithText(SwitchListTile, 'Allow take-away'));
      await tester.pump();
      await enterByLabel(tester, 'Customer type', 'VIP');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Register'));
      await tester.pumpAndSettle();

      final listPersonal =
          repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
      expect(listPersonal.single['flightCode'], isEmpty);
      // Never empty — legacy always sends a value, falling back to today.
      expect(listPersonal.single['flightDate'], isNotEmpty);
      expect(listPersonal.single['flightTime'], isNotEmpty);
    },
  );

  testWidgets('a failed submit shows an inline error and stays on the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildHarness(
        registerError: const ApiException(
          messageDesc: 'Passport already registered.',
        ),
      ),
    );
    await openPage(tester);
    await fillRequiredFields(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Passport already registered.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);
  });

  group('editing an existing customer', () {
    // `action` here is what actually decides REGISTER_ADD vs REGISTER_EDIT
    // on submit (see `_isEdit`'s doc comment) — not the fact that this test
    // opened the form via `existingCustomer`.
    const existingCustomer = Customer(
      action: 'REGISTER_EDIT',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [
          {'contactType': 'E-MAIL', 'contactValue': 'jane@example.com'},
          {'contactType': 'MOBILE', 'contactValue': '0812345678'},
          {'contactType': 'WECHAT', 'contactValue': 'jane_wc'},
        ],
        privileges: [],
        walletMembers: [],
        customerTypeCode: 'VIP',
        gender: 'F',
        flightCode: 'TG101',
        flightDate: '2026-08-18T10:00:00',
      ),
      tour: {},
      agentCode: 'AG1',
      subAgentCode: 'GD1',
      isMember: false,
    );

    String textOf(WidgetTester tester, String label) {
      final field = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        ),
      );
      return field.controller?.text ?? '';
    }

    testWidgets(
      'prefills every field from the found customer and shows Update/Customer profile',
      (tester) async {
        await tester.pumpWidget(
          buildHarness(existingCustomer: existingCustomer),
        );
        await openPage(tester);
        // Lets the flight-date prefill's async getDatesForFlight resolve.
        await tester.pumpAndSettle();

        expect(find.text('Customer profile'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Update'), findsOneWidget);
        expect(textOf(tester, 'Passport no.'), 'P1234567');
        expect(textOf(tester, 'English name'), 'Jane Doe');
        expect(textOf(tester, 'Customer type'), 'VIP');
        expect(textOf(tester, 'Email'), 'jane@example.com');
        expect(textOf(tester, 'Mobile'), '0812345678');
        expect(textOf(tester, 'WeChat'), 'jane_wc');
        expect(find.text('Female'), findsOneWidget);
        expect(textOf(tester, 'Nationality'), 'THA');
        expect(textOf(tester, 'Flight'), 'TG101');
        expect(textOf(tester, 'Agent'), 'AG1');
        expect(textOf(tester, 'Guide'), 'GD1');
        // The prefilled flight resolves candidate dates the same way
        // picking a flight does, auto-filling the first one.
        expect(find.text('18-08-2026 10:00'), findsOneWidget);
      },
    );

    testWidgets('tapping Update submits with action REGISTER_EDIT', (
      tester,
    ) async {
      final repo = FakeCustomerRepository(
        agentsResult: _agents,
        registerResult: const RegisterResult(
          outputs: [
            RegisterOutput(
              runningNo: '1',
              shoppingCard: 'CPX0001',
              qrShoppingCard: 'QR-CPX0001',
              coupons: [],
            ),
          ],
          messages: [],
          isComplete: true,
        ),
      );
      await tester.pumpWidget(
        buildHarness(existingCustomer: existingCustomer, repository: repo),
      );
      await openPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await tester.pumpAndSettle();

      expect(repo.lastRegisterCall!['action'], 'REGISTER_EDIT');
      expect(find.text('Customer updated'), findsOneWidget);
    });

    testWidgets(
      'a shopping card that was never completed (action: REGISTER_ADD, isFound: false) submits '
      'as REGISTER_ADD even though it was opened via the edit icon — sending REGISTER_EDIT for it '
      'gets rejected server-side as a duplicate shopping card, but still echoes back listIdentity/'
      'provinceCode/cityCode since it already has a shopping card — that echo is keyed on the '
      'shopping card being present, independent of REGISTER_ADD vs REGISTER_EDIT',
      (tester) async {
        const existingIdentity = [
          {'IdentityType': 'SHOPCARD', 'IdentityValue': '9900000033194'},
        ];
        const incompleteCustomer = Customer(
          action: 'REGISTER_ADD',
          isFound: false,
          person: CustomerPerson(
            englishName: 'Brant Simonis',
            passportNo: 'KY1086005',
            nationality: 'KOR',
            contacts: [],
            privileges: [],
            walletMembers: [],
            customerTypeCode: 'VIP',
            isActivate: false,
            shoppingCard: '9900000033194',
            listIdentity: existingIdentity,
            provinceCode: 'PC1',
            cityCode: 'CC1',
          ),
          tour: {},
          agentCode: '',
          isMember: false,
        );
        final repo = FakeCustomerRepository(
          agentsResult: _agents,
          registerResult: const RegisterResult(
            outputs: [
              RegisterOutput(
                runningNo: '1',
                shoppingCard: 'CPX0001',
                qrShoppingCard: 'QR-CPX0001',
                coupons: [],
              ),
            ],
            messages: [],
            isComplete: true,
          ),
        );

        await tester.pumpWidget(
          buildHarness(existingCustomer: incompleteCustomer, repository: repo),
        );
        await openPage(tester);
        await tester.pumpAndSettle();

        // Looks and behaves like a fresh registration, not an edit —
        // matches legacy's `action == "REGISTER_ADD"` branch in
        // `setFormCustomerData()`.
        expect(find.text('Register new customer'), findsWidgets);
        expect(find.widgetWithText(FilledButton, 'Register'), findsOneWidget);

        // Not the focus of this test — skips flight/nationality
        // requiredness so the tap below reaches the register call.
        await tester.tap(find.widgetWithText(SwitchListTile, 'Allow take-away'));
        await tester.pump();

        await tester.tap(find.widgetWithText(FilledButton, 'Register'));
        await tester.pumpAndSettle();

        expect(repo.lastRegisterCall!['action'], 'REGISTER_ADD');
        final listPersonal =
            repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>;
        expect(listPersonal.single['listIdentity'], existingIdentity);
        expect(listPersonal.single['provinceCode'], 'PC1');
        expect(listPersonal.single['cityCode'], 'CC1');
      },
    );
  });
}
