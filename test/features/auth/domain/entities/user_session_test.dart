import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';

void main() {
  test('canDoIt matches an authorized module+action pair', () {
    const session = UserSession(
      sessionKey: 'abc',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [
        AuthorizedAction(
          moduleCode: 'MposKpi',
          authCode: 'A1',
          action: 'void_payment',
        ),
      ],
    );

    expect(session.canDoIt('MposKpi', 'void_payment'), isTrue);
    expect(session.canDoIt('MposKpi', 'refund'), isFalse);
    expect(session.canDoIt('OtherModule', 'void_payment'), isFalse);
  });
}
