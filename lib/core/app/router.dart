import 'package:go_router/go_router.dart';

import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/authenticated_home_placeholder_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/login_view_model.dart';
import '../startup/startup_validator.dart';
import 'placeholder_pages.dart';
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
  required LogoutUseCase logoutUseCase,
}) {
  return GoRouter(
    // TEMPORARY (dev testing, per user request): defaults to /login so the
    // login screen is reachable before task 6.x's real device-setup
    // workflow exists. Revert to AppRoutes.deviceSetup once that lands.
    initialLocation: AppRoutes.login,
    refreshListenable: sessionState,
    redirect: (context, state) {
      final status = sessionState.status;
      final location = state.matchedLocation;

      if (status == StartupStatus.needsDeviceSetup) {
        // TEMPORARY: also allow /login through the incomplete-device-setup
        // gate so it can be reached for testing — see note above.
        if (location == AppRoutes.deviceSetup || location == AppRoutes.login) {
          return null;
        }
        return AppRoutes.deviceSetup;
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
        builder: (context, state) => const DeviceSetupPlaceholderPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => LoginPage(
          viewModel: loginViewModelFactory(),
          sessionState: sessionState,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => AuthenticatedHomePlaceholderPage(
          sessionState: sessionState,
          logoutUseCase: logoutUseCase,
        ),
      ),
    ],
  );
}
