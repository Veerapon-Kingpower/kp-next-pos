import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/exchange_change_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';
import 'package:kp_pos/features/settings/domain/entities/sub_branch.dart';
import 'package:kp_pos/features/settings/domain/repositories/settings_repository.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../storage/fakes.dart';
import '../../features/auth/fake_auth_repository.dart';
import '../../features/customer/fake_customer_repository.dart';
import '../../features/flight/fake_flight_repository.dart';
import '../../features/nationality/fake_nationality_repository.dart';
import '../../features/sale/fake_sale_repository.dart';
import '../../features/settings/fake_settings_repository.dart';
import '../../helpers/test_id_finders.dart';

const _completeSettings = DeviceSettings(
  saleEngineEndpoint: 'https://sale',
  webServiceEndpoint: 'https://register',
  flightApi: 'https://flight',
);

({LoginViewModel Function() loginViewModelFactory, LogoutUseCase logoutUseCase})
_authDeps() {
  final repo = FakeAuthRepository();
  return (
    loginViewModelFactory: () =>
        LoginViewModel(loginUseCase: LoginUseCase(repo)),
    logoutUseCase: LogoutUseCase(repo),
  );
}

HomeViewModel _homeViewModel() {
  final authRepo = FakeAuthRepository();
  final settingsRepo = FakeSettingsRepository(settings: _completeSettings);
  return HomeViewModel(
    restoreSession: RestoreSessionUseCase(authRepo),
    loadDeviceSettings: LoadDeviceSettingsUseCase(settingsRepo),
    searchCustomer: SearchCustomerUseCase(FakeCustomerRepository()),
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
    lookupArticle: LookupArticleByBarcodeUseCase(FakeSaleRepository()),
    addItemToCart: AddItemToCartUseCase(FakeSaleRepository()),
    updateCartItemQuantity: UpdateCartItemQuantityUseCase(FakeSaleRepository()),
    removeCartItem: RemoveCartItemUseCase(FakeSaleRepository()),
    listCurrencies: ListCurrenciesUseCase(FakeSaleRepository()),
    changeOrderCurrency: ChangeOrderCurrencyUseCase(FakeSaleRepository()),
    exchangeChange: ExchangeChangeUseCase(FakeSaleRepository()),
  );
}

SettingsViewModel _settingsViewModel() {
  final repo = FakeSettingsRepository(settings: _completeSettings);
  return SettingsViewModel(
    loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
    saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
    listSubBranches: ListSubBranchesUseCase(repo),
  );
}

/// Wraps [FakeSettingsRepository] but never resolves `listSubBranches` —
/// simulates a real device hitting an unreachable/slow Register endpoint, to
/// check whether Save can get stuck on the full-page loading indicator
/// waiting on this best-effort lookup.
class _HangingSubBranchesRepository implements SettingsRepository {
  final FakeSettingsRepository _inner;
  _HangingSubBranchesRepository(this._inner);

  @override
  Future<DeviceSettings> readDeviceSettings() => _inner.readDeviceSettings();
  @override
  Future<void> saveDeviceSettings(DeviceSettings settings) =>
      _inner.saveDeviceSettings(settings);
  @override
  Future<List<SubBranch>> listSubBranches({
    required String baseUrl,
    String key = '',
  }) => Completer<List<SubBranch>>().future;
}

SettingsViewModel _settingsViewModelWithHangingSubBranches() {
  final repo = _HangingSubBranchesRepository(
    FakeSettingsRepository(settings: _completeSettings),
  );
  return SettingsViewModel(
    loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
    saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
    listSubBranches: ListSubBranchesUseCase(repo),
  );
}

void main() {
  testWidgets(
    'redirects to login when device settings are complete but no session exists',
    (tester) async {
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(_completeSettings),
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

      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets(
    'a Register endpoint that never answers the sub-branch lookup does not '
    'block the Settings page on the loading screen',
    (tester) async {
      final view = TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first;
      view.physicalSize = const Size(800, 3200);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
          sessionStorage: FakeSessionStorage(),
        ),
      );
      await sessionState.refreshSession();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        settingsViewModelFactory: _settingsViewModelWithHangingSubBranches,
        homeViewModelFactory: _homeViewModel,
        saleCartViewModelFactory: _saleCartViewModel,
        customerRegistrationViewModelFactory: _customerRegistrationViewModel,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      // The initial load's device-settings read still completes fine; only
      // the best-effort sub-branch lookup hangs, so settle() should not
      // block on it.
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
      expect(find.text('Loading device settings...'), findsNothing);
      expect(byTestId(SettingsIds.saveButton), findsOneWidget);

      Future<void> enterByLabel(String label, String value) async {
        final finder = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.enterText(finder, value);
      }

      await enterByLabel('Branch number', '03');
      await enterByLabel('Sale Engine endpoint', 'https://sale');
      await enterByLabel('Register endpoint', 'https://register');
      await enterByLabel('Flight API endpoint', 'https://flight');

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Loading device settings...'), findsNothing);
    },
  );

  testWidgets(
    'completing first-time device setup via Save lands on the login page, '
    'not stuck on the loading screen',
    (tester) async {
      final view = TestWidgetsFlutterBinding.ensureInitialized()
          .platformDispatcher
          .views
          .first;
      view.physicalSize = const Size(800, 3200);
      view.devicePixelRatio = 1.0;
      addTearDown(view.resetPhysicalSize);
      addTearDown(view.resetDevicePixelRatio);

      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(),
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

      Future<void> enterByLabel(String label, String value) async {
        final finder = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == label,
        );
        await tester.enterText(finder, value);
      }

      await enterByLabel('Branch number', '03');
      await enterByLabel('Sale Engine endpoint', 'https://sale');
      await enterByLabel('Register endpoint', 'https://register');
      await enterByLabel('Flight API endpoint', 'https://flight');

      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Loading device settings...'), findsNothing);
    },
  );

  testWidgets('signing out redirects from home back to login', (tester) async {
    final sessionState = SessionState(
      startupValidator: StartupValidator(
        deviceSettingsStorage: FakeDeviceSettingsStorage(_completeSettings),
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

    sessionState.signedOut();
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}
