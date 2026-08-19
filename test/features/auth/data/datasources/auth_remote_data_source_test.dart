import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/data/datasources/auth_remote_data_source.dart';

import '../../../../core/network/fake_api_client.dart';

void main() {
  test(
    'login posts to Authen/LoginAuthen and parses the session on success',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': {
            'session_key': 'abc123',
            'userInfo': {
              'branch_no': '03',
              'user_code': 'U001',
              'user_name': 'Test User',
              'list_authorize': [],
            },
          },
          'Message': [],
        },
      );
      final dataSource = AuthRemoteDataSource(
        apiClient: apiClient,
        saleEngineEndpoint: 'https://sale-engine',
      );

      final session = await dataSource.login(
        userCode: 'U001',
        userPassword: 'pass',
        branchNo: '03',
        moduleCode: 'MposKpi',
        machineIp: 'uuid-1',
      );

      expect(apiClient.lastUrl, 'https://sale-engine/Authen/LoginAuthen');
      expect(apiClient.lastData, {
        'user_code': 'U001',
        'user_password': 'pass',
        'branch_no': '03',
        'module_code': 'MposKpi',
        'machine_ip': 'uuid-1',
      });
      expect(session.sessionKey, 'abc123');
    },
  );

  test(
    'login throws ApiException when the server returns an empty session_key (invalid credentials)',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': {
            'session_key': '',
            'userInfo': {
              'branch_no': '',
              'user_code': '',
              'user_name': '',
              'list_authorize': [],
            },
          },
          'Message': [],
        },
      );
      final dataSource = AuthRemoteDataSource(
        apiClient: apiClient,
        saleEngineEndpoint: 'https://sale-engine',
      );

      expect(
        () => dataSource.login(
          userCode: 'bad',
          userPassword: 'bad',
          branchNo: '03',
          moduleCode: 'MposKpi',
          machineIp: 'uuid',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('logout posts SessionKey to SaleEngine/SignOut', () async {
    final apiClient = FakeApiClient(
      response: {'isCompleted': true, 'Data': true, 'Message': []},
    );
    final dataSource = AuthRemoteDataSource(
      apiClient: apiClient,
      saleEngineEndpoint: 'https://sale-engine',
    );

    await dataSource.logout('abc123');

    expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/SignOut');
    expect(apiClient.lastData, {'SessionKey': 'abc123'});
  });
}
