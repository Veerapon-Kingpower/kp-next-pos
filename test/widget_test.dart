import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/app.dart';
import 'package:kp_pos/core/app/router.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';

import 'core/storage/fakes.dart';
import 'features/auth/fake_auth_repository.dart';

({LoginViewModel Function() loginViewModelFactory, LogoutUseCase logoutUseCase})
_authDeps() {
  final repo = FakeAuthRepository();
  return (
    loginViewModelFactory: () =>
        LoginViewModel(loginUseCase: LoginUseCase(repo)),
    logoutUseCase: LogoutUseCase(repo),
  );
}

void main() {
  testWidgets(
    'the device setup route is still reachable when device settings are incomplete '
    '(the guard temporarily also defaults to /login for testing — see router.dart)',
    (tester) async {
      final sessionState = SessionState(
        startupValidator: StartupValidator(
          deviceSettingsStorage: FakeDeviceSettingsStorage(
            const DeviceSettings(),
          ),
          sessionStorage: FakeSessionStorage(),
        ),
      );
      await sessionState.refresh();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      await tester.pumpAndSettle();

      router.go(AppRoutes.deviceSetup);
      await tester.pumpAndSettle();

      expect(find.textContaining('Device setup'), findsOneWidget);
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
      await sessionState.refresh();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      await tester.pumpAndSettle();

      expect(find.textContaining('Home'), findsOneWidget);
    },
  );
}
