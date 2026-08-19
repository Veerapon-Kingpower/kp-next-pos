import 'package:kp_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:kp_pos/features/auth/data/models/user_session_model.dart';

class FakeAuthLocalDataSource implements AuthLocalDataSource {
  UserSessionModel? _session;
  int clearCallCount = 0;

  FakeAuthLocalDataSource([this._session]);

  @override
  Future<UserSessionModel?> read() async => _session;

  @override
  Future<void> save(UserSessionModel session) async => _session = session;

  @override
  Future<void> clear() async {
    _session = null;
    clearCallCount++;
  }
}
