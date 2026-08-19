import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/repositories/auth_repository.dart';

/// Shared test double for [AuthRepository] — used wherever a test needs a
/// working login/logout flow without a real network call.
class FakeAuthRepository implements AuthRepository {
  final UserSession? loginResult;
  final Object? loginError;
  int logoutCallCount = 0;

  FakeAuthRepository({this.loginResult, this.loginError});

  @override
  Future<UserSession> login({
    required String userCode,
    required String userPassword,
  }) async {
    if (loginError != null) throw loginError!;
    return loginResult ??
        const UserSession(
          sessionKey: 'fake-session',
          branchNo: '03',
          userCode: 'U001',
          userName: 'Test User',
          authorizedActions: [],
        );
  }

  @override
  Future<void> logout() async {
    logoutCallCount++;
  }

  @override
  Future<UserSession?> currentSession() async => null;
}
