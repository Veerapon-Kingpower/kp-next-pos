import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/user_session_model.dart';

/// Sale Engine `Authen`/`SaleEngine` calls (`api-contracts.md` section 5a,
/// ops 1 and 5).
class AuthRemoteDataSource {
  final ApiClient _apiClient;
  final String _saleEngineEndpoint;

  const AuthRemoteDataSource({
    required ApiClient apiClient,
    required String saleEngineEndpoint,
  }) : _apiClient = apiClient,
       _saleEngineEndpoint = saleEngineEndpoint;

  Future<UserSessionModel> login({
    required String userCode,
    required String userPassword,
    required String branchNo,
    required String moduleCode,
    required String machineIp,
  }) async {
    final response = await _apiClient.post(
      '$_saleEngineEndpoint/Authen/LoginAuthen',
      data: {
        'user_code': userCode,
        'user_password': userPassword,
        'branch_no': branchNo,
        'module_code': moduleCode,
        'machine_ip': machineIp,
      },
    );

    final result = ReturnObject<UserSessionModel>.fromJson(
      response,
      (data) =>
          UserSessionModel.fromLoginResultJson(data as Map<String, dynamic>),
    );

    final session = result.unwrap();
    if (session.sessionKey.isEmpty) {
      // Login page's own success check in the legacy client is
      // `session_key != ""`, not the envelope's `isCompleted` — invalid
      // credentials return a completed envelope with an empty session_key.
      throw const ApiException(messageDesc: 'Invalid username or password.');
    }
    return session;
  }

  Future<void> logout(String sessionKey) async {
    await _apiClient.post(
      '$_saleEngineEndpoint/SaleEngine/SignOut',
      data: {'SessionKey': sessionKey},
    );
  }
}
