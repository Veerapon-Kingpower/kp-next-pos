import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_page.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../../../core/storage/fakes.dart';
import '../../settings/fake_settings_repository.dart';
import '../fake_auth_repository.dart';

void main() {
  SessionState buildSessionState() => SessionState(
    startupValidator: StartupValidator(
      deviceSettingsStorage: FakeDeviceSettingsStorage(),
      sessionStorage: FakeSessionStorage(),
    ),
  );

  SettingsViewModel Function() buildSettingsViewModelFactory() {
    final repo = FakeSettingsRepository();
    return () => SettingsViewModel(
      loadDeviceSettings: LoadDeviceSettingsUseCase(repo),
      saveDeviceSettings: SaveDeviceSettingsUseCase(repo),
      listSubBranches: ListSubBranchesUseCase(repo),
    );
  }

  testWidgets('successful sign-in updates SessionState to ready', (
    tester,
  ) async {
    const session = UserSession(
      sessionKey: 'abc123',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [],
    );
    final viewModel = LoginViewModel(
      loginUseCase: LoginUseCase(FakeAuthRepository(loginResult: session)),
    );
    final sessionState = buildSessionState();

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: viewModel,
          sessionState: sessionState,
          settingsViewModelFactory: buildSettingsViewModelFactory(),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'U001');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.ensureVisible(find.text('Sign in'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(sessionState.status, StartupStatus.ready);
    expect(sessionState.sessionKey, 'abc123');
  });

  testWidgets(
    'failed sign-in shows a retryable error with the server message',
    (tester) async {
      final viewModel = LoginViewModel(
        loginUseCase: LoginUseCase(
          FakeAuthRepository(
            loginError: const ApiException(
              messageDesc: 'Invalid username or password.',
            ),
          ),
        ),
      );
      final sessionState = buildSessionState();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            viewModel: viewModel,
            sessionState: sessionState,
            settingsViewModelFactory: buildSettingsViewModelFactory(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, 'bad');
      await tester.enterText(find.byType(TextField).last, 'bad');
      await tester.ensureVisible(find.text('Sign in'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid username or password.'), findsOneWidget);
      expect(sessionState.status, isNot(StartupStatus.ready));
    },
  );

  testWidgets(
    'tapping the settings icon opens device settings and back returns to login',
    (tester) async {
      final viewModel = LoginViewModel(
        loginUseCase: LoginUseCase(FakeAuthRepository()),
      );
      final sessionState = buildSessionState();

      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            viewModel: viewModel,
            sessionState: sessionState,
            settingsViewModelFactory: buildSettingsViewModelFactory(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Device settings'), findsOneWidget);
      expect(find.text('Sign in'), findsNothing);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets('saving settings opened from the login page returns to login '
      'automatically, without a manual back tap', (tester) async {
    final viewModel = LoginViewModel(
      loginUseCase: LoginUseCase(FakeAuthRepository()),
    );
    final sessionState = buildSessionState();

    final view = TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .views
        .first;
    view.physicalSize = const Size(800, 3200);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          viewModel: viewModel,
          sessionState: sessionState,
          settingsViewModelFactory: buildSettingsViewModelFactory(),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings));
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
    expect(find.text('Device settings'), findsNothing);
  });
}
