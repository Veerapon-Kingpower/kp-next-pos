import 'authorized_action.dart';

/// The authenticated store/user context, restored on every app launch.
/// Field-for-field port of the legacy `LoginResult.userInfo`
/// (`api-contracts.md` section 5a, op 1).
class UserSession {
  final String sessionKey;
  final String branchNo;
  final String userCode;
  final String userName;
  final List<AuthorizedAction> authorizedActions;

  const UserSession({
    required this.sessionKey,
    required this.branchNo,
    required this.userCode,
    required this.userName,
    required this.authorizedActions,
  });

  /// Port of `ShareDataProvider.canDoIt` — whether this session is
  /// authorized for [action] within [moduleCode].
  bool canDoIt(String moduleCode, String action) {
    return authorizedActions.any(
      (a) => a.moduleCode == moduleCode && a.action == action,
    );
  }
}
