import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/app/app.dart';
import 'core/app/router.dart';
import 'core/app/session_state.dart';
import 'core/di/service_locator.dart';
import 'core/startup/startup_validator.dart';
import 'features/auth/auth_injection.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/login_view_model.dart';
import 'features/customer/customer_injection.dart';
import 'features/customer/presentation/customer_registration_view_model.dart';
import 'features/flight/flight_injection.dart';
import 'features/home/home_injection.dart';
import 'features/nationality/nationality_injection.dart';
import 'features/home/presentation/home_view_model.dart';
import 'features/sale/presentation/sale_cart_view_model.dart';
import 'features/sale/sale_injection.dart';
import 'features/settings/presentation/settings_view_model.dart';
import 'features/settings/settings_injection.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final support = await getApplicationSupportDirectory();
  setupCoreServiceLocator(cookieDirectory: '${support.path}/cookies/');
  setupAuthServiceLocator();
  setupCustomerServiceLocator();
  setupFlightServiceLocator();
  setupNationalityServiceLocator();
  setupSettingsServiceLocator();
  setupHomeServiceLocator();
  setupSaleServiceLocator();

  final sessionState = SessionState(startupValidator: sl<StartupValidator>());
  await sessionState.refreshSession();

  final router = buildRouter(
    sessionState,
    loginViewModelFactory: () => sl<LoginViewModel>(),
    settingsViewModelFactory: () => sl<SettingsViewModel>(),
    homeViewModelFactory: () => sl<HomeViewModel>(),
    saleCartViewModelFactory: () => sl<SaleCartViewModel>(),
    customerRegistrationViewModelFactory: () =>
        sl<CustomerRegistrationViewModel>(),
    logoutUseCase: sl<LogoutUseCase>(),
  );

  runApp(KpPosApp(router: router));
}
