import 'package:flutter/foundation.dart';

import '../startup/startup_validator.dart';

/// App-wide auth/session status, drives the router's redirect guard (see
/// `router.dart`). Kept separate from [StartupValidator] itself so the
/// router can listen for changes (`ChangeNotifier`) after login/logout,
/// not just at cold start.
class SessionState extends ChangeNotifier {
  final StartupValidator _startupValidator;

  StartupStatus _status = StartupStatus.needsDeviceSetup;
  String? _sessionKey;

  SessionState({required StartupValidator startupValidator})
    : _startupValidator = startupValidator;

  StartupStatus get status => _status;
  String? get sessionKey => _sessionKey;

  Future<void> refresh() async {
    final result = await _startupValidator.validate();
    _status = result.status;
    _sessionKey = result.sessionKey;
    notifyListeners();
  }

  void signedIn(String sessionKey) {
    _sessionKey = sessionKey;
    _status = StartupStatus.ready;
    notifyListeners();
  }

  void signedOut() {
    _sessionKey = null;
    _status = StartupStatus.needsLogin;
    notifyListeners();
  }

  void deviceSetupCompleted() {
    _status = StartupStatus.needsLogin;
    notifyListeners();
  }
}
