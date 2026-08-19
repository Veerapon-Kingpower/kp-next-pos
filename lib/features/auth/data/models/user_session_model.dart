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
  });

  /// [json] is the `Data` object of a `ReturnObject<LoginResult>` response.
  factory UserSessionModel.fromLoginResultJson(Map<String, dynamic> json) {
    final userInfo = json['userInfo'] as Map<String, dynamic>? ?? const {};
    return UserSessionModel(
      sessionKey: json['session_key'] as String? ?? '',
      branchNo: userInfo['branch_no'] as String? ?? '',
      userCode: userInfo['user_code'] as String? ?? '',
      userName: userInfo['user_name'] as String? ?? '',
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
