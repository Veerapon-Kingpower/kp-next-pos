import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/app/app.dart';
import 'package:kp_pos/core/app/router.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_customer_types_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/register_customer_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/search_customer_usecase.dart';
import 'package:kp_pos/features/customer/presentation/customer_registration_view_model.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_date_by_flight_usecase.dart';
import 'package:kp_pos/features/flight/domain/usecases/get_flight_by_code_usecase.dart';
import 'package:kp_pos/features/home/presentation/home_view_model.dart';
import 'package:kp_pos/features/nationality/domain/usecases/list_nationalities_usecase.dart';
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

import 'core/storage/fakes.dart';
import 'features/auth/fake_auth_repository.dart';
import 'features/customer/fake_customer_repository.dart';
import 'features/flight/fake_flight_repository.dart';
import 'features/nationality/fake_nationality_repository.dart';
import 'features/sale/fake_sale_repository.dart';
import 'features/settings/fake_settings_repository.dart';
import 'helpers/test_id_finders.dart';

({LoginViewModel Function() loginViewModelFactory, LogoutUseCase logoutUseCase})
_authDeps() {
  final repo = FakeAuthRepository();
  return (
    loginViewModelFactory: () =>
        LoginViewModel(loginUseCase: LoginUseCase(repo)),
    logoutUseCase: LogoutUseCase(repo),
  );
}

SettingsViewModel _settingsViewModel([DeviceSettings? settings]) {
  final repo = FakeSettingsRepository(
    settings: settings ?? const DeviceSettings(),
  );
  return SettingsViewModel(
    loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
    saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
    listSubBranches: ListSubBranchesUseCase(repo),
  );
}

CustomerRegistrationViewModel _customerRegistrationViewModel() {
  final repo = FakeCustomerRepository();
  final flightRepo = FakeFlightRepository();
  return CustomerRegistrationViewModel(
    listNationalities: ListNationalitiesUseCase(FakeNationalityRepository()),
    listAgents: ListAgentsUseCase(repo),
    listGuides: ListGuidesUseCase(repo),
    listCustomerTypes: ListCustomerTypesUseCase(repo),
    getFlightByCode: GetFlightByCodeUseCase(flightRepo),
    getDateByFlight: GetDateByFlightUseCase(flightRepo),
    registerCustomer: RegisterCustomerUseCase(repo),
  );
}

SaleCartViewModel _saleCartViewModel() {
  final auth = FakeAuthRepository();
  return SaleCartViewModel(
    restoreSession: RestoreSessionUseCase(auth),
    getCart: GetCartUseCase(FakeSaleRepository()),
    updateOrderStatus: UpdateOrderStatusUseCase(FakeSaleRepository()),
    saveOrder: SaveOrderUseCase(FakeSaleRepository()),
    reverseVirtualStock: ReverseVirtualStockUseCase(FakeSaleRepository()),
    listPromotions: ListPromotionsUseCase(FakeSaleRepository()),
    findPromotion: FindPromotionUseCase(FakeSaleRepository()),
    actOnLines: ActOnLinesUseCase(FakeSaleRepository()),
    actOnOrder: ActOnOrderUseCase(FakeSaleRepository()),
    addItemToCart: AddItemToCartUseCase(FakeSaleRepository()),
    updateCartItemQuantity: UpdateCartItemQuantityUseCase(FakeSaleRepository()),
    editCartItem: EditCartItemUseCase(FakeSaleRepository()),
    lookupSerial: LookupSerialUseCase(FakeSaleRepository()),
    removeCartItem: RemoveCartItemUseCase(FakeSaleRepository()),
    listCurrencies: ListCurrenciesUseCase(FakeSaleRepository()),
    changeOrderCurrency: ChangeOrderCurrencyUseCase(FakeSaleRepository()),
    exchangeChange: ExchangeChangeUseCase(FakeSaleRepository()),
    addCashPayment: AddCashPaymentUseCase(FakeSaleRepository()),
    saveChangeExchange: SaveChangeExchangeUseCase(FakeSaleRepository()),
  );
}

HomeViewModel _homeViewModel([DeviceSettings? settings]) {
  final authRepo = FakeAuthRepository();
  final settingsRepo = FakeSettingsRepository(
    settings: settings ?? const DeviceSettings(),
  );
  return HomeViewModel(
    restoreSession: RestoreSessionUseCase(authRepo),
    loadDeviceSettings: LoadDeviceSettingsUseCase(settingsRepo),
    searchCustomer: SearchCustomerUseCase(FakeCustomerRepository()),
  );
}

void main() {
  testWidgets(
    'renders the device settings page when device settings are incomplete',
    (tester) async {
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(
            const DeviceSettings(),
          ),
          sessionStorage: FakeSessionStorage(),
        ),
      );
      await sessionState.refreshSession();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        settingsViewModelFactory: _settingsViewModel,
        homeViewModelFactory: _homeViewModel,
        saleCartViewModelFactory: _saleCartViewModel,
        customerRegistrationViewModelFactory: _customerRegistrationViewModel,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
      expect(byTestId(SettingsIds.saveButton), findsOneWidget);
    },
  );

  testWidgets(
    'renders the home placeholder when settings are complete and a session exists',
    (tester) async {
      const completeSettings = DeviceSettings(
        saleEngineEndpoint: 'https://sale',
        webServiceEndpoint: 'https://register',
        flightApi: 'https://flight',
      );
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(completeSettings),
          sessionStorage: FakeSessionStorage('abc123'),
        ),
      );
      await sessionState.refreshSession();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        settingsViewModelFactory: _settingsViewModel,
        homeViewModelFactory: _homeViewModel,
        saleCartViewModelFactory: _saleCartViewModel,
        customerRegistrationViewModelFactory: _customerRegistrationViewModel,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      await tester.pumpAndSettle();

      // Handheld Home (scan-to-find-customer) is the landing tab post-login.
      expect(byTestId(HomeIds.scanField), findsOneWidget);
    },
  );
}
