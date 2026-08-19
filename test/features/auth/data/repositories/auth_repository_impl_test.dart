import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:kp_pos/features/auth/data/models/user_session_model.dart';
import 'package:kp_pos/features/auth/data/repositories/auth_repository_impl.dart';

import '../../../../core/network/fake_api_client.dart';
import '../../../../core/storage/fakes.dart';
import '../../fake_auth_local_data_source.dart';

void main() {
  const deviceSettings = DeviceSettings(
    branch: '03',
    moduleKey: 'MposKpi',
    uuid: 'device-uuid-1',
    saleEngineEndpoint: 'https://sale-engine',
    webServiceEndpoint: 'https://register',
    flightApi: 'https://flight',
  );

  test(
    'login sends device settings as branch/module/machine, persists locally, and saves the core session key',
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
      final local = FakeAuthLocalDataSource();
      final coreSession = FakeSessionStorage();
      final repo = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(
          apiClient: apiClient,
          saleEngineEndpoint: deviceSettings.saleEngineEndpoint,
        ),
        local: local,
        coreSessionStorage: coreSession,
        deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
      );

      final session = await repo.login(userCode: 'U001', userPassword: 'pass');

      expect(session.sessionKey, 'abc123');
      expect(apiClient.lastData, {
        'user_code': 'U001',
        'user_password': 'pass',
        'branch_no': '03',
        'module_code': 'MposKpi',
        'machine_ip': 'device-uuid-1',
      });
      expect(await local.read(), isNotNull);
      expect(await coreSession.readSessionKey(), 'abc123');
    },
  );

  test(
    'login falls back to the legacy hardcoded UUID when the device has no uuid set',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': {
            'session_key': 'abc123',
            'userInfo': {
              'branch_no': '03',
              'user_code': 'U001',
              'user_name': '',
              'list_authorize': [],
            },
          },
          'Message': [],
        },
      );
      final repo = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(
          apiClient: apiClient,
          saleEngineEndpoint: deviceSettings.saleEngineEndpoint,
        ),
        local: FakeAuthLocalDataSource(),
        coreSessionStorage: FakeSessionStorage(),
        deviceSettingsStorage: FakeDeviceSettingsStorage(
          deviceSettings.copyWith(uuid: ''),
        ),
      );

      await repo.login(userCode: 'U001', userPassword: 'pass');

      expect(
        (apiClient.lastData as Map)['machine_ip'],
        '01afaa68-f583-9816-2868-591032116435',
      );
    },
  );

  test(
    'logout clears the local session and core session key even if the server call fails',
    () async {
      final apiClient = FakeApiClient(errorToThrow: Exception('network down'));
      final local = FakeAuthLocalDataSource(
        const UserSessionModel(
          sessionKey: 'abc123',
          branchNo: '03',
          userCode: 'U001',
          userName: 'Test User',
          authorizedActions: [],
        ),
      );
      final coreSession = FakeSessionStorage('abc123');
      final repo = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(
          apiClient: apiClient,
          saleEngineEndpoint: deviceSettings.saleEngineEndpoint,
        ),
        local: local,
        coreSessionStorage: coreSession,
        deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
      );

      await repo.logout();

      expect(await local.read(), isNull);
      expect(await coreSession.readSessionKey(), isNull);
    },
  );

  test('currentSession reads the persisted local session', () async {
    final session = const UserSessionModel(
      sessionKey: 'abc123',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [],
    );
    final repo = AuthRepositoryImpl(
      remote: AuthRemoteDataSource(
        apiClient: FakeApiClient(),
        saleEngineEndpoint: deviceSettings.saleEngineEndpoint,
      ),
      local: FakeAuthLocalDataSource(session),
      coreSessionStorage: FakeSessionStorage(),
      deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
    );

    expect(await repo.currentSession(), session);
  });
}
