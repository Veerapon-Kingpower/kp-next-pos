import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/presentation/test_ids.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/core/theme/app_colors.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_page.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';
import 'package:kp_pos/features/settings/domain/usecases/list_sub_branches_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/load_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/domain/usecases/save_device_settings_usecase.dart';
import 'package:kp_pos/features/settings/presentation/settings_view_model.dart';

import '../../../core/storage/fakes.dart';
import '../../../helpers/test_id_finders.dart';
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

  group('handheld sign-in (below desktop width)', () {
    LoginPage buildPage({FakeAuthRepository? repository}) => LoginPage(
      viewModel: LoginViewModel(
        loginUseCase: LoginUseCase(repository ?? FakeAuthRepository()),
      ),
      sessionState: buildSessionState(),
      settingsViewModelFactory: buildSettingsViewModelFactory(),
    );

    testWidgets('renders the dark handheld form with automation ids', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(MaterialApp(home: buildPage()));

      expect(find.text('SMART POS MOBILE'), findsOneWidget);
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      for (final id in [
        LoginIds.userCodeField,
        LoginIds.passwordField,
        LoginIds.passwordVisibility,
        LoginIds.signInButton,
        LoginIds.qrLoginButton,
        LoginIds.settingsButton,
      ]) {
        expect(find.bySemanticsIdentifier(id), findsOneWidget, reason: id);
      }
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.ink);
      handle.dispose();
    });

    testWidgets('Show / Hide toggles password visibility', (tester) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(MaterialApp(home: buildPage()));

      EditableText password() => tester.widget<EditableText>(
        find.descendant(
          of: byTestId(LoginIds.passwordField),
          matching: find.byType(EditableText),
        ),
      );

      expect(password().obscureText, isTrue);
      await tester.tap(byTestId(LoginIds.passwordVisibility));
      await tester.pump();
      expect(password().obscureText, isFalse);
      expect(find.text('Hide'), findsOneWidget);
    });

    testWidgets('pressing Done on the password field signs in', (tester) async {
      setDeviceSize(tester, compactSize);
      const session = UserSession(
        sessionKey: 'k1',
        branchNo: '03',
        userCode: 'U001',
        userName: 'Test User',
        authorizedActions: [],
      );
      final sessionState = buildSessionState();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            viewModel: LoginViewModel(
              loginUseCase: LoginUseCase(
                FakeAuthRepository(loginResult: session),
              ),
            ),
            sessionState: sessionState,
            settingsViewModelFactory: buildSettingsViewModelFactory(),
          ),
        ),
      );

      await tester.enterText(
        find.descendant(
          of: byTestId(LoginIds.userCodeField),
          matching: find.byType(TextField),
        ),
        'U001',
      );
      await tester.enterText(
        find.descendant(
          of: byTestId(LoginIds.passwordField),
          matching: find.byType(TextField),
        ),
        'pw',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(sessionState.status, StartupStatus.ready);
    });

    testWidgets('a failed sign-in shows the error and keeps Sign in usable', (
      tester,
    ) async {
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(
        MaterialApp(
          home: buildPage(
            repository: FakeAuthRepository(
              loginError: const ApiException(
                messageCode: '401',
                messageDesc: 'Invalid username or password.',
              ),
            ),
          ),
        ),
      );
      await tester.tap(byTestId(LoginIds.signInButton));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: byTestId(LoginIds.errorMessage),
          matching: find.text('Invalid username or password.'),
        ),
        findsOneWidget,
      );
      expect(byTestId(LoginIds.signInButton), findsOneWidget);
    });

    testWidgets('QR login is shown but inert until a staff-QR API exists', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      setDeviceSize(tester, compactSize);
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      expect(
        tester.getSemantics(byTestId(LoginIds.qrLoginButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      handle.dispose();
    });

    testWidgets('iPad portrait: the form is centred and capped in width', (
      tester,
    ) async {
      setDeviceSize(tester, mediumSize);
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      final rect = tester.getRect(byTestId(LoginIds.signInButton));
      expect(rect.width, lessThanOrEqualTo(440));
      expect(rect.center.dx, closeTo(410, 0.5));
    });

    testWidgets('desktop width shows the station sign-in with identity panel', (
      tester,
    ) async {
      setDeviceSize(tester, expandedSize);
      await tester.pumpWidget(MaterialApp(home: buildPage()));
      await tester.pumpAndSettle();
      expect(byTestId(DesktopIds.loginIdentityPanel), findsOneWidget);
      expect(find.text('SMART POS MOBILE'), findsNothing);
    });

    testWidgets('desktop sign-in submits through the same view-model', (
      tester,
    ) async {
      setDeviceSize(tester, expandedSize);
      const session = UserSession(
        sessionKey: 'k2',
        branchNo: '03',
        userCode: 'U001',
        userName: 'Test User',
        authorizedActions: [],
      );
      final sessionState = buildSessionState();
      await tester.pumpWidget(
        MaterialApp(
          home: LoginPage(
            viewModel: LoginViewModel(
              loginUseCase: LoginUseCase(
                FakeAuthRepository(loginResult: session),
              ),
            ),
            sessionState: sessionState,
            settingsViewModelFactory: buildSettingsViewModelFactory(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(byTestId(LoginIds.signInButton));
      await tester.pumpAndSettle();
      expect(sessionState.status, StartupStatus.ready);
    });
  });
}
