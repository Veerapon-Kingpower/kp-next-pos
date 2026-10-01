import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/customer/domain/entities/agent.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/customer_registration.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_customer_types_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/register_customer_usecase.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_page.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_view_model.dart';
import 'package:kp_pos/features/flight/domain/entities/flight.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/nationality/domain/entities/nationality.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';

import '../../../helpers/test_id_finders.dart';
import '../../flight/fake_flight_repository.dart';
import '../../nationality/fake_nationality_repository.dart';
import '../fake_customer_repository.dart';

const _nationalities = [
  Nationality(countryCode: 'THA', countryName: 'Thailand'),
];
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
    // Handheld width (tall, so nothing scrolls) by default — these tests
    // cover the shared form logic through the handheld layout, which keeps
    // the plain labelled fields; the desktop group sets its own size.
    view.physicalSize = const Size(400, 2400);
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
    String? notFoundQuery,
    VoidCallback? onSearchAgain,
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
      listCustomerTypes: ListCustomerTypesUseCase(repo),
      getFlightByCode: GetFlightByCodeUseCase(flightRepo),
      getDateByFlight: GetDateByFlightUseCase(flightRepo),
      registerCustomer: RegisterCustomerUseCase(repo),
    );
    final page = CustomerRegistrationPage(
      viewModel: viewModel,
      userCode: 'U001',
      isAirportMpos: false,
      existingCustomer: existingCustomer,
      notFoundQuery: notFoundQuery,
      onSearchAgain: onSearchAgain,
    );

    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).push(MaterialPageRoute<void>(builder: (_) => page)),
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

  group('opened because nothing was found (handheld)', () {
    testWidgets('the banner names the query and offers Sign up / Search '
        'again', (tester) async {
      await tester.pumpWidget(buildHarness(notFoundQuery: 'AA1234567'));
      await openPage(tester);

      expect(byTestId(MemberIds.notFound), findsOneWidget);
      expect(find.text('No customer for "AA1234567"'), findsOneWidget);
      expect(byTestId(MemberIds.signUpButton), findsOneWidget);
      // It replaces the found-customer status banner.
      expect(byTestId(RegisterIds.statusBanner), findsNothing);

      await tester.tap(byTestId(MemberIds.signUpButton));
      await tester.pumpAndSettle();
      expect(byTestId(MemberIds.signUpQr), findsOneWidget);
    });

    testWidgets('Search again goes back to the lookup', (tester) async {
      var searchedAgain = 0;
      await tester.pumpWidget(
        buildHarness(
          notFoundQuery: 'AA1234567',
          onSearchAgain: () => searchedAgain++,
        ),
      );
      await openPage(tester);

      await tester.tap(byTestId(MemberIds.notFoundSearchAgain));
      await tester.pumpAndSettle();

      expect(searchedAgain, 1);
      expect(byTestId(RegisterIds.page), findsNothing);
    });

    testWidgets('no banner when opened any other way', (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);
      expect(byTestId(MemberIds.notFound), findsNothing);
    });
  });

  testWidgets('shows every form field', (tester) async {
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
    // Handheld also titles its section "Agent".
    expect(find.text('Agent'), findsNWidgets(2));
    expect(find.text('Guide'), findsOneWidget);
    expect(find.text('Customer type'), findsOneWidget);
    expect(find.text('Allow take-away'), findsOneWidget);
    expect(byTestId(RegisterIds.submitButton), findsOneWidget);
  });

  testWidgets(
    'Register is never disabled by field validity — tapping it empty shows a validation alert instead, matching legacy',
    (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      final registerButton = byTestId(RegisterIds.submitButton);
      // Legacy's Save/Update is always tappable; it validates on tap.
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
    'picking another date keeps the first candidate\'s time — legacy never '
    'lets the user edit the time',
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
      await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 8, 19))));
      await tester.pump();
      await tester.tap(byTestId(FlightPickerIds.confirmButton));
      await tester.pumpAndSettle();

      // The 19th's own candidate departs 14:00; handheld keeps 10:00.
      expect(find.text('19-08-2026 10:00'), findsOneWidget);
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

      await tester.tap(byTestId(RegisterIds.submitButton));
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

      await tester.tap(byTestId(RegisterIds.submitButton));
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

      await tester.tap(byTestId(RegisterIds.submitButton));
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
      expect(byTestId(RegisterIds.flightField), findsOneWidget);
      await tester.tap(find.widgetWithText(SwitchListTile, 'Allow take-away'));
      await tester.pump();
      // Legacy hides Flight Code / Flight Date under allowTakeAway.
      expect(byTestId(RegisterIds.flightField), findsNothing);
      expect(find.byKey(const Key('flightDateField')), findsNothing);
      await enterByLabel(tester, 'Customer type', 'VIP');
      await tester.pump();

      await tester.tap(byTestId(RegisterIds.submitButton));
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

    await tester.tap(byTestId(RegisterIds.submitButton));
    await tester.pumpAndSettle();

    expect(find.text('Passport already registered.'), findsOneWidget);
    expect(byTestId(RegisterIds.submitButton), findsOneWidget);
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
        // As GetCustomer sends them: the date at midnight, the time apart.
        flightDate: '2026-08-18T00:00:00',
        flightTime: '10:00',
        airlineCode: 'TG',
      ),
      tour: {},
      agentCode: 'AG1',
      subAgentCode: 'GD1',
      isMember: false,
    );

    // Legacy `setFormCustomerData()`: a saved take-away comes back as
    // flight `OP000` / airline `OP`.
    const takeAwayCustomer = Customer(
      action: 'REGISTER_EDIT',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [],
        walletMembers: [],
        customerTypeCode: 'VIP',
        flightCode: 'OP000',
        airlineCode: 'OP',
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    testWidgets('a saved take-away (OP000 / OP) turns Allow take-away back '
        'on, without the placeholder flight', (tester) async {
      await tester.pumpWidget(buildHarness(existingCustomer: takeAwayCustomer));
      await openPage(tester);
      await tester.pumpAndSettle();

      final toggle = tester.widget<SwitchListTile>(
        find.descendant(
          of: byTestId(RegisterIds.takeAwaySwitch),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(toggle.value, isTrue);
      expect(find.text('OP000'), findsNothing);
    });

    testWidgets('desktop: a saved take-away re-checks Non-international', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1400);
      await tester.pumpWidget(buildHarness(existingCustomer: takeAwayCustomer));
      await openPage(tester);
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.descendant(
          of: byTestId(DesktopCustomerIds.nonInternational),
          matching: find.byType(CheckboxListTile),
        ),
      );
      expect(checkbox.value, isTrue);
    });

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

        // Header title and submit button both read "Update customer".
        expect(find.text('Update customer'), findsNWidgets(2));
        expect(
          find.descendant(
            of: byTestId(RegisterIds.submitButton),
            matching: find.text('Update customer'),
          ),
          findsOneWidget,
        );
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
        // The customer's saved flight date + time (legacy
        // setFormCustomerData), not a looked-up candidate.
        expect(find.text('18-08-2026 10:00'), findsOneWidget);
      },
    );

    RegisterResult saved() => const RegisterResult(
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
    );

    testWidgets('an edit re-sends the saved flight date, not the first '
        'candidate, with the airline of the flight', (tester) async {
      final repo = FakeCustomerRepository(
        agentsResult: _agents,
        registerResult: saved(),
      );
      await tester.pumpWidget(
        buildHarness(
          existingCustomer: existingCustomer,
          repository: repo,
          // The first candidate (20th) is not the customer's date (18th).
          flightDates: const [
            Flight(
              flightCode: 'TG101',
              flightDescription: '',
              arrDepAirportName: '',
              destAirportName: '',
              flightType: 'D',
              airlineCode: 'TG',
              flightNo: '101',
              flightDate: '2026-08-20T09:00:00',
            ),
          ],
        ),
      );
      await openPage(tester);
      await tester.pumpAndSettle();
      expect(find.text('18-08-2026 10:00'), findsOneWidget);

      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();

      final person =
          (repo.lastRegisterCall!['listPersonal'] as List).single
              as Map<String, dynamic>;
      expect(person['flightCode'], 'TG101');
      expect(person['flightDate'], '2026-08-18');
      expect(person['flightTime'], '10:00');
      expect(person['airlineCode'], 'TG');
    });

    testWidgets('a take-away customer is re-sent with OP000 / OP, as legacy', (
      tester,
    ) async {
      final repo = FakeCustomerRepository(
        agentsResult: _agents,
        registerResult: saved(),
      );
      await tester.pumpWidget(
        buildHarness(existingCustomer: takeAwayCustomer, repository: repo),
      );
      await openPage(tester);
      await tester.pumpAndSettle();

      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();

      expect(repo.lastRegisterCall!['allowTakeAway'], isTrue);
      final person =
          (repo.lastRegisterCall!['listPersonal'] as List).single
              as Map<String, dynamic>;
      expect(person['flightCode'], 'OP000');
      expect(person['airlineCode'], 'OP');
    });

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

      await tester.tap(byTestId(RegisterIds.submitButton));
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
        expect(find.text('Register customer'), findsOneWidget);
        expect(byTestId(RegisterIds.submitButton), findsOneWidget);

        // Not the focus of this test — skips flight/nationality
        // requiredness so the tap below reaches the register call.
        await tester.tap(
          find.widgetWithText(SwitchListTile, 'Allow take-away'),
        );
        await tester.pump();

        await tester.tap(byTestId(RegisterIds.submitButton));
        await tester.pumpAndSettle();

        expect(repo.lastRegisterCall!['action'], 'REGISTER_ADD');
        final listPersonal =
            repo.lastRegisterCall!['listPersonal']
                as List<Map<String, dynamic>>;
        expect(listPersonal.single['listIdentity'], existingIdentity);
        expect(listPersonal.single['provinceCode'], 'PC1');
        expect(listPersonal.single['cityCode'], 'CC1');
      },
    );
  });

  group('input rules and clear buttons', () {
    Finder field(String id) =>
        find.descendant(of: byTestId(id), matching: find.byType(TextField));

    String textOf(WidgetTester tester, String id) =>
        tester.widget<TextField>(field(id)).controller!.text;

    testWidgets('name / passport take upper-case English only; mobile and '
        'email are validated inline', (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await tester.enterText(field(RegisterIds.englishNameField), 'Jane Doe1');
      await tester.enterText(field(RegisterIds.passportField), 'ab-12 3');
      await tester.enterText(field(RegisterIds.mobileField), '12ab3');
      await tester.enterText(field(RegisterIds.emailField), 'jane@mail');
      await tester.pump();

      expect(textOf(tester, RegisterIds.englishNameField), 'JANE DOE');
      expect(textOf(tester, RegisterIds.passportField), 'AB123');
      expect(textOf(tester, RegisterIds.mobileField), '123');
      expect(find.textContaining('Invalid mobile number'), findsOneWidget);
      expect(find.text('Invalid email address.'), findsOneWidget);

      await tester.enterText(field(RegisterIds.mobileField), '+66 812345678');
      await tester.pump();
      expect(find.textContaining('Invalid mobile number'), findsNothing);
    });

    testWidgets('handheld: WeChat takes no Thai; every field is upper-case', (
      tester,
    ) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await tester.enterText(field(RegisterIds.weChatField), 'jane_wc ไทย');
      await tester.enterText(field(RegisterIds.emailField), 'jane@mail.com');
      await tester.enterText(field(RegisterIds.nationalityField), 'tha');
      await tester.pump();

      expect(textOf(tester, RegisterIds.weChatField), 'JANE_WC');
      expect(textOf(tester, RegisterIds.emailField), 'JANE@MAIL.COM');
      expect(textOf(tester, RegisterIds.nationalityField), 'THA');
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets('desktop: WeChat takes no Thai; every field is upper-case', (
      tester,
    ) async {
      setDeviceSize(tester, const Size(1440, 1400));
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await tester.enterText(field(DesktopCustomerIds.weChat), 'jane_wc ไทย');
      await tester.enterText(field(DesktopCustomerIds.email), 'jane@mail.com');
      await tester.pump();

      expect(textOf(tester, DesktopCustomerIds.weChat), 'JANE_WC');
      expect(textOf(tester, DesktopCustomerIds.email), 'JANE@MAIL.COM');
    });

    testWidgets('Register rejects an invalid mobile number', (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);
      await fillRequiredFields(tester);
      await tester.enterText(field(RegisterIds.mobileField), '1234');
      await tester.pump();

      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      expect(find.text('Mobile number in invalid format.'), findsOneWidget);
    });

    testWidgets('handheld: clearing the flight search drops the flight and '
        'its date', (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);
      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();
      expect(find.text('18-08-2026 10:00'), findsOneWidget);

      await tester.tap(byTestId(FieldIds.clear(RegisterIds.flightField)));
      await tester.pump();

      expect(find.text('18-08-2026 10:00'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: byTestId(RegisterIds.flightField),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('the clear button shows with text and empties the field', (
      tester,
    ) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);
      final clear = byTestId(FieldIds.clear(RegisterIds.weChatField));
      expect(clear, findsNothing);

      await tester.enterText(field(RegisterIds.weChatField), 'jane_wc');
      await tester.pump();
      await tester.tap(clear);
      await tester.pump();

      expect(textOf(tester, RegisterIds.weChatField), isEmpty);
      expect(clear, findsNothing);
    });

    testWidgets('Customer type clears like the other fields', (tester) async {
      await tester.pumpWidget(buildHarness());
      await openPage(tester);
      final clear = byTestId(FieldIds.clear(RegisterIds.customerTypeField));
      expect(clear, findsNothing);

      await tester.enterText(field(RegisterIds.customerTypeField), 'VIP');
      await tester.pump();
      await tester.ensureVisible(clear);
      await tester.tap(clear);
      await tester.pump();

      expect(textOf(tester, RegisterIds.customerTypeField), isEmpty);
      expect(clear, findsNothing);
    });

    testWidgets('desktop fields follow the same rules and clear', (
      tester,
    ) async {
      setDeviceSize(tester, const Size(1440, 1400));
      await tester.pumpWidget(buildHarness());
      await openPage(tester);

      await tester.enterText(
        field(DesktopCustomerIds.englishName),
        'sofia almeida',
      );
      await tester.enterText(field(DesktopCustomerIds.passportNo), 'cb91-24');
      await tester.enterText(field(DesktopCustomerIds.mobile), '99');
      await tester.pump();

      expect(textOf(tester, DesktopCustomerIds.englishName), 'SOFIA ALMEIDA');
      expect(textOf(tester, DesktopCustomerIds.passportNo), 'CB9124');
      expect(find.textContaining('Invalid mobile number'), findsOneWidget);

      await tester.tap(byTestId(FieldIds.clear(DesktopCustomerIds.passportNo)));
      await tester.pump();
      expect(textOf(tester, DesktopCustomerIds.passportNo), isEmpty);
    });
  });

  group('handheld layout (below desktop width)', () {
    Future<void> openHandheld(
      WidgetTester tester, {
      Size size = compactSize,
      List<Flight> flightDates = _flightDates,
    }) async {
      setDeviceSize(tester, size);
      await tester.pumpWidget(buildHarness(flightDates: flightDates));
      await openPage(tester);
    }

    testWidgets('dark header, grouped sections and automation ids', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openHandheld(tester);
      expect(byTestId(RegisterIds.page), findsOneWidget);
      expect(find.text('Register customer'), findsOneWidget);
      expect(
        find.text('New shopping card · attaches to this sale'),
        findsOneWidget,
      );
      for (final id in [
        RegisterIds.scanPassportButton,
        RegisterIds.travellerSection,
        RegisterIds.submitButton,
        RegisterIds.cancelButton,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      expect(byTestId(RegisterIds.contactSection), findsOneWidget);
      expect(byTestId(RegisterIds.agentSection), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(RegisterIds.scanPassportButton)),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('Register in the bottom bar validates like desktop', (
      tester,
    ) async {
      await openHandheld(tester);
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      expect(find.text('Error!'), findsOneWidget);
      expect(find.text('Please input passport.'), findsOneWidget);
    });

    testWidgets('the flight date opens the handheld picker, limited to '
        'the resolved dates', (tester) async {
      final handle = tester.ensureSemantics();
      await openHandheld(tester, flightDates: _flightDatesWithGap);
      await enterByLabel(tester, 'Flight', 'TG');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(find.text('TG101 — Bangkok - Tokyo'));
      await tester.pump();

      await tester.tap(find.byKey(const Key('flightDateField')));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(byTestId(FlightPickerIds.sheet), findsOneWidget);
      expect(
        tester.getSemantics(
          byTestId(FlightPickerIds.day(DateTime(2026, 8, 19))),
        ),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );

      await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 8, 20))));
      await tester.pump();
      await tester.tap(byTestId(FlightPickerIds.confirmButton));
      await tester.pumpAndSettle();
      expect(find.textContaining('20-08-2026'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Cancel closes the page', (tester) async {
      await openHandheld(tester);
      await tester.tap(byTestId(RegisterIds.cancelButton));
      await tester.pumpAndSettle();
      expect(find.text('Open registration'), findsOneWidget);
    });

    testWidgets('iPad portrait renders without overflow', (tester) async {
      await openHandheld(tester, size: mediumSize);
      expect(tester.takeException(), isNull);
      expect(byTestId(RegisterIds.submitButton), findsOneWidget);
    });
  });

  group('desktop layout (mockup screens 8, 12, 13)', () {
    const typedAgents = [
      Agent(
        subAgentCode: 'GD1',
        subAgentDesc: 'Guide One',
        agentCode: 'AG1',
        agentDesc: 'Agent One',
        customerType: 'TOURIST',
        customerTypeDesc: 'Duty-free eligible',
      ),
      Agent(
        subAgentCode: 'GD2',
        subAgentDesc: 'Guide Two',
        agentCode: 'AG2',
        agentDesc: 'Agent Two',
        customerType: 'RESIDENT',
        customerTypeDesc: 'Thai · VAT applies',
      ),
    ];
    const saved = RegisterResult(
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
    const editCustomer = Customer(
      action: 'REGISTER_EDIT',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [],
        walletMembers: [],
        customerTypeCode: 'VIP',
        gender: 'F',
      ),
      tour: {},
      agentCode: 'AG1',
      subAgentCode: 'GD1',
      isMember: false,
    );

    Future<FakeCustomerRepository> openDesktop(
      WidgetTester tester, {
      Customer? existingCustomer,
      List<Flight> flightDates = _flightDates,
    }) async {
      setDeviceSize(tester, const Size(1440, 1400));
      final repo = FakeCustomerRepository(
        agentsResult: typedAgents,
        registerResult: saved,
      );
      await tester.pumpWidget(
        buildHarness(
          repository: repo,
          existingCustomer: existingCustomer,
          flightDates: flightDates,
        ),
      );
      await openPage(tester);
      await tester.pumpAndSettle();
      return repo;
    }

    Finder input(String id) =>
        find.descendant(of: byTestId(id), matching: find.byType(TextField));

    String textOf(WidgetTester tester, String id) =>
        tester.widget<TextField>(input(id)).controller!.text;

    Future<void> lookup(
      WidgetTester tester,
      String id,
      String text, {
      int option = 0,
    }) async {
      await tester.tap(input(id));
      await tester.enterText(input(id), text);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(byTestId(DesktopLookupIds.option(id, option)));
      await tester.pumpAndSettle();
    }

    String flightDateText(WidgetTester tester) => tester
        .widgetList<Text>(
          find.descendant(
            of: byTestId(DesktopCustomerIds.flightDate),
            matching: find.byType(Text),
          ),
        )
        .skip(1) // the label
        .map((t) => t.data)
        .join(' ');

    testWidgets('pushed: page frame, two-column form, required markers', (
      tester,
    ) async {
      await openDesktop(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Register new customer'), findsOneWidget);
      expect(byTestId(DesktopCustomerIds.form), findsOneWidget);
      expect(find.text('NEW CUSTOMER'), findsOneWidget);
      for (final label in [
        'FLIGHT CODE *',
        'FLIGHT DATE & TIME *',
        'PASSPORT NO. *',
        'ENGLISH NAME *',
        'NATIONALITY *',
        'CUSTOMER TYPE *',
        'AGENT CODE',
        'SUB AGENT CODE',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(
        tester.getTopLeft(byTestId(DesktopCustomerIds.flightDate)).dy,
        tester.getTopLeft(byTestId(DesktopCustomerIds.flightCode)).dy,
        reason: 'flight code and date share a row',
      );
      expect(
        find.descendant(
          of: byTestId(RegisterIds.submitButton),
          matching: find.text('Register customer'),
        ),
        findsOneWidget,
      );
      expect(flightDateText(tester), 'Pick a flight first');
    });

    testWidgets('Register still validates on tap, like legacy', (tester) async {
      await openDesktop(tester);
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      expect(find.text('Please input passport.'), findsOneWidget);
    });

    testWidgets('a picked flight resolves its date; the picker offers only '
        'operating days, each with its own departure time', (tester) async {
      final handle = tester.ensureSemantics();
      await openDesktop(tester, flightDates: _flightDatesWithGap);
      await lookup(tester, DesktopCustomerIds.flightCode, 'TG');

      expect(textOf(tester, DesktopCustomerIds.flightCode), 'TG101');
      expect(flightDateText(tester), 'Tue 18 Aug 2026 10:00');

      await tester.tap(byTestId(DesktopCustomerIds.flightDate));
      await tester.pumpAndSettle();
      expect(byTestId(DesktopCustomerIds.flightPicker), findsOneWidget);
      expect(
        tester.getSemantics(
          byTestId(FlightPickerIds.day(DateTime(2026, 8, 19))),
        ),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      await tester.tap(byTestId(FlightPickerIds.day(DateTime(2026, 8, 20))));
      await tester.pump();
      await tester.tap(byTestId(FlightPickerIds.confirmButton));
      await tester.pumpAndSettle();

      expect(flightDateText(tester), 'Thu 20 Aug 2026 09:00');
      handle.dispose();
    });

    testWidgets('non-international hides and clears the flight fields, as '
        'legacy hides them under allowTakeAway', (tester) async {
      await openDesktop(tester);
      await lookup(tester, DesktopCustomerIds.flightCode, 'TG');
      expect(flightDateText(tester), 'Tue 18 Aug 2026 10:00');

      expect(
        find.descendant(
          of: byTestId(DesktopCustomerIds.nonInternational),
          matching: find.text('Non-international flight (take away)'),
        ),
        findsOneWidget,
      );
      await tester.tap(byTestId(DesktopCustomerIds.nonInternational));
      await tester.pumpAndSettle();

      expect(byTestId(DesktopCustomerIds.flightCode), findsNothing);
      expect(byTestId(DesktopCustomerIds.flightDate), findsNothing);
      expect(find.text('PASSPORT NO.'), findsOneWidget);
      // Customer type stays required off Airport mode.
      expect(find.text('CUSTOMER TYPE *'), findsOneWidget);

      // Unticking brings the flight fields back, empty.
      await tester.tap(byTestId(DesktopCustomerIds.nonInternational));
      await tester.pumpAndSettle();
      expect(textOf(tester, DesktopCustomerIds.flightCode), isEmpty);
      expect(flightDateText(tester), 'Pick a flight first');
    });

    testWidgets('non-international hides the flight pane of Flight & '
        'passport', (tester) async {
      await openDesktop(tester);
      await tester.tap(byTestId(DesktopCustomerIds.nonInternational));
      await tester.pumpAndSettle();

      await tester.tap(byTestId(DesktopCustomerIds.travellerButton));
      await tester.pumpAndSettle();

      expect(byTestId(DesktopCustomerIds.traveller), findsOneWidget);
      expect(byTestId(TravellerIds.flightSearch), findsNothing);
    });

    testWidgets('clearing a lookup drops its value — the flight takes its '
        'date along, the agent its sub agent', (tester) async {
      await openDesktop(tester);
      await lookup(tester, DesktopCustomerIds.flightCode, 'TG');
      expect(flightDateText(tester), 'Tue 18 Aug 2026 10:00');
      await lookup(tester, DesktopCustomerIds.agentCode, 'AG');
      await lookup(tester, DesktopCustomerIds.subAgentCode, 'GD');
      await lookup(tester, DesktopCustomerIds.nationality, 'tha');

      await tester.tap(byTestId(FieldIds.clear(DesktopCustomerIds.flightCode)));
      await tester.pumpAndSettle();
      expect(textOf(tester, DesktopCustomerIds.flightCode), isEmpty);
      expect(flightDateText(tester), 'Pick a flight first');

      await tester.tap(byTestId(FieldIds.clear(DesktopCustomerIds.agentCode)));
      await tester.pumpAndSettle();
      expect(textOf(tester, DesktopCustomerIds.agentCode), isEmpty);
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), isEmpty);
      expect(
        tester
            .widget<TextField>(input(DesktopCustomerIds.subAgentCode))
            .enabled,
        isFalse,
      );

      await tester.tap(
        byTestId(FieldIds.clear(DesktopCustomerIds.nationality)),
      );
      await tester.pumpAndSettle();
      await tester.enterText(input(DesktopCustomerIds.passportNo), 'P1');
      await tester.enterText(input(DesktopCustomerIds.englishName), 'A');
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      // Legacy order: nationality is checked before the flight.
      expect(find.text('Please input nationality.'), findsOneWidget);
    });

    testWidgets('sub agent waits for an agent; changing the agent clears it', (
      tester,
    ) async {
      await openDesktop(tester);
      expect(
        tester
            .widget<TextField>(input(DesktopCustomerIds.subAgentCode))
            .enabled,
        isFalse,
      );
      expect(find.text('Choose an agent code first'), findsOneWidget);

      await lookup(tester, DesktopCustomerIds.agentCode, 'AG');
      expect(textOf(tester, DesktopCustomerIds.agentCode), 'AG1');
      await lookup(tester, DesktopCustomerIds.subAgentCode, 'GD');
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), 'GD1');

      await lookup(tester, DesktopCustomerIds.agentCode, 'AG', option: 1);
      expect(textOf(tester, DesktopCustomerIds.agentCode), 'AG2');
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), isEmpty);
    });

    testWidgets('registers with the looked-up values', (tester) async {
      final repo = await openDesktop(tester);
      await tester.enterText(input(DesktopCustomerIds.passportNo), 'P1234567');
      await tester.enterText(input(DesktopCustomerIds.englishName), 'Jane Doe');
      await lookup(tester, DesktopCustomerIds.flightCode, 'TG');
      await lookup(tester, DesktopCustomerIds.nationality, 'tha');
      await lookup(tester, DesktopCustomerIds.customerType, 'tou');
      expect(textOf(tester, DesktopCustomerIds.customerType), 'TOURIST');
      expect(repo.lastAgentsTypeSearch, 'C');

      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();

      final person =
          (repo.lastRegisterCall!['listPersonal'] as List<Map<String, dynamic>>)
              .single;
      expect(person['nationality'], 'THA');
      expect(person['customerTypeCode'], 'TOURIST');
      expect(person['flightCode'], 'TG101');
      expect(person['flightDate'], '2026-08-18');
      expect(find.text('Customer registered'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Open registration'), findsOneWidget);
    });

    testWidgets('editing: Undo restores the loaded customer', (tester) async {
      await openDesktop(tester, existingCustomer: editCustomer);
      expect(find.text('UPDATE CUSTOMER'), findsOneWidget);
      expect(textOf(tester, DesktopCustomerIds.passportNo), 'P1234567');
      expect(textOf(tester, DesktopCustomerIds.nationality), 'THA');
      expect(textOf(tester, DesktopCustomerIds.customerType), 'VIP');
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), 'GD1');
      expect(find.text('Female'), findsOneWidget);

      await tester.enterText(input(DesktopCustomerIds.passportNo), 'X999');
      await lookup(tester, DesktopCustomerIds.agentCode, 'AG', option: 1);
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), isEmpty);

      await tester.tap(byTestId(DesktopCustomerIds.undoButton));
      await tester.pumpAndSettle();

      expect(textOf(tester, DesktopCustomerIds.passportNo), 'P1234567');
      expect(textOf(tester, DesktopCustomerIds.agentCode), 'AG1');
      expect(textOf(tester, DesktopCustomerIds.subAgentCode), 'GD1');
      expect(
        find.descendant(
          of: byTestId(RegisterIds.submitButton),
          matching: find.text('Update customer'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Flight & passport writes back into the form and resolves '
        'the flight date', (tester) async {
      await openDesktop(tester);
      await tester.tap(byTestId(DesktopCustomerIds.travellerButton));
      await tester.pumpAndSettle();
      expect(byTestId(DesktopCustomerIds.traveller), findsOneWidget);

      await tester.enterText(
        find.descendant(
          of: byTestId(DesktopCustomerIds.travellerPassportNo),
          matching: find.byType(TextField),
        ),
        'CB912447',
      );
      await tester.enterText(
        find.descendant(
          of: byTestId(TravellerIds.flightSearch),
          matching: find.byType(TextField),
        ),
        'TG',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(TravellerIds.flight(0)));
      await tester.pump();
      await tester.tap(byTestId(TravellerIds.saveButton));
      await tester.pumpAndSettle();

      expect(byTestId(DesktopCustomerIds.traveller), findsNothing);
      expect(textOf(tester, DesktopCustomerIds.passportNo), 'CB912447');
      expect(textOf(tester, DesktopCustomerIds.flightCode), 'TG101');
      expect(flightDateText(tester), 'Tue 18 Aug 2026 10:00');
    });

    testWidgets('embedded: no page chrome, and saving reports the shopping '
        'card instead of closing', (tester) async {
      setDeviceSize(tester, const Size(1440, 1400));
      final repo = FakeCustomerRepository(
        agentsResult: typedAgents,
        registerResult: saved,
      );
      final flightRepo = FakeFlightRepository(
        searchResult: _flights,
        dateResult: _flightDates,
      );
      final savedCards = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerRegistrationPage(
                embedded: true,
                onSaved: savedCards.add,
                viewModel: CustomerRegistrationViewModel(
                  listNationalities: ListNationalitiesUseCase(
                    FakeNationalityRepository(searchResult: _nationalities),
                  ),
                  listAgents: ListAgentsUseCase(repo),
                  listGuides: ListGuidesUseCase(repo),
                  listCustomerTypes: ListCustomerTypesUseCase(repo),
                  getFlightByCode: GetFlightByCodeUseCase(flightRepo),
                  getDateByFlight: GetDateByFlightUseCase(flightRepo),
                  registerCustomer: RegisterCustomerUseCase(repo),
                ),
                userCode: 'U001',
                isAirportMpos: false,
                existingCustomer: editCustomer,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Customer profile'), findsNothing);

      // Take-away skips the flight requirement for this test.
      await tester.tap(byTestId(DesktopCustomerIds.nonInternational));
      await tester.pump();
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(savedCards, ['CPX0099']);
      expect(byTestId(DesktopCustomerIds.form), findsOneWidget);
    });
  });
}
