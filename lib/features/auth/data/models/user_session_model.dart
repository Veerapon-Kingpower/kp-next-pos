import '../../domain/entities/authorized_action.dart';
import '../../domain/entities/user_session.dart';

/// Parses/serializes the legacy `LoginResult` shape (`api-contracts.md`
/// section 5a, op 1: `Data: {session_key, userInfo: {branch_no, user_code,
/// user_name, list_authorize: [...]}}`), and the flattened JSON this app
/// persists locally between launches.
class UserSessionModel extends UserSession {
  const UserSessionModel({
    required super.sessionKey,
    required super.branchNo,
    required super.userCode,
    required super.userName,
    required super.authorizedActions,
    super.machineNo,
    super.site,
    super.posType,
  });

  /// [json] is the `Data` object of a `ReturnObject<LoginResult>` response.
  factory UserSessionModel.fromLoginResultJson(Map<String, dynamic> json) {
    final userInfo = json['userInfo'] as Map<String, dynamic>? ?? const {};
    // Legacy `UserInfoModel.MachineEnv: EnvModel` (`AuthenModel.ts`).
    final machineEnv =
        userInfo['MachineEnv'] as Map<String, dynamic>? ?? const {};
    return UserSessionModel(
      sessionKey: json['session_key'] as String? ?? '',
      branchNo: userInfo['branch_no'] as String? ?? '',
      userCode: userInfo['user_code'] as String? ?? '',
      userName: userInfo['user_name'] as String? ?? '',
      machineNo: '${machineEnv['MachineNo'] ?? ''}',
      site: '${machineEnv['site'] ?? ''}',
      posType: int.tryParse('${machineEnv['posType'] ?? ''}') ?? 0,
      authorizedActions:
          (userInfo['list_authorize'] as List<dynamic>? ?? const [])
              .map(
                (a) => AuthorizedAction(
                  moduleCode: a['ModuleCode'] as String? ?? '',
                  authCode: a['AuthCode'] as String? ?? '',
                  action: a['Action'] as String? ?? '',
                ),
              )
              .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionKey': sessionKey,
    'branchNo': branchNo,
    'userCode': userCode,
    'userName': userName,
    'machineNo': machineNo,
    'site': site,
    'posType': posType,
    'authorizedActions': authorizedActions
        .map(
          (a) => {
            'moduleCode': a.moduleCode,
            'authCode': a.authCode,
            'action': a.action,
          },
        )
        .toList(growable: false),
  };

  factory UserSessionModel.fromJson(Map<String, dynamic> json) =>
      UserSessionModel(
        sessionKey: json['sessionKey'] as String? ?? '',
        branchNo: json['branchNo'] as String? ?? '',
        userCode: json['userCode'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        // Absent from sessions saved before it was stored — such a session
        // is incomplete and startup sends the user back to login.
        machineNo: json['machineNo'] as String? ?? '',
        site: json['site'] as String? ?? '',
        posType: (json['posType'] as num?)?.toInt() ?? 0,
        authorizedActions:
            (json['authorizedActions'] as List<dynamic>? ?? const [])
                .map(
                  (a) => AuthorizedAction(
                    moduleCode: a['moduleCode'] as String? ?? '',
                    authCode: a['authCode'] as String? ?? '',
                    action: a['action'] as String? ?? '',
                  ),
                )
                .toList(growable: false),
      );
}
