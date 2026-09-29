import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/agent.dart';
import 'package:kp_pos/features/customer/domain/entities/customer_registration.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_customer_types_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/register_customer_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/search_customer_usecase.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_view_model.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/home/presentation/home_page.dart';
import 'package:kp_pos/features/home/presentation/home_view_model.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/exchange_change_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../../../core/storage/fakes.dart';
import '../../../helpers/test_id_finders.dart';
import '../../auth/fake_auth_repository.dart';
import '../../customer/fake_customer_repository.dart';
import '../../flight/fake_flight_repository.dart';
import '../../nationality/fake_nationality_repository.dart';
import '../../sale/fake_sale_repository.dart';
import '../../settings/fake_settings_repository.dart';

const _session = UserSession(
  sessionKey: 'abc123',
  branchNo: '03',
  userCode: 'U001',
  userName: 'Somchai P.',
  authorizedActions: [],
);

const _settings = DeviceSettings(
  moduleKey: 'PosKpi',
  branch: '03',
  saleEngineEndpoint: 'https://sale',
  webServiceEndpoint: 'https://register',
  flightApi: 'https://flight',
);

void main() {
  setUp(() {
    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    // Desktop width by default: the Customer-search tests below exercise the
    // desktop Customer tab. Handheld (< 840) tests set their own size.
    view.physicalSize = const Size(1200, 2400);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  SessionState buildSessionState() => SessionState(
    startupValidator: StartupValidator(
      deviceSettingsStorage: FakeDeviceSettingsStorage(),
      sessionStorage: FakeSessionStorage(),
    ),
  );

  SaleCartViewModel buildSaleCartViewModel() {
    final sale = FakeSaleRepository();
    return SaleCartViewModel(
      restoreSession: RestoreSessionUseCase(FakeAuthRepository()),
      lookupArticle: LookupArticleByBarcodeUseCase(sale),
      addItemToCart: AddItemToCartUseCase(sale),
      updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
      removeCartItem: RemoveCartItemUseCase(sale),
      listCurrencies: ListCurrenciesUseCase(sale),
      changeOrderCurrency: ChangeOrderCurrencyUseCase(sale),
      exchangeChange: ExchangeChangeUseCase(sale),
    );
  }

  HomePage buildPage({
    List<Customer> searchResult = const [],
    Object? searchError,
    FakeAuthRepository? logoutRepository,
    FakeCustomerRepository? searchRepository,
    FakeCustomerRepository? formRepository,
  }) {
    final viewModel = HomeViewModel(
      restoreSession: RestoreSessionUseCase(
        FakeAuthRepository(currentSessionResult: _session),
      ),
      loadDeviceSettings: LoadDeviceSettingsUseCase(
        FakeSettingsRepository(settings: _settings),
      ),
      searchCustomer: SearchCustomerUseCase(
        searchRepository ??
            FakeCustomerRepository(
              searchResult: searchResult,
              searchError: searchError,
            ),
      ),
    );
    final sessionState = buildSessionState();
    return HomePage(
      viewModel: viewModel,
      sessionState: sessionState,
      logoutUseCase: LogoutUseCase(logoutRepository ?? FakeAuthRepository()),
      settingsViewModelFactory: () {
        final repo = FakeSettingsRepository();
        return SettingsViewModel(
          loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
          saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
          listSubBranches: ListSubBranchesUseCase(repo),
        );
      },
      saleCartViewModelFactory: buildSaleCartViewModel,
      customerRegistrationViewModelFactory: () {
        final repo = formRepository ?? FakeCustomerRepository();
        final flightRepo = FakeFlightRepository();
        return CustomerRegistrationViewModel(
          listNationalities: ListNationalitiesUseCase(
            FakeNationalityRepository(),
          ),
          listAgents: ListAgentsUseCase(repo),
          listGuides: ListGuidesUseCase(repo),
          listCustomerTypes: ListCustomerTypesUseCase(repo),
          getFlightByCode: GetFlightByCodeUseCase(flightRepo),
          getDateByFlight: GetDateByFlightUseCase(flightRepo),
          registerCustomer: RegisterCustomerUseCase(repo),
        );
      },
    );
  }

  /// Pumps [page] at the default desktop width and opens the Customer tab,
  /// where the full customer search section (search button, register card,
  /// result card) lives.
  /// Scopes [finder] to the desktop Customer tab's profile column — the
  /// customer form beside it holds the same values in its fields.
  Finder inProfile(Finder finder) => find.descendant(
    of: byTestId(DesktopCustomerIds.profile),
    matching: finder,
  );

  Future<void> pumpCustomerTab(WidgetTester tester, HomePage page) async {
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer').last);
    await tester.pumpAndSettle();
  }

  testWidgets('the header shows the signed-in user, module, and branch', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Somchai P.'), findsOneWidget);
    expect(find.textContaining('PosKpi'), findsOneWidget);
    expect(find.textContaining('03'), findsOneWidget);
  });

  testWidgets('tapping Sale shows the barcode scan field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sale').last);
    await tester.pumpAndSettle();

    expect(byTestId(SaleIds.scanField), findsOneWidget);
    expect(byTestId(DesktopSaleIds.summary), findsOneWidget);
    expect(find.text('Sale · Shopping'), findsOneWidget);
  });

  testWidgets('tapping the logout icon asks for confirmation first', (
    tester,
  ) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: buildPage(logoutRepository: authRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();

    expect(find.text('Log out'), findsWidgets);
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
    expect(authRepository.logoutCallCount, 0);
  });

  testWidgets('confirming the logout dialog logs out', (tester) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: buildPage(logoutRepository: authRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(authRepository.logoutCallCount, 1);
  });

  testWidgets('cancelling the logout dialog does not log out', (tester) async {
    final authRepository = FakeAuthRepository();
    await tester.pumpWidget(
      MaterialApp(home: buildPage(logoutRepository: authRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(authRepository.logoutCallCount, 0);
    expect(
      inProfile(find.text('Are you sure you want to log out?')),
      findsNothing,
    );
  });

  testWidgets(
    'the Customers tab shows a combined hint and searches by shopping card, passport, or ID card number',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
          typeCardMember: 'Gold',
        ),
        tour: {},
        agentCode: 'AG1',
        isMember: true,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      expect(byTestId(DesktopCustomerIds.searchField), findsOneWidget);
      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      expect(inProfile(find.text('Jane Doe')), findsOneWidget);
      expect(inProfile(find.textContaining('P1234567')), findsOneWidget);
      // The member-card badge is driven by `typeCardMember` (from legacy's
      // `person.singleDiscount`), not the `isMember` flag.
      expect(inProfile(find.text('GOLD')), findsOneWidget);
    },
  );

  testWidgets(
    'the Customers tab shows an empty state when the search finds nothing',
    (tester) async {
      await pumpCustomerTab(tester, buildPage());

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX9999');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      expect(inProfile(find.text('No customer found.')), findsOneWidget);
    },
  );

  testWidgets(
    'the card always shows privileges, wallet, and tour details, but not contacts',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [
            {'contactType': 'MOBILE', 'contactValue': '0812345678'},
          ],
          privileges: [
            Privilege(
              name: 'Gold Member',
              discount: 10,
              typeCode: 'VIP',
              promoCode: 'PROMO123',
            ),
          ],
          walletMembers: [
            {'balance': '100'},
          ],
        ),
        tour: {'tourCode': 'T1'},
        agentCode: 'AG1',
        isMember: true,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      // Agent is part of the always-visible header, matching legacy;
      // privileges/wallet/tour are always visible too now (no toggle);
      // contacts are deliberately not shown at all.
      expect(inProfile(find.textContaining('AG1')), findsOneWidget);
      expect(find.text('contactType: MOBILE'), findsNothing);
      expect(find.text('contactValue: 0812345678'), findsNothing);
      expect(inProfile(find.text('Gold Member')), findsOneWidget);
      expect(inProfile(find.text('[VIP]:PROMO123')), findsOneWidget);
      expect(inProfile(find.text('balance: 100')), findsOneWidget);
      expect(inProfile(find.text('tourCode: T1')), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a privilege card selects it, tapping it again deselects it',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [
            Privilege(
              name: 'Gold Member',
              discount: 10,
              typeCode: 'VIP',
              promoCode: 'PROMO123',
            ),
          ],
          walletMembers: [],
          // Kept false so the header's status icon stays `Icons.cancel`,
          // not `Icons.check_circle` — avoids colliding with the
          // privilege card's own selected-state icon in these assertions.
          isActivate: false,
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      final card = find.byKey(const Key('privilegeCard_0'));
      expect(card, findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);

      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    },
  );

  testWidgets(
    'selecting a privilege on the Customers tab shows it on the Sale page',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [
            Privilege(
              name: 'Gold Member',
              discount: 10,
              typeCode: 'VIP',
              promoCode: 'PROMO123',
            ),
          ],
          walletMembers: [],
          isActivate: true,
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('privilegeCard_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sale').last);
      await tester.pumpAndSettle();

      expect(find.text('Gold Member'), findsOneWidget);
      expect(find.text('[VIP]:PROMO123'), findsOneWidget);
    },
  );

  testWidgets('starting a new search clears a previously selected privilege', (
    tester,
  ) async {
    const customer = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [Privilege(name: 'Gold Member', discount: 10)],
        walletMembers: [],
        isActivate: false,
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

    final searchField = find.widgetWithText(
      TextField,
      'Search by shopping card, passport, or ID card number',
    );
    await tester.enterText(searchField, 'CPX0001');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('privilegeCard_0')));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check_circle), findsNothing);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
  });

  testWidgets('a customer with no extra data shows only the no-flight bar', (
    tester,
  ) async {
    const customer = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'John Smith',
        passportNo: '',
        nationality: '',
        contacts: [],
        privileges: [],
        walletMembers: [],
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

    final searchField = find.widgetWithText(
      TextField,
      'Search by shopping card, passport, or ID card number',
    );
    await tester.enterText(searchField, 'CPX0002');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    expect(inProfile(find.text('Flight: Not available')), findsOneWidget);
  });

  testWidgets(
    'shows the shopping card number and registered status in the header',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
          shoppingCard: 'CPX0001',
          isActivate: true,
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      // The search field also holds "CPX0001" as typed input, so match only
      // a plain Text widget (not the field's EditableText) for the card.
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'CPX0001'),
        findsOneWidget,
      );
      expect(inProfile(find.text('Registered')), findsOneWidget);
    },
  );

  testWidgets(
    'a not-activated customer shows a Not Registered status in the header',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
          isActivate: false,
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );

      await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();

      expect(inProfile(find.text('Not Registered')), findsOneWidget);
    },
  );

  testWidgets('shows customer type and guide in the always-visible header', (
    tester,
  ) async {
    const customer = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [],
        walletMembers: [],
        customerTypeCode: 'VIP',
        customerTypeDetail: 'VIP Member',
      ),
      tour: {},
      agentCode: '',
      subAgentCode: 'GD1',
      isMember: false,
    );

    await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

    final searchField = find.widgetWithText(
      TextField,
      'Search by shopping card, passport, or ID card number',
    );
    await tester.enterText(searchField, 'CPX0001');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    expect(inProfile(find.textContaining('VIP')), findsWidgets);
    expect(inProfile(find.textContaining('VIP Member')), findsOneWidget);
    expect(inProfile(find.textContaining('GD1')), findsOneWidget);
  });

  testWidgets('shows flight info attached to the customer info when present', (
    tester,
  ) async {
    const customer = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [],
        walletMembers: [],
        flightCode: 'TG101',
        flightDate: '2026-08-18',
        flightTime: '10:00',
        flightRouteDetail: 'BKK - NRT',
        flightPickup: 'Gate A1',
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    await pumpCustomerTab(tester, buildPage(searchResult: const [customer]));

    final searchField = find.widgetWithText(
      TextField,
      'Search by shopping card, passport, or ID card number',
    );
    await tester.enterText(searchField, 'CPX0001');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    expect(inProfile(find.textContaining('TG101')), findsOneWidget);
    expect(inProfile(find.textContaining('BKK - NRT')), findsOneWidget);
    expect(inProfile(find.textContaining('Gate A1')), findsOneWidget);
  });

  group('desktop Customer (mockup screen 8)', () {
    const found = Customer(
      action: 'REGISTER_EDIT',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [
          Privilege(
            name: 'Elite 10%',
            discount: 10,
            promoCode: 'PROMO123',
            typeCode: 'VIP',
          ),
        ],
        walletMembers: [
          {'balance': 4200},
        ],
        shoppingCard: 'CPX0001',
        isActivate: true,
      ),
      tour: {},
      agentCode: '',
      isMember: true,
    );

    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(
        find.descendant(
          of: byTestId(DesktopCustomerIds.searchField),
          matching: find.byType(TextField),
        ),
        query,
      );
      await tester.tap(byTestId(DesktopCustomerIds.searchButton));
      await tester.pumpAndSettle();
    }

    String formText(WidgetTester tester, String id) => tester
        .widget<TextField>(
          find.descendant(of: byTestId(id), matching: find.byType(TextField)),
        )
        .controller!
        .text;

    testWidgets('a new-customer form beside an empty profile until a search '
        'finds someone', (tester) async {
      await pumpCustomerTab(tester, buildPage());
      expect(tester.takeException(), isNull);
      expect(byTestId(DesktopCustomerIds.form), findsOneWidget);
      expect(find.text('NEW CUSTOMER'), findsOneWidget);
      expect(byTestId(DesktopCustomerIds.profileEmpty), findsOneWidget);
      // Register member has no enrolment API — visibly inert.
      expect(
        tester.getSemantics(byTestId(DesktopCustomerIds.registerMemberButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );

      await search(tester, 'CPX9999');
      expect(inProfile(find.text('No customer found.')), findsOneWidget);
      expect(find.text('NEW CUSTOMER'), findsOneWidget);
    });

    testWidgets('a found customer loads into the form beside the profile', (
      tester,
    ) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      expect(find.text('EDIT CUSTOMER'), findsOneWidget);
      expect(formText(tester, DesktopCustomerIds.passportNo), 'P1234567');
      expect(formText(tester, DesktopCustomerIds.englishName), 'Jane Doe');
      expect(inProfile(find.text('Jane Doe')), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(DesktopCustomerIds.matchedCard),
          matching: find.text('Shopping card CPX0001'),
        ),
        findsOneWidget,
      );
      // The form is the edit — no separate edit icon on the profile.
      expect(find.byKey(const Key('editCustomerButton')), findsNothing);
      final formLeft = tester.getTopLeft(byTestId(DesktopCustomerIds.form)).dx;
      final profileLeft = tester
          .getTopLeft(byTestId(DesktopCustomerIds.profile))
          .dx;
      expect(formLeft, lessThan(profileLeft));
    });

    testWidgets('profile stats: e-Purse from the wallet, the rest not '
        'available', (tester) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      String stat(String id) => tester
          .widget<Text>(
            find.descendant(of: byTestId(id), matching: find.byType(Text)),
          )
          .data!;
      expect(stat(ProfileIds.ePurseStat), '฿4,200.00');
      expect(stat(ProfileIds.pointsStat), '—');
      expect(stat(ProfileIds.spendStat), '—');
      expect(stat(ProfileIds.visitsStat), '—');
      expect(byTestId(ProfileIds.recentPurchases), findsOneWidget);
    });

    testWidgets('Attach to bill carries the picked privilege to Sale', (
      tester,
    ) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      await tester.tap(find.byKey(const Key('privilegeCard_0')));
      await tester.pump();
      await tester.ensureVisible(byTestId(ProfileIds.attachButton));
      await tester.tap(byTestId(ProfileIds.attachButton));
      await tester.pumpAndSettle();

      expect(find.text('Sale · Shopping'), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(NavIds.sale)),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('Attach to bill is blocked for an unregistered card', (
      tester,
    ) async {
      const unregistered = Customer(
        action: 'REGISTER_ADD',
        isFound: false,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
          shoppingCard: 'CPX0001',
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await pumpCustomerTab(
        tester,
        buildPage(searchResult: const [unregistered]),
      );
      await search(tester, 'CPX0001');
      await tester.ensureVisible(byTestId(ProfileIds.attachButton));
      await tester.tap(byTestId(ProfileIds.attachButton));
      await tester.pumpAndSettle();

      expect(find.text('ShoppingCard is not register'), findsOneWidget);
    });

    testWidgets('New customer clears the lookup and resets the form', (
      tester,
    ) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');
      expect(find.text('EDIT CUSTOMER'), findsOneWidget);

      await tester.tap(byTestId(DesktopCustomerIds.newCustomerButton));
      await tester.pumpAndSettle();

      expect(find.text('NEW CUSTOMER'), findsOneWidget);
      expect(formText(tester, DesktopCustomerIds.passportNo), isEmpty);
      expect(formText(tester, DesktopCustomerIds.searchField), isEmpty);
      expect(byTestId(DesktopCustomerIds.profileEmpty), findsOneWidget);
    });

    testWidgets('saving the form looks the customer up again by the saved '
        'shopping card', (tester) async {
      final searchRepo = FakeCustomerRepository(searchResult: const [found]);
      final formRepo = FakeCustomerRepository(
        agentsResult: const [
          Agent(
            subAgentCode: '',
            subAgentDesc: '',
            agentCode: '',
            agentDesc: '',
            customerType: 'VIP',
            customerTypeDesc: 'Very important',
          ),
        ],
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
      await pumpCustomerTab(
        tester,
        buildPage(searchRepository: searchRepo, formRepository: formRepo),
      );

      // A take-away registration needs only the customer type.
      await tester.tap(byTestId(DesktopCustomerIds.nonInternational));
      await tester.pump();
      final typeField = find.descendant(
        of: byTestId(DesktopCustomerIds.customerType),
        matching: find.byType(TextField),
      );
      await tester.tap(typeField);
      await tester.enterText(typeField, 'VI');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.tap(
        byTestId(DesktopLookupIds.option(DesktopCustomerIds.customerType, 0)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(byTestId(RegisterIds.submitButton));
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      expect(find.text('Customer registered'), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(searchRepo.searchedShoppingCards, ['CPX0001']);
      expect(inProfile(find.text('Jane Doe')), findsOneWidget);
      expect(find.text('EDIT CUSTOMER'), findsOneWidget);
    });
  });

  testWidgets(
    'at desktop width, shows Home/Sale/Enquiry/Customer/Setup and lands on Home',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      expect(byTestId(DesktopIds.homeGreeting), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Sale'), findsWidgets);
      expect(find.text('Enquiry'), findsWidgets);
      expect(find.text('Customer'), findsWidgets);
      expect(find.text('Setup'), findsWidgets);
      // Mobile-only labels must not appear.
      expect(find.text('Customers'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );

  testWidgets(
    'at desktop width, tapping Enquiry shows the transaction search',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enquiry').last);
      await tester.pumpAndSettle();

      expect(byTestId(DesktopIds.enquirySearchButton), findsOneWidget);
    },
  );

  testWidgets('at desktop width, tapping Customer shows customer search', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Customer').last);
    await tester.pumpAndSettle();

    expect(byTestId(DesktopCustomerIds.searchField), findsOneWidget);
  });

  testWidgets('at desktop width, tapping Setup pushes the settings page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setup').last);
    await tester.pumpAndSettle();

    expect(find.text('Device settings'), findsOneWidget);
  });

  testWidgets(
    'at desktop width, scanning a card on the dashboard looks up the customer',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.descendant(
          of: byTestId(DesktopIds.homeScanField),
          matching: find.byType(TextField),
        ),
        'CPX0001',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(byTestId(DesktopCustomerIds.searchField), findsOneWidget);
      expect(inProfile(find.text('Jane Doe')), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(NavIds.customer)),
        isSemantics(isSelected: true),
      );
    },
  );

  testWidgets('at desktop width, the rail shows the station context', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();
    expect(find.text('Module PosKpi', findRichText: true), findsOneWidget);
    expect(find.text('Branch 03', findRichText: true), findsOneWidget);
    expect(
      find.descendant(
        of: byTestId(DesktopIds.userChip),
        matching: find.text('Cashier · U001'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('at desktop width, Sign out in the rail asks to confirm', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();
    await tester.tap(byTestId(NavIds.signOut));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to log out?'), findsOneWidget);
  });

  group('handheld layout (below desktop width)', () {
    const jane = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        englishName: 'Jane Doe',
        passportNo: 'P1234567',
        nationality: 'THA',
        contacts: [],
        privileges: [
          Privilege(
            name: 'Gold Member',
            discount: 10,
            typeCode: 'VIP',
            promoCode: 'PROMO123',
          ),
        ],
        walletMembers: [],
        isActivate: true,
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    Future<void> pumpHandheld(
      WidgetTester tester,
      HomePage page, {
      Size size = compactSize,
    }) async {
      setDeviceSize(tester, size);
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
    }

    Future<void> scan(WidgetTester tester, String code) async {
      await tester.enterText(
        find.descendant(
          of: byTestId(HomeIds.scanField),
          matching: find.byType(TextField),
        ),
        code,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
    }

    for (final entry in {
      'phone': compactSize,
      'iPad portrait': mediumSize,
    }.entries) {
      testWidgets(
        '${entry.key}: lands on Home with the Home/Sale/Enquiry/Menu nav',
        (tester) async {
          final handle = tester.ensureSemantics();
          await pumpHandheld(tester, buildPage(), size: entry.value);

          for (final id in [
            NavIds.home,
            NavIds.sale,
            NavIds.enquiry,
            NavIds.menu,
          ]) {
            expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
          }
          expect(byTestId(HomeIds.scanField), findsOneWidget);
          expect(
            tester.getSemantics(byTestId(NavIds.home)),
            isSemantics(isSelected: true),
          );
          expect(find.byType(NavigationRail), findsNothing);
          expect(find.text('Setup'), findsNothing);
          expect(find.text('Home dashboard — coming soon'), findsNothing);
          handle.dispose();
        },
      );
    }

    testWidgets('the Home header shows the signed-in user, module, branch', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      expect(find.text('PosKpi · Branch 03 · Somchai P.'), findsOneWidget);
    });

    testWidgets('scanning a shopping card lists the customer as a tile', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');

      expect(
        find.descendant(
          of: byTestId(HomeIds.customerTile(0)),
          matching: find.text('Jane Doe'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping the tile opens the customer profile', (tester) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');
      await tester.tap(byTestId(HomeIds.customerTile(0)));
      await tester.pumpAndSettle();

      expect(byTestId(ProfileIds.page), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(ProfileIds.privilege(0)),
          matching: find.text('Gold Member'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a scan that finds nothing shows the empty state', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await scan(tester, 'CPX9999');
      expect(find.text('No customer found.'), findsOneWidget);
    });

    testWidgets('Attach to bill carries the picked privilege to Sale', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');
      await tester.tap(byTestId(HomeIds.customerTile(0)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
      await tester.tap(byTestId(ProfileIds.privilege(0)));
      await tester.pump();
      await tester.tap(byTestId(ProfileIds.attachButton));
      await tester.pumpAndSettle();

      expect(byTestId(ProfileIds.page), findsNothing);
      expect(byTestId(SaleIds.scanField), findsOneWidget);
      expect(find.text('[VIP]:PROMO123'), findsOneWidget);
    });

    testWidgets('Attach to bill is blocked for an unregistered card', (
      tester,
    ) async {
      const unregistered = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'Jane Doe',
          passportNo: 'P1234567',
          nationality: 'THA',
          contacts: [],
          privileges: [],
          walletMembers: [],
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await pumpHandheld(tester, buildPage(searchResult: const [unregistered]));
      await scan(tester, 'CPX0001');
      await tester.tap(byTestId(HomeIds.customerTile(0)));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(ProfileIds.attachButton));
      await tester.pumpAndSettle();

      expect(find.text('ShoppingCard is not register'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(byTestId(ProfileIds.page), findsOneWidget);
    });

    testWidgets('the Sale tile and the Sale nav item open the Sale screen', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());

      await tester.tap(byTestId(HomeIds.tileSale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanField), findsOneWidget);
      expect(find.text('Sale · Shopping'), findsOneWidget);

      await tester.tap(byTestId(SaleIds.backButton));
      await tester.pumpAndSettle();
      expect(byTestId(HomeIds.scanField), findsOneWidget);

      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanField), findsOneWidget);
    });

    testWidgets('the Sale screen hides the bottom nav, as in the mockup', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();
      expect(byTestId(NavIds.home), findsNothing);
      expect(byTestId(SaleIds.checkoutButton), findsOneWidget);
    });

    testWidgets("the Sale screen's Customer action returns to Home lookup", (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(SaleIds.customerButton));
      await tester.pumpAndSettle();
      expect(byTestId(HomeIds.scanField), findsOneWidget);
    });

    testWidgets('the Register tile opens the registration page', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(HomeIds.tileRegister));
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'English name',
        ),
        findsOneWidget,
      );
    });

    testWidgets('the Enquiry nav item and tile open Enquiry', (tester) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(HomeIds.tileEnquiry));
      await tester.pumpAndSettle();
      expect(byTestId(EnquiryIds.searchField), findsOneWidget);
      expect(byTestId(NavIds.enquiry), findsOneWidget, reason: 'nav stays');
      expect(
        tester.getSemantics(byTestId(NavIds.enquiry)),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('Menu opens a sheet whose Settings item pushes settings', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(NavIds.menu));
      await tester.pumpAndSettle();

      expect(byTestId(MenuIds.sheet), findsOneWidget);
      await tester.tap(byTestId(MenuIds.settings));
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
    });

    testWidgets('Menu → Log out confirms, then logs out', (tester) async {
      final authRepository = FakeAuthRepository();
      await pumpHandheld(tester, buildPage(logoutRepository: authRepository));
      await tester.tap(byTestId(NavIds.menu));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(MenuIds.logout));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(authRepository.logoutCallCount, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
      await tester.pumpAndSettle();
      expect(authRepository.logoutCallCount, 1);
    });

    testWidgets('Menu on iPad portrait opens as a dialog, not a sheet', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(), size: mediumSize);
      await tester.tap(byTestId(NavIds.menu));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);
      expect(byTestId(MenuIds.settings), findsOneWidget);
    });
  });
}
