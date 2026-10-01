import 'dart:async';

import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/repositories/auth_repository.dart';

/// Shared test double for [AuthRepository] — used wherever a test needs a
/// working login/logout flow without a real network call.
class FakeAuthRepository implements AuthRepository {
  final UserSession? loginResult;
  final Object? loginError;
  final UserSession? currentSessionResult;
  int logoutCallCount = 0;

  /// When set, logout waits for it — a slow sign-out still in flight.
  Completer<void>? logoutGate;

  FakeAuthRepository({
    this.loginResult,
    this.loginError,
    this.currentSessionResult,
    this.logoutGate,
  });

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
    await logoutGate?.future;
  }

  @override
  Future<UserSession?> currentSession() async => currentSessionResult;
}
