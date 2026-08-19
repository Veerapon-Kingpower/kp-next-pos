import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/login_usecase.dart';
import 'package:kp_pos/features/auth/presentation/login_view_model.dart';

import '../fake_auth_repository.dart';

void main() {
  test(
    'submit transitions idle -> submitting -> success and stores the session',
    () async {
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

      expect(viewModel.status, LoginStatus.idle);

      final future = viewModel.submit(userCode: 'U001', userPassword: 'pass');
      expect(viewModel.status, LoginStatus.submitting);

      await future;

      expect(viewModel.status, LoginStatus.success);
      expect(viewModel.session, session);
      expect(viewModel.errorMessage, isNull);
    },
  );

  test(
    'submit transitions to failure and surfaces the server message on ApiException',
    () async {
      final viewModel = LoginViewModel(
        loginUseCase: LoginUseCase(
          FakeAuthRepository(
            loginError: const ApiException(
              messageDesc: 'Invalid username or password.',
            ),
          ),
        ),
      );

      await viewModel.submit(userCode: 'bad', userPassword: 'bad');

      expect(viewModel.status, LoginStatus.failure);
      expect(viewModel.errorMessage, 'Invalid username or password.');
      expect(viewModel.session, isNull);
    },
  );

  test(
    'submit falls back to a generic message on an unexpected error',
    () async {
      final viewModel = LoginViewModel(
        loginUseCase: LoginUseCase(
          FakeAuthRepository(loginError: Exception('boom')),
        ),
      );

      await viewModel.submit(userCode: 'U001', userPassword: 'pass');

      expect(viewModel.status, LoginStatus.failure);
      expect(viewModel.errorMessage, isNotNull);
    },
  );
}
