import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/app.dart';
import 'package:kp_pos/core/app/router.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/domain/usecases/logout_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';

import '../storage/fakes.dart';
import '../../features/auth/fake_auth_repository.dart';

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
      await sessionState.refresh();

      final deps = _authDeps();
      final router = buildRouter(
        sessionState,
        loginViewModelFactory: deps.loginViewModelFactory,
        logoutUseCase: deps.logoutUseCase,
      );

      await tester.pumpWidget(KpPosApp(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets('signing out redirects from home back to login', (tester) async {
    final sessionState = SessionState(
      startupValidator: StartupValidator(
        deviceSettingsStorage: FakeDeviceSettingsStorage(_completeSettings),
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

    sessionState.signedOut();
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
  });
}
