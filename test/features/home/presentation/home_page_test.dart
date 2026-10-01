import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:kp_pos/features/customer/presentation/widgets/member_sign_up.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/home/presentation/home_page.dart';
import 'package:kp_pos/features/home/presentation/home_view_model.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/order_status.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/get_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/leave_sale_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/line_discount_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_order_status_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/cash_payment_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/exchange_change_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/edit_cart_item_usecase.dart';
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
  machineNo: 'KPPOS05',
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

  // The Sale tab's repository in the last built page.
  late FakeSaleRepository saleRepository;

  SaleCartViewModel buildSaleCartViewModel() {
    final sale = saleRepository = FakeSaleRepository(
      cartResult: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [],
        orderNo: '42',
      ),
    );
    return SaleCartViewModel(
      restoreSession: RestoreSessionUseCase(
        FakeAuthRepository(currentSessionResult: _session),
      ),
      getCart: GetCartUseCase(sale),
      updateOrderStatus: UpdateOrderStatusUseCase(sale),
      saveOrder: SaveOrderUseCase(sale),
      reverseVirtualStock: ReverseVirtualStockUseCase(sale),
      listPromotions: ListPromotionsUseCase(sale),
      findPromotion: FindPromotionUseCase(sale),
      actOnLines: ActOnLinesUseCase(sale),
      addItemToCart: AddItemToCartUseCase(sale),
      updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
      editCartItem: EditCartItemUseCase(sale),
      lookupSerial: LookupSerialUseCase(sale),
      removeCartItem: RemoveCartItemUseCase(sale),
      listCurrencies: ListCurrenciesUseCase(sale),
      changeOrderCurrency: ChangeOrderCurrencyUseCase(sale),
      exchangeChange: ExchangeChangeUseCase(sale),
      addCashPayment: AddCashPaymentUseCase(sale),
      saveChangeExchange: SaveChangeExchangeUseCase(sale),
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

  testWidgets('desktop header Machine shows the login machine number', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    // One Text.rich per item: "Machine KPPOS05".
    expect(find.text('Machine KPPOS05', findRichText: true), findsOneWidget);
    // Store is no longer in the top bar.
    expect(find.textContaining('Store ', findRichText: true), findsNothing);
  });

  testWidgets('tapping Sale shows the barcode scan field', (tester) async {
    await tester.pumpWidget(MaterialApp(home: buildPage()));
    await tester.pumpAndSettle();

    await tester.tap(byTestId(NavIds.sale));
    await tester.pumpAndSettle();

    expect(byTestId(SaleIds.scanField), findsOneWidget);
    expect(byTestId(DesktopSaleIds.summary), findsOneWidget);
    expect(find.text('Sale · NORMAL'), findsOneWidget);
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

  testWidgets('a slow logout shows Logging out… until it finishes', (
    tester,
  ) async {
    final gate = Completer<void>();
    final authRepository = FakeAuthRepository(logoutGate: gate);
    await tester.pumpWidget(
      MaterialApp(home: buildPage(logoutRepository: authRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump();
    await tester.pump();

    // Legacy's loading — not a silent screen while the calls run.
    expect(byTestId(MenuIds.loggingOut), findsOneWidget);
    expect(find.text('Logging out…'), findsOneWidget);
    expect(authRepository.logoutCallCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(byTestId(MenuIds.loggingOut), findsNothing);
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
          memberId: 'M1',
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

      expect(inProfile(byTestId(ProfileIds.privileges)), findsOneWidget);
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

      expect(inProfile(byTestId(MemberIds.notFound)), findsOneWidget);
      expect(inProfile(find.text('No customer found')), findsOneWidget);
      expect(inProfile(find.text('for "CPX9999"')), findsOneWidget);
      // The two ways on: the register form beside it, or member sign-up.
      expect(inProfile(byTestId(MemberIds.signUpButton)), findsOneWidget);
    },
  );

  testWidgets(
    'the search field ✕ shows with text, empties it and keeps focus',
    (tester) async {
      await pumpCustomerTab(tester, buildPage());
      final input = find.descendant(
        of: byTestId(DesktopCustomerIds.searchField),
        matching: find.byType(TextField),
      );
      final clear = byTestId(FieldIds.clear(DesktopCustomerIds.searchField));
      expect(clear, findsNothing);

      await tester.enterText(input, 'CPX0001');
      await tester.pump();
      await tester.tap(clear);
      await tester.pump();

      final field = tester.widget<TextField>(input);
      expect(field.controller!.text, isEmpty);
      expect(field.focusNode!.hasFocus, isTrue);
      expect(clear, findsNothing);
    },
  );

  testWidgets('not found: Search again selects the query in the search field', (
    tester,
  ) async {
    await pumpCustomerTab(tester, buildPage());
    final searchField = find.widgetWithText(
      TextField,
      'Search by shopping card, passport, or ID card number',
    );
    await tester.enterText(searchField, 'CPX9999');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    await tester.ensureVisible(byTestId(MemberIds.notFoundSearchAgain));
    await tester.tap(byTestId(MemberIds.notFoundSearchAgain));
    await tester.pump();

    final field = tester.widget<TextField>(
      find.descendant(
        of: byTestId(DesktopCustomerIds.searchField),
        matching: find.byType(TextField),
      ),
    );
    expect(field.focusNode!.hasFocus, isTrue);
    expect(
      field.controller!.selection.textInside(field.controller!.text),
      'CPX9999',
    );
  });

  testWidgets(
    'the card shows privileges but no raw wallet, tour, contact, or header '
    'facts',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          memberId: 'M1',
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

      // The form beside the profile already holds name, passport, agent…;
      // wallets are the Carat / e-Purse tiles, never a key/value dump.
      expect(inProfile(find.text('Gold Member')), findsOneWidget);
      expect(inProfile(find.text('[VIP]:PROMO123')), findsOneWidget);
      expect(inProfile(find.textContaining('AG1')), findsNothing);
      expect(inProfile(find.text('Jane Doe')), findsNothing);
      expect(inProfile(find.text('Passport')), findsNothing);
      expect(find.text('contactType: MOBILE'), findsNothing);
      expect(inProfile(find.text('balance: 100')), findsNothing);
      expect(inProfile(find.text('tourCode: T1')), findsNothing);
    },
  );

  testWidgets(
    'privileges are a radio list with "No privilege" as the default',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          memberId: 'M1',
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

      bool checked(String id) => find
          .descendant(
            of: byTestId(id),
            matching: find.byIcon(Icons.radio_button_checked),
          )
          .evaluate()
          .isNotEmpty;

      final card = byTestId(ProfileIds.privilege(0));
      expect(card, findsOneWidget);
      expect(checked(ProfileIds.noPrivilege), isTrue, reason: 'default');
      expect(checked(ProfileIds.privilege(0)), isFalse);

      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(checked(ProfileIds.privilege(0)), isTrue);
      expect(checked(ProfileIds.noPrivilege), isFalse);

      await tester.tap(byTestId(ProfileIds.noPrivilege));
      await tester.pumpAndSettle();

      expect(checked(ProfileIds.privilege(0)), isFalse);
      expect(checked(ProfileIds.noPrivilege), isTrue);
    },
  );

  testWidgets(
    'selecting a privilege on the Customers tab shows it on the Sale page',
    (tester) async {
      const customer = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          memberId: 'M1',
          shoppingCard: 'CPX0001',
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

      await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
      await tester.tap(byTestId(ProfileIds.privilege(0)));
      await tester.pumpAndSettle();

      await tester.tap(byTestId(NavIds.sale));
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
        memberId: 'M1',
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

    Finder checkedIn(String id) => find.descendant(
      of: byTestId(id),
      matching: find.byIcon(Icons.radio_button_checked),
    );

    await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
    await tester.tap(byTestId(ProfileIds.privilege(0)));
    await tester.pumpAndSettle();

    expect(checkedIn(ProfileIds.privilege(0)), findsOneWidget);

    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    expect(checkedIn(ProfileIds.privilege(0)), findsNothing);
    expect(checkedIn(ProfileIds.noPrivilege), findsOneWidget);
  });

  testWidgets('a non-member: their Trip and the Not a member notice instead '
      'of Carat / e-Purse / privileges', (tester) async {
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
        customerTypeCode: 'VIP',
        customerTypeDetail: 'VIP Member',
        shoppingCard: 'CPX0001',
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
    await tester.enterText(searchField, 'CPX0002');
    await tester.tap(byTestId(DesktopCustomerIds.searchButton));
    await tester.pumpAndSettle();

    // Trip: what decides Collect or Take.
    expect(inProfile(byTestId(MemberIds.trip)), findsOneWidget);
    expect(inProfile(find.text('TG101 · BKK - NRT')), findsOneWidget);
    expect(
      inProfile(find.textContaining('Departs 18 Aug 10:00')),
      findsOneWidget,
    );
    expect(inProfile(find.text('Pickup: Gate A1')), findsOneWidget);
    // No member data, and why.
    expect(inProfile(byTestId(MemberIds.nonMember)), findsOneWidget);
    expect(inProfile(byTestId(ProfileIds.caratStat)), findsNothing);
    expect(inProfile(byTestId(ProfileIds.privileges)), findsNothing);
    // The rest stays in the form.
    expect(inProfile(find.textContaining('VIP Member')), findsNothing);
    expect(inProfile(find.textContaining('GD1')), findsNothing);
    expect(inProfile(find.text('CPX0001')), findsNothing);
  });

  group('desktop Customer (mockup screen 8)', () {
    const found = Customer(
      action: 'REGISTER_EDIT',
      isFound: true,
      person: CustomerPerson(
        memberId: 'M1',
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
          {'Code': 'CARAT_WALLET', 'PaymentCode': 'CARAT', 'Balance': 1475.0},
          {'Code': 'CASH_WALLET', 'PaymentCode': 'CASHW', 'Balance': 4200.0},
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
      // No member enrolment API — so no Register member button.
      expect(find.text('Register member'), findsNothing);
      // The Search label fits beside its ENTER chip — not "Se…".
      final searchLabel = tester.renderObject<RenderParagraph>(
        find.descendant(
          of: byTestId(DesktopCustomerIds.searchButton),
          matching: find.text('Search'),
        ),
      );
      expect(searchLabel.didExceedMaxLines, isFalse);

      await search(tester, 'CPX9999');
      expect(inProfile(byTestId(MemberIds.notFound)), findsOneWidget);
      expect(find.text('NEW CUSTOMER'), findsOneWidget);
    });

    testWidgets('a found customer loads into the form beside the profile', (
      tester,
    ) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      expect(find.text('UPDATE CUSTOMER'), findsOneWidget);
      expect(formText(tester, DesktopCustomerIds.passportNo), 'P1234567');
      expect(formText(tester, DesktopCustomerIds.englishName), 'Jane Doe');
      expect(inProfile(byTestId(ProfileIds.privileges)), findsOneWidget);
      // No "Shopping card …" chip under the search bar — the form's status
      // banner already shows the card ("Shopping card CPX0001 · Saving …").
      expect(find.text('Shopping card CPX0001'), findsNothing);
      // The form is the edit — no separate edit icon on the profile.
      expect(find.byKey(const Key('editCustomerButton')), findsNothing);
      final formLeft = tester.getTopLeft(byTestId(DesktopCustomerIds.form)).dx;
      final profileLeft = tester
          .getTopLeft(byTestId(DesktopCustomerIds.profile))
          .dx;
      expect(formLeft, lessThan(profileLeft));
    });

    testWidgets('profile stats: Carat and e-Purse from the wallets; no '
        'spend / visits / Attach to bill', (tester) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      String stat(String id) => tester
          .widget<Text>(
            find.descendant(of: byTestId(id), matching: find.byType(Text)),
          )
          .data!;
      expect(stat(ProfileIds.caratStat), '1,475.00');
      expect(stat(ProfileIds.ePurseStat), '฿4,200.00');
      expect(find.text('SPEND YTD'), findsNothing);
      expect(find.text('VISITS'), findsNothing);
      expect(find.text('Attach to bill'), findsNothing);
      expect(find.text('Recent purchases'), findsNothing);
      expect(byTestId(ProfileIds.caratExpiring), findsNothing);
    });

    testWidgets('the Sale nav starts the sale for the looked-up customer, '
        'with the picked privilege', (tester) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');
      expect(
        byTestId(ProfileIds.goToSaleButton),
        findsNothing,
        reason: 'no Start sale on the Customer tab',
      );

      await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
      await tester.tap(byTestId(ProfileIds.privilege(0)));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();

      // No second privilege prompt — the radio pick is used as-is.
      expect(find.text('Select privilege'), findsNothing);
      expect(byTestId(SaleIds.scanField), findsOneWidget);
      expect(find.text('Elite 10%'), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(NavIds.sale)),
        isSemantics(isSelected: true),
      );
    });

    testWidgets('an isFound: false card: Sale asks for a customer', (
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

      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.noCustomerNotice), findsOneWidget);
    });

    testWidgets('a fast-registered card is blocked with legacy "Oops !"', (
      tester,
    ) async {
      const fast = Customer(
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
          fastRegister: true,
        ),
        tour: {},
        agentCode: '',
        isMember: true,
      );
      await pumpCustomerTab(tester, buildPage(searchResult: const [fast]));
      await search(tester, 'CPX0001');

      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();

      expect(find.text('Oops !'), findsOneWidget);
      expect(find.text('ShoppingCard is fast register'), findsOneWidget);
      expect(byTestId(SaleIds.scanField), findsNothing);
    });

    testWidgets('the Carat tile notes the amount nearly expiring', (
      tester,
    ) async {
      const expiring = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          memberId: 'M2',
          englishName: 'KP DEV',
          passportNo: '1234567',
          nationality: 'USA',
          contacts: [],
          privileges: [],
          walletMembers: [
            {
              'Code': 'CARAT_WALLET',
              'PaymentCode': 'CARAT',
              'Balance': 1475.0,
              'NearlyExpiredAmount': 1475.0,
              'NearlyExpiredAt': '2029-12-31T16:59:59.999Z',
            },
          ],
        ),
        tour: {},
        agentCode: '',
        isMember: true,
      );
      await pumpCustomerTab(tester, buildPage(searchResult: const [expiring]));
      await search(tester, 'CPX0001');

      expect(
        find.descendant(
          of: byTestId(ProfileIds.caratExpiring),
          matching: find.text('1,475.00 expiring 31/12/2029'),
        ),
        findsOneWidget,
      );
      expect(inProfile(find.textContaining('WalletTypeCode')), findsNothing);
      // A small hint, well under the value.
      expect(
        tester
            .widget<Text>(
              find.descendant(
                of: byTestId(ProfileIds.caratExpiring),
                matching: find.byType(Text),
              ),
            )
            .style
            ?.fontSize,
        10.5,
      );
      // The expiring line doesn't make the Carat tile taller than e-Purse.
      double tileHeight(String id) => tester
          .getSize(
            find
                .ancestor(of: byTestId(id), matching: find.byType(Expanded))
                .first,
          )
          .height;
      expect(
        tileHeight(ProfileIds.caratStat),
        tileHeight(ProfileIds.ePurseStat),
      );
    });

    testWidgets('a registered customer shows a Registered status and an '
        'Update customer form', (tester) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');

      final banner = byTestId(RegisterIds.statusBanner);
      expect(
        find.descendant(of: banner, matching: find.text('Registered')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: banner,
          matching: find.textContaining('Shopping card CPX0001'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(RegisterIds.submitButton),
          matching: find.text('Update customer'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an unregistered card shows "Not registered yet"', (
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

      expect(
        find.descendant(
          of: byTestId(RegisterIds.statusBanner),
          matching: find.text('Not registered yet'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(RegisterIds.submitButton),
          matching: find.text('Register customer'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('New Register clears the lookup and resets the form', (
      tester,
    ) async {
      await pumpCustomerTab(tester, buildPage(searchResult: const [found]));
      await search(tester, 'CPX0001');
      expect(find.text('UPDATE CUSTOMER'), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(DesktopCustomerIds.newCustomerButton),
          matching: find.text('New Register'),
        ),
        findsOneWidget,
      );

      await tester.tap(byTestId(DesktopCustomerIds.newCustomerButton));
      await tester.pumpAndSettle();

      expect(find.text('NEW CUSTOMER'), findsOneWidget);
      expect(formText(tester, DesktopCustomerIds.passportNo), isEmpty);
      expect(formText(tester, DesktopCustomerIds.searchField), isEmpty);
      expect(byTestId(DesktopCustomerIds.profileEmpty), findsOneWidget);
    });

    testWidgets('saving the form returns to Home, looking the customer up '
        'by the saved shopping card', (tester) async {
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
      expect(
        tester.getSemantics(byTestId(NavIds.home)),
        isSemantics(isSelected: true),
      );
      expect(byTestId(DesktopIds.homeLookup), findsOneWidget);
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

      expect(byTestId(DesktopIds.homeIdle), findsOneWidget);
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

  group('desktop Home lookup (Find customer to start a sale)', () {
    const sofia = Customer(
      action: 'found',
      isFound: true,
      person: CustomerPerson(
        memberId: 'M1',
        englishName: 'Sofia Almeida',
        passportNo: 'CB912447',
        nationality: 'PRT',
        contacts: [
          {'contactType': 'MOBILE', 'contactValue': '+351 91 442 8830'},
        ],
        privileges: [
          Privilege(
            name: 'Elite 10%',
            discount: 10,
            typeCode: 'VIP',
            promoCode: 'PROMO123',
            raw: {'Name': 'Elite 10%', 'PromoCode': 'PROMO123'},
          ),
        ],
        walletMembers: [
          {'Code': 'CARAT_WALLET', 'PaymentCode': 'CARAT', 'Balance': 18420.0},
          {'Code': 'CASH_WALLET', 'PaymentCode': 'CASHW', 'Balance': 4200.0},
        ],
        shoppingCard: '8823-4419-0027',
        typeCardMember: 'KP Elite',
        customerTypeCode: 'TOURIST',
        gender: 'F',
        flightCode: 'TG916',
        flightDate: '2026-08-26',
        flightTime: '23:45',
        isActivate: true,
      ),
      tour: {},
      agentCode: '',
      isMember: true,
    );
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
        shoppingCard: 'CPX0001',
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );
    // `GetCustomer`'s "not found": a record, not an empty list —
    // `isFound: false` (legacy `customer.ts` routes it to CustomerFormPage).
    const notFound = Customer(
      action: 'REGISTER_ADD',
      isFound: false,
      person: CustomerPerson(
        englishName: '',
        passportNo: 'CB999999',
        nationality: '',
        contacts: [],
        privileges: [],
        walletMembers: [],
      ),
      tour: {},
      agentCode: '',
      isMember: false,
    );

    Future<void> lookUp(WidgetTester tester, HomePage page, String q) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: byTestId(DesktopIds.homeScanField),
          matching: find.byType(TextField),
        ),
        q,
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
    }

    Finder inLookup(Finder finder) =>
        find.descendant(of: byTestId(DesktopIds.homeLookup), matching: finder);

    bool scanHasFocus(WidgetTester tester) => tester
        .state<EditableTextState>(
          find.descendant(
            of: byTestId(DesktopIds.homeScanField),
            matching: find.byType(EditableText),
          ),
        )
        .widget
        .focusNode
        .hasFocus;

    testWidgets('the scan field has focus on open and keeps it after a scan', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();
      expect(scanHasFocus(tester), isTrue, reason: 'autofocus on open');

      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');
      expect(scanHasFocus(tester), isTrue, reason: 'kept after the scan');
    });

    testWidgets('a registered customer shows on Home, ready to start a sale', (
      tester,
    ) async {
      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');

      expect(
        tester.getSemantics(byTestId(NavIds.home)),
        isSemantics(isSelected: true),
      );
      expect(byTestId(DesktopIds.homeIdle), findsNothing);
      expect(inLookup(find.text('Registered customer')), findsOneWidget);
      expect(
        inLookup(find.textContaining('Found by passport CB912447')),
        findsOneWidget,
      );
      expect(inLookup(find.text('Sofia Almeida')), findsOneWidget);
      expect(inLookup(find.text('KP ELITE')), findsOneWidget);
      expect(
        inLookup(find.text('Female · PRT · TOURIST · +351 91 442 8830')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(DesktopIds.homeFact('flight')),
          matching: find.text('TG916 · 26 Aug 23:45'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: byTestId(DesktopIds.homeFact('carat')),
          matching: find.text('18,420.00'),
        ),
        findsOneWidget,
      );
      // No API for these — never faked.
      expect(inLookup(find.text('MEMBER ID')), findsNothing);
      expect(inLookup(find.text('LAST PURCHASE')), findsNothing);
      // Stepper: Register skipped, Sale current.
      expect(
        tester.getSemantics(byTestId(DesktopIds.homeStep(2))),
        isSemantics(isSelected: true),
      );
      expect(byTestId(ProfileIds.check(3)), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(ProfileIds.goToSaleButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: true),
      );
      expect(byTestId(DesktopIds.homeRegisterButton), findsNothing);
      expect(
        find.descendant(
          of: byTestId(DesktopIds.homeFact('ePurse')),
          matching: find.text('฿4,200.00'),
        ),
        findsOneWidget,
      );
      // Edit profile sits in the identity header, beside the name — not in
      // the action column, where Enquiry and Clear now fit in full.
      expect(
        tester.getTopLeft(byTestId(DesktopIds.homeEditProfileButton)).dx,
        lessThan(tester.getTopLeft(byTestId(ProfileIds.goToSaleButton)).dx),
      );
      // Two-up, not three-up: each takes half the action column.
      for (final id in [
        DesktopIds.homeEnquiryButton,
        DesktopIds.homeClearButton,
      ]) {
        expect(
          tester.getSize(byTestId(id)).width,
          greaterThan(130),
          reason: id,
        );
      }
    });

    testWidgets('Start sale carries the picked privilege to the Sale tab', (
      tester,
    ) async {
      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');
      await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
      await tester.tap(byTestId(ProfileIds.privilege(0)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byTestId(ProfileIds.goToSaleButton));
      await tester.tap(byTestId(ProfileIds.goToSaleButton));
      await tester.pumpAndSettle();

      expect(byTestId(SaleIds.scanField), findsOneWidget);
      expect(find.text('Elite 10%'), findsOneWidget);
      // Legacy getOrder() on entering Sale: opens the card's order.
      expect(saleRepository.lastOrderContext?.shoppingCard, '8823-4419-0027');
      // The pick goes as GetOrder's member / tier for the engine to price.
      expect(saleRepository.lastOrderContext?.tier, {
        'Name': 'Elite 10%',
        'PromoCode': 'PROMO123',
      });

      // Sale can switch it (legacy Privilege Selection) — No Privilege
      // re-prices the order without it.
      await tester.tap(byTestId(SaleIds.privilegeChangeButton));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: byTestId(SaleIds.privilegePicker),
          matching: find.text('Elite 10%'),
        ),
        findsOneWidget,
      );
      await tester.tap(byTestId(SaleIds.privilegeNone));
      await tester.pumpAndSettle();
      expect(saleRepository.lastOrderContext?.tier, isNull);
      expect(find.text('No Privilege'), findsOneWidget);
    });

    testWidgets('leaving Sale from the nav prompts, then unlocks the card '
        '(legacy ionViewCanLeave)', (tester) async {
      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');
      await tester.ensureVisible(byTestId(ProfileIds.goToSaleButton));
      await tester.tap(byTestId(ProfileIds.goToSaleButton));
      await tester.pumpAndSettle();
      expect(saleRepository.orderStatuses.map((s) => s.status), [
        OrderStatus.lock,
      ]);

      await tester.tap(byTestId(NavIds.customer));
      await tester.pumpAndSettle();
      expect(find.text('Do you want to go back?'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.leaveCancel));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(NavIds.sale)),
        isSemantics(isSelected: true),
        reason: 'Cancel stays on Sale, still locked',
      );
      expect(saleRepository.orderStatuses, hasLength(1));

      await tester.tap(byTestId(NavIds.customer));
      await tester.pumpAndSettle();
      await tester.tap(byTestId(SaleIds.leaveOk));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(NavIds.customer)),
        isSemantics(isSelected: true),
      );
      expect(saleRepository.orderStatuses.map((s) => s.status), [
        OrderStatus.lock,
        OrderStatus.unlock,
      ]);
    });

    testWidgets('an unregistered customer shows on Home; Start sale is '
        'disabled and Register opens the Customer form', (tester) async {
      await lookUp(
        tester,
        buildPage(searchResult: const [unregistered]),
        'CPX0001',
      );

      expect(inLookup(find.text('Not registered')), findsOneWidget);
      expect(
        tester.getSemantics(byTestId(DesktopIds.homeStep(1))),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(byTestId(ProfileIds.goToSaleButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );

      await tester.ensureVisible(byTestId(DesktopIds.homeRegisterButton));
      await tester.tap(byTestId(DesktopIds.homeRegisterButton));
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(byTestId(NavIds.customer)),
        isSemantics(isSelected: true),
      );
      expect(
        find.descendant(
          of: byTestId(RegisterIds.statusBanner),
          matching: find.text('Not registered yet'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('iPad landscape (1024 wide) lays the result out cleanly', (
      tester,
    ) async {
      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(byTestId(ProfileIds.goToSaleButton), findsOneWidget);
    });

    testWidgets('an isFound: false record goes to the Customer tab to '
        'register, prefilled from it', (tester) async {
      await lookUp(tester, buildPage(searchResult: const [notFound]), 'CB9');

      expect(byTestId(DesktopIds.homeLookup), findsNothing);
      expect(
        tester.getSemantics(byTestId(NavIds.customer)),
        isSemantics(isSelected: true),
      );
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: byTestId(DesktopCustomerIds.passportNo),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        'CB999999',
      );
    });

    testWidgets('nothing found goes to the Customer tab to register', (
      tester,
    ) async {
      await lookUp(tester, buildPage(), 'CPX9999');

      expect(
        tester.getSemantics(byTestId(NavIds.customer)),
        isSemantics(isSelected: true),
      );
      expect(inProfile(byTestId(MemberIds.notFound)), findsOneWidget);
      expect(inProfile(find.text('for "CPX9999"')), findsOneWidget);
      expect(find.text('NEW CUSTOMER'), findsOneWidget);
    });

    testWidgets('a non-member result shows the notice, not privileges', (
      tester,
    ) async {
      const walkIn = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'John Smith',
          passportNo: 'CB111111',
          nationality: 'GBR',
          contacts: [],
          privileges: [],
          walletMembers: [],
          shoppingCard: 'CPX0009',
          isActivate: true,
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await lookUp(tester, buildPage(searchResult: const [walkIn]), 'CB111111');

      expect(byTestId(MemberIds.nonMember), findsOneWidget);
      expect(byTestId(ProfileIds.privileges), findsNothing);

      await tester.ensureVisible(byTestId(MemberIds.signUpButton));
      await tester.tap(byTestId(MemberIds.signUpButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(byTestId(MemberIds.signUpQr), findsOneWidget);
      expect(find.text(memberSignUpUrl), findsOneWidget);
    });

    testWidgets('not found: Sign up opens the QR on the Customer tab', (
      tester,
    ) async {
      await lookUp(tester, buildPage(), 'CPX9999');
      await tester.ensureVisible(byTestId(MemberIds.signUpButton));
      await tester.tap(byTestId(MemberIds.signUpButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(byTestId(MemberIds.signUpQr), findsOneWidget);
    });

    testWidgets('Clear returns to the dashboard; Edit profile opens the form', (
      tester,
    ) async {
      await lookUp(tester, buildPage(searchResult: const [sofia]), 'CB912447');
      await tester.ensureVisible(byTestId(DesktopIds.homeEditProfileButton));
      await tester.tap(byTestId(DesktopIds.homeEditProfileButton));
      await tester.pumpAndSettle();
      expect(find.text('UPDATE CUSTOMER'), findsOneWidget);

      await tester.tap(byTestId(NavIds.home));
      await tester.pumpAndSettle();
      await tester.ensureVisible(byTestId(DesktopIds.homeClearButton));
      await tester.tap(byTestId(DesktopIds.homeClearButton));
      await tester.pumpAndSettle();
      expect(byTestId(DesktopIds.homeLookup), findsNothing);
      expect(byTestId(DesktopIds.homeIdle), findsOneWidget);
    });
  });

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
        memberId: 'M1',
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
        shoppingCard: 'CPX0001',
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

    testWidgets('a scan with one match opens that customer\'s profile', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');

      expect(byTestId(ProfileIds.page), findsOneWidget);
      expect(
        find.descendant(
          of: byTestId(ProfileIds.privilege(0)),
          matching: find.text('Gold Member'),
        ),
        findsOneWidget,
      );
      await tester.ensureVisible(byTestId(ProfileIds.registrationChecks));
      expect(byTestId(ProfileIds.check(0)), findsOneWidget);
    });

    testWidgets('several matches list as tiles; tapping one opens it', (
      tester,
    ) async {
      const john = Customer(
        action: 'found',
        isFound: true,
        person: CustomerPerson(
          englishName: 'John Smith',
          passportNo: 'P7654321',
          nationality: 'GBR',
          contacts: [],
          privileges: [],
          walletMembers: [],
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await pumpHandheld(tester, buildPage(searchResult: const [jane, john]));
      await scan(tester, 'P');

      expect(byTestId(ProfileIds.page), findsNothing);
      expect(
        find.descendant(
          of: byTestId(HomeIds.customerTile(1)),
          matching: find.text('John Smith'),
        ),
        findsOneWidget,
      );
      await tester.tap(byTestId(HomeIds.customerTile(1)));
      await tester.pumpAndSettle();
      expect(byTestId(ProfileIds.page), findsOneWidget);
    });

    Future<void> closeProfile(WidgetTester tester) async {
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
    }

    testWidgets(
      'the Home Sale tile starts the sale for the looked-up customer',
      (tester) async {
        await pumpHandheld(tester, buildPage(searchResult: const [jane]));
        await scan(tester, 'CPX0001');
        expect(
          byTestId(ProfileIds.goToSaleButton),
          findsNothing,
          reason: 'no Start sale on the profile',
        );

        await tester.ensureVisible(byTestId(ProfileIds.privilege(0)));
        await tester.tap(byTestId(ProfileIds.privilege(0)));
        await tester.pumpAndSettle();
        await closeProfile(tester);
        await tester.tap(byTestId(HomeIds.tileSale));
        await tester.pumpAndSettle();

        expect(byTestId(ProfileIds.page), findsNothing);
        expect(byTestId(SaleIds.noCustomerNotice), findsNothing);
        expect(byTestId(SaleIds.scanField), findsOneWidget);
        expect(find.text('Gold Member'), findsOneWidget);
      },
    );

    testWidgets('Start sale locks the card; leaving Sale unlocks it', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');
      await closeProfile(tester);
      await tester.tap(byTestId(HomeIds.tileSale));
      await tester.pumpAndSettle();
      expect(saleRepository.orderStatuses.map((s) => s.status), [
        OrderStatus.lock,
      ]);

      await tester.tap(byTestId(SaleIds.backButton));
      await tester.pumpAndSettle();

      // An empty order: legacy asks "Do you want to go back?".
      expect(find.text('Do you want to go back?'), findsOneWidget);
      await tester.tap(byTestId(SaleIds.leaveOk));
      await tester.pumpAndSettle();

      expect(byTestId(HomeIds.tileRegister), findsOneWidget);
      expect(saleRepository.orderStatuses.map((s) => s.status), [
        OrderStatus.lock,
        OrderStatus.unlock,
      ]);
    });

    testWidgets('a scan that finds nothing opens Register', (tester) async {
      await pumpHandheld(tester, buildPage());
      await scan(tester, 'CPX9999');
      expect(byTestId(RegisterIds.page), findsOneWidget);
    });

    testWidgets('an isFound: false record opens Register, not the profile', (
      tester,
    ) async {
      const notFound = Customer(
        action: 'REGISTER_ADD',
        isFound: false,
        person: CustomerPerson(
          englishName: '',
          passportNo: 'CB999999',
          nationality: '',
          contacts: [],
          privileges: [],
          walletMembers: [],
        ),
        tour: {},
        agentCode: '',
        isMember: false,
      );
      await pumpHandheld(tester, buildPage(searchResult: const [notFound]));
      await scan(tester, 'CB999999');
      expect(byTestId(ProfileIds.page), findsNothing);
      expect(byTestId(RegisterIds.page), findsOneWidget);
    });

    testWidgets('registering returns to Home, looking up the saved card', (
      tester,
    ) async {
      const takeAway = Customer(
        action: 'REGISTER_ADD',
        isFound: false,
        person: CustomerPerson(
          englishName: '',
          passportNo: 'CB999999',
          nationality: '',
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
      final searchRepo = FakeCustomerRepository(searchResult: const [takeAway]);
      final formRepo = FakeCustomerRepository(
        registerResult: const RegisterResult(
          outputs: [
            RegisterOutput(
              runningNo: '1',
              shoppingCard: 'CPX0009',
              qrShoppingCard: 'QR-CPX0009',
              coupons: [],
            ),
          ],
          messages: [],
          isComplete: true,
        ),
      );
      await pumpHandheld(
        tester,
        buildPage(searchRepository: searchRepo, formRepository: formRepo),
      );
      await scan(tester, 'CB999999');
      expect(byTestId(RegisterIds.page), findsOneWidget);

      await tester.ensureVisible(byTestId(RegisterIds.submitButton));
      await tester.tap(byTestId(RegisterIds.submitButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(byTestId(RegisterIds.page), findsNothing);
      expect(byTestId(HomeIds.tileRegister), findsOneWidget);
      expect(searchRepo.searchedShoppingCards, ['CB999999', 'CPX0009']);
    });

    testWidgets('Update customer opens the form with the registered status', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage(searchResult: const [jane]));
      await scan(tester, 'CPX0001');
      expect(find.text('Attach to bill'), findsNothing);

      await tester.tap(byTestId(ProfileIds.editButton));
      await tester.pumpAndSettle();

      expect(byTestId(RegisterIds.page), findsOneWidget);
      expect(byTestId(RegisterIds.statusBanner), findsOneWidget);
    });

    testWidgets('the Sale tile and the Sale nav item open the Sale screen', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());

      await tester.tap(byTestId(HomeIds.tileSale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanField), findsOneWidget);
      expect(find.text('Sale · NORMAL'), findsOneWidget);

      await tester.tap(byTestId(SaleIds.backButton));
      await tester.pumpAndSettle();
      expect(byTestId(HomeIds.scanField), findsOneWidget);

      await tester.tap(byTestId(NavIds.sale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.scanField), findsOneWidget);
    });

    testWidgets('Sale without a customer points back to the Home lookup', (
      tester,
    ) async {
      await pumpHandheld(tester, buildPage());
      await tester.tap(byTestId(HomeIds.tileSale));
      await tester.pumpAndSettle();
      expect(byTestId(SaleIds.noCustomerNotice), findsOneWidget);

      await tester.tap(byTestId(SaleIds.findCustomerButton));
      await tester.pumpAndSettle();
      expect(byTestId(HomeIds.scanField), findsOneWidget);
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
