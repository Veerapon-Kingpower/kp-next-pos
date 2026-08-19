import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/app/session_state.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/startup/startup_validator.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_page.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';

import '../../../core/storage/fakes.dart';
import '../fake_auth_repository.dart';

void main() {
  SessionState buildSessionState() => SessionState(
    startupValidator: StartupValidator(
      deviceSettingsStorage: FakeDeviceSettingsStorage(),
      sessionStorage: FakeSessionStorage(),
    ),
  );

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
        home: LoginPage(viewModel: viewModel, sessionState: sessionState),
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
          home: LoginPage(viewModel: viewModel, sessionState: sessionState),
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
}
