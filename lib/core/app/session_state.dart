import 'package:get/get.dart';

import '../startup/startup_validator.dart';

/// App-wide auth/session status, drives the router's redirect guard (see
/// `router.dart`). Kept separate from [StartupValidator] itself so the
/// router can listen for changes (`GetxController` genuinely implements
/// `Listenable`, so it works directly as go_router's `refreshListenable`)
/// after login/logout, not just at cold start.
class SessionState extends GetxController {
  final StartupValidator _startupValidator;

  StartupStatus _status = StartupStatus.needsDeviceSetup;
  String? _sessionKey;

  SessionState({required StartupValidator startupValidator})
    : _startupValidator = startupValidator;

  StartupStatus get status => _status;
  String? get sessionKey => _sessionKey;

  /// Named to avoid colliding with [GetxController]'s own internal
  /// `refresh()` (called by `update()` to notify listeners) — overriding
  /// that with this unrelated async validation method would recurse.
  Future<void> refreshSession() async {
    final result = await _startupValidator.validate();
    _status = result.status;
    _sessionKey = result.sessionKey;
    update();
  }

  void signedIn(String sessionKey) {
    _sessionKey = sessionKey;
    _status = StartupStatus.ready;
    update();
  }

  void signedOut() {
    _sessionKey = null;
    _status = StartupStatus.needsLogin;
    update();
  }

  void deviceSetupCompleted() {
    _status = StartupStatus.needsLogin;
    update();
  }
}
