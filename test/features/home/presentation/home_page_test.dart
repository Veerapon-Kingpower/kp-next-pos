import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
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
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../../../core/storage/fakes.dart';
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
    view.physicalSize = const Size(800, 2400);
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
    );
  }

  HomePage buildPage({
    List<Customer> searchResult = const [],
    Object? searchError,
    FakeAuthRepository? logoutRepository,
  }) {
    final viewModel = HomeViewModel(
      restoreSession: RestoreSessionUseCase(
        FakeAuthRepository(currentSessionResult: _session),
      ),
      loadDeviceSettings: LoadDeviceSettingsUseCase(
        FakeSettingsRepository(settings: _settings),
      ),
      searchCustomer: SearchCustomerUseCase(
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
        final repo = FakeCustomerRepository();
        final flightRepo = FakeFlightRepository();
        return CustomerRegistrationViewModel(
          listNationalities: ListNationalitiesUseCase(
            FakeNationalityRepository(),
          ),
          listAgents: ListAgentsUseCase(repo),
          listGuides: ListGuidesUseCase(repo),
          getFlightByCode: GetFlightByCodeUseCase(flightRepo),
          getDateByFlight: GetDateByFlightUseCase(flightRepo),
          registerCustomer: RegisterCustomerUseCase(repo),
        );
      },
    );
  }

  testWidgets(
    'Customers is the default-active tab, showing the search UI',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      expect(find.text('Search customer'), findsOneWidget);
    },
  );

  testWidgets(
    'the header shows the signed-in user, module, and branch',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Somchai P.'), findsOneWidget);
      expect(find.textContaining('PosKpi'), findsOneWidget);
      expect(find.textContaining('03'), findsOneWidget);
    },
  );

  testWidgets('tapping Sale shows the barcode scan field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sale').last);
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(
        TextField,
        'Scan or type barcode (e.g. 5*8850012345678)',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'tapping Settings pushes the settings page without changing tabs',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
    },
  );

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

  testWidgets('cancelling the logout dialog does not log out', (
    tester,
  ) async {
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
    expect(find.text('Are you sure you want to log out?'), findsNothing);
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

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      expect(find.text('Search customer'), findsOneWidget);
      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.textContaining('P1234567'), findsOneWidget);
      // The member-card badge is driven by `typeCardMember` (from legacy's
      // `person.singleDiscount`), not the `isMember` flag.
      expect(find.text('GOLD'), findsOneWidget);
    },
  );

  testWidgets(
    'the Customers tab shows an empty state when the search finds nothing',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX9999');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(find.text('No customer found.'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping "Details" expands the card to show privileges, wallet, and tour details, but not contacts',
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
            {'tier': 'Gold'},
          ],
          walletMembers: [
            {'balance': '100'},
          ],
        ),
        tour: {'tourCode': 'T1'},
        agentCode: 'AG1',
        isMember: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      // Agent is part of the always-visible header now, matching legacy —
      // only privileges/wallet/tour stay behind the toggle; contacts are
      // deliberately not shown at all.
      expect(find.textContaining('AG1'), findsOneWidget);
      expect(find.text('tier: Gold'), findsNothing);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.text('contactType: MOBILE'), findsNothing);
      expect(find.text('contactValue: 0812345678'), findsNothing);
      expect(find.text('tier: Gold'), findsOneWidget);
      expect(find.text('balance: 100'), findsOneWidget);
      expect(find.text('tourCode: T1'), findsOneWidget);

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.text('tier: Gold'), findsNothing);
    },
  );

  testWidgets(
    'a customer with no extra data shows only the no-flight bar when expanded',
    (tester) async {
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

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0002');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.text('Flight: Not available'), findsOneWidget);
    },
  );

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

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      // The search field also holds "CPX0001" as typed input, so match only
      // a plain Text widget (not the field's EditableText) for the card.
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == 'CPX0001'),
        findsOneWidget,
      );
      expect(find.text('Registered'), findsOneWidget);
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

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(find.text('Not Registered'), findsOneWidget);
    },
  );

  testWidgets(
    'shows customer type and guide in the always-visible header',
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
          customerTypeCode: 'VIP',
          customerTypeDetail: 'VIP Member',
        ),
        tour: {},
        agentCode: '',
        subAgentCode: 'GD1',
        isMember: false,
      );

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      expect(find.textContaining('VIP'), findsWidgets);
      expect(find.textContaining('VIP Member'), findsOneWidget);
      expect(find.textContaining('GD1'), findsOneWidget);
    },
  );

  testWidgets(
    'shows flight info in the expanded details when present',
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

      await tester.pumpWidget(
        MaterialApp(home: buildPage(searchResult: const [customer])),
      );
      await tester.pumpAndSettle();

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      expect(find.textContaining('TG101'), findsOneWidget);
      expect(find.textContaining('BKK - NRT'), findsOneWidget);
      expect(find.textContaining('Gate A1'), findsOneWidget);
    },
  );

  testWidgets(
    'a "Register new customer" card sits separately below Search and opens the registration page',
    (tester) async {
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();

      // Physically separate from the search row (not the Search button
      // itself), per the "own card below Search" placement decision.
      expect(find.widgetWithText(FilledButton, 'Search'), findsOneWidget);
      final registerButton = find.widgetWithText(
        FilledButton,
        'Register new customer',
      );
      expect(registerButton, findsOneWidget);

      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(find.text('Register new customer'), findsWidgets);
      expect(
        find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == 'English name',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'tapping the edit icon on a found customer opens the registration form prefilled for editing',
    (tester) async {
      const customer = Customer(
        // 'REGISTER_EDIT' is what actually drives edit-mode UI on the
        // registration page — see `CustomerRegistrationPage._isEdit`.
        action: 'REGISTER_EDIT',
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

      final searchField = find.widgetWithText(
        TextField,
        'Search by shopping card, passport, or ID card number',
      );
      await tester.enterText(searchField, 'CPX0001');
      await tester.tap(find.widgetWithText(FilledButton, 'Search'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('editCustomerButton')));
      await tester.pumpAndSettle();

      expect(find.text('Customer profile'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byWidgetPredicate(
                (w) => w is TextField && w.decoration?.labelText == 'Passport no.',
              ),
            )
            .controller
            ?.text,
        'P1234567',
      );
    },
  );
}
