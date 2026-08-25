import 'package:go_router/go_router.dart';

import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/login_view_model.dart';
import '../../features/customer/presentation/customer_registration_view_model.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/home/presentation/home_view_model.dart';
import '../../features/sale/presentation/sale_cart_view_model.dart';
import '../../features/settings/presentation/settings_page.dart';
import '../../features/settings/presentation/settings_view_model.dart';
import '../startup/startup_validator.dart';
import 'session_state.dart';

abstract class AppRoutes {
  static const deviceSetup = '/device-setup';
  static const login = '/login';
  static const home = '/home';
}

/// Central auth guard: every navigation is redirected based on
/// [SessionState.status], matching the legacy app's own startup gate
/// (incomplete device settings → Settings; no session → Login; otherwise →
/// Home) rather than each page checking auth individually.
///
/// Route-level dependencies are passed in rather than pulled from the
/// global service locator, so the router stays a pure function of its
/// inputs and is testable without standing up full app DI — `main.dart`
/// (the composition root) is the only caller expected to wire real ones.
GoRouter buildRouter(
  SessionState sessionState, {
  required LoginViewModel Function() loginViewModelFactory,
  required SettingsViewModel Function() settingsViewModelFactory,
  required HomeViewModel Function() homeViewModelFactory,
  required SaleCartViewModel Function() saleCartViewModelFactory,
  required CustomerRegistrationViewModel Function()
  customerRegistrationViewModelFactory,
  required LogoutUseCase logoutUseCase,
}) {
  return GoRouter(
    initialLocation: AppRoutes.deviceSetup,
    refreshListenable: sessionState,
    redirect: (context, state) {
      final status = sessionState.status;
      final location = state.matchedLocation;

      if (status == StartupStatus.needsDeviceSetup) {
        return location == AppRoutes.deviceSetup ? null : AppRoutes.deviceSetup;
      }
      if (status == StartupStatus.needsLogin) {
        return location == AppRoutes.login ? null : AppRoutes.login;
      }
      // status == StartupStatus.ready
      if (location == AppRoutes.login || location == AppRoutes.deviceSetup) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.deviceSetup,
        builder: (context, state) => SettingsPage(
          viewModel: settingsViewModelFactory(),
          sessionState: sessionState,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          viewModel: loginViewModelFactory(),
          sessionState: sessionState,
          settingsViewModelFactory: settingsViewModelFactory,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => HomePage(
          viewModel: homeViewModelFactory(),
          sessionState: sessionState,
          logoutUseCase: logoutUseCase,
          settingsViewModelFactory: settingsViewModelFactory,
          saleCartViewModelFactory: saleCartViewModelFactory,
          customerRegistrationViewModelFactory:
              customerRegistrationViewModelFactory,
        ),
      ),
    ],
  );
}
