import '../entities/user_session.dart';

abstract class AuthRepository {
  /// Ports `AuthServiceProvider.login` (`Authen/LoginAuthen`) plus the
  /// device-context fields the legacy app pulls from `SettingsProvider`
  /// before calling it. Throws [ApiException] on failure.
  Future<UserSession> login({
    required String userCode,
    required String userPassword,
  });

  /// Ports `AuthServiceProvider.logout` (`SaleEngine/SignOut`) and clears
  /// the persisted session either way, since the legacy app does not block
  /// local logout on the server call succeeding.
  Future<void> logout();

  /// Restores the session persisted from a previous login, or null if none
  /// exists — ports `AuthServiceProvider.hasLoggedIn`/`getLoggedinData`.
  Future<UserSession?> currentSession();
}
