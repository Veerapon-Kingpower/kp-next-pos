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

  /// `userInfo.MachineEnv.MachineNo` — the POS machine number the server
  /// assigns at login. Legacy sends it as `machineNo` on Register/GetCustomer
  /// and RegisterAPI (and elsewhere), so a session without one is not
  /// usable: see [isComplete].
  final String machineNo;

  /// `userInfo.MachineEnv.site` — legacy's `siteCode` for
  /// `GetMasterByBarcodeDLL`. Empty for a session saved before it was
  /// stored.
  final String site;

  /// `userInfo.MachineEnv.posType` — legacy `PosTypeEnum`: 1 Sale (can't
  /// take payment), 2 Cashier. 0 when unknown (a session saved before it
  /// was stored).
  final int posType;

  /// Legacy `PosTypeEnum.Sale`.
  static const posTypeSale = 1;

  const UserSession({
    required this.sessionKey,
    required this.branchNo,
    required this.userCode,
    required this.userName,
    required this.authorizedActions,
    this.machineNo = '',
    this.site = '',
    this.posType = 0,
  });

  /// Whether this session carries everything later calls need. A session
  /// persisted before [machineNo] was stored isn't — the app sends the
  /// user back to login to get a fresh one.
  bool get isComplete => sessionKey.isNotEmpty && machineNo.isNotEmpty;

  /// Port of `ShareDataProvider.canDoIt` — whether this session is
  /// authorized for [action] within [moduleCode].
  bool canDoIt(String moduleCode, String action) {
    return authorizedActions.any(
      (a) => a.moduleCode == moduleCode && a.action == action,
    );
  }

  /// Port of `ShareDataProvider.canDoIt(AuthorizeCode.X)` as the Sale page
  /// calls it: matches `list_authorize[].AuthCode` alone (e.g.
  /// `actCurrency`).
  bool hasAuthCode(String authCode) =>
      authorizedActions.any((a) => a.authCode == authCode);
}
