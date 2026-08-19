import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/auth/data/models/user_session_model.dart';

void main() {
  test('fromLoginResultJson parses the legacy LoginResult.Data shape', () {
    final json = {
      'session_key': 'abc123',
      'userInfo': {
        'branch_no': '03',
        'user_code': 'U001',
        'user_name': 'Test User',
        'list_authorize': [
          {'ModuleCode': 'MposKpi', 'AuthCode': 'A1', 'Action': 'void_payment'},
        ],
      },
    };

    final session = UserSessionModel.fromLoginResultJson(json);

    expect(session.sessionKey, 'abc123');
    expect(session.branchNo, '03');
    expect(session.userCode, 'U001');
    expect(session.userName, 'Test User');
    expect(session.authorizedActions, hasLength(1));
    expect(session.authorizedActions.single.moduleCode, 'MposKpi');
  });

  test('round-trips through the local persistence JSON shape', () {
    final original = UserSessionModel.fromLoginResultJson({
      'session_key': 'abc123',
      'userInfo': {
        'branch_no': '03',
        'user_code': 'U001',
        'user_name': 'Test User',
        'list_authorize': [
          {'ModuleCode': 'MposKpi', 'AuthCode': 'A1', 'Action': 'void_payment'},
        ],
      },
    });

    final restored = UserSessionModel.fromJson(original.toJson());

    expect(restored.sessionKey, original.sessionKey);
    expect(restored.branchNo, original.branchNo);
    expect(restored.userCode, original.userCode);
    expect(restored.userName, original.userName);
    expect(restored.authorizedActions.single.moduleCode, 'MposKpi');
    expect(restored.authorizedActions.single.action, 'void_payment');
  });
}
