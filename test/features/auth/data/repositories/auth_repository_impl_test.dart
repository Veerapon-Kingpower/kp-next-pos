import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/data/auth_session_validity.dart';
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
              'MachineEnv': {'MachineNo': 'KPPOS05', 'site': 'CPX'},
              'list_authorize': [],
            },
          },
          'Message': [],
        },
      );
      final local = FakeAuthLocalDataSource();
      final coreSession = FakeSessionStorage();
      final repo = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(apiClient: apiClient),
        local: local,
        coreSessionStorage: coreSession,
        deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
      );

      final session = await repo.login(userCode: 'U001', userPassword: 'pass');

      expect(session.sessionKey, 'abc123');
      expect(session.machineNo, 'KPPOS05');
      expect((await local.read())!.machineNo, 'KPPOS05');
      // `MachineEnv.site` — the serial lookup's siteCode.
      expect(session.site, 'CPX');
      expect(apiClient.lastData, {
        'user_code': 'U001',
        'user_password': 'pass',
        'branch_no': '03',
        'module_code': 'MposKpi',
        'machine_ip': '01afaa68-f583-9816-2868-591032116435',
      });
      expect(await local.read(), isNotNull);
      expect(await coreSession.readSessionKey(), 'abc123');
    },
  );

  test(
    'login sends the fixed machine UUID even when the device has no uuid set',
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
              'MachineEnv': {'MachineNo': 'KPPOS05'},
              'list_authorize': [],
            },
          },
          'Message': [],
        },
      );
      final repo = AuthRepositoryImpl(
        remote: AuthRemoteDataSource(apiClient: apiClient),
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

  test('login without MachineEnv.MachineNo fails and saves nothing', () async {
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
      remote: AuthRemoteDataSource(apiClient: apiClient),
      local: local,
      coreSessionStorage: coreSession,
      deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
    );

    await expectLater(
      repo.login(userCode: 'U001', userPassword: 'pass'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.messageDesc,
          'messageDesc',
          contains('machine number'),
        ),
      ),
    );
    expect(await local.read(), isNull);
    expect(await coreSession.readSessionKey(), isNull);
  });

  group('AuthSessionValidity', () {
    const complete = UserSessionModel(
      sessionKey: 'abc123',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [],
      machineNo: 'KPPOS05',
    );

    test('keeps a session that has its machine number', () async {
      final local = FakeAuthLocalDataSource(complete);
      final coreSession = FakeSessionStorage('abc123');
      final validity = AuthSessionValidity(
        local: local,
        coreSessionStorage: coreSession,
      );

      expect(await validity.isSessionComplete(), isTrue);
      expect(await coreSession.readSessionKey(), 'abc123');
    });

    test(
      'clears a session saved without a machine number, forcing login',
      () async {
        final local = FakeAuthLocalDataSource(
          UserSessionModel.fromJson({
            'sessionKey': 'abc123',
            'branchNo': '03',
            'userCode': 'U001',
            'userName': 'Test User',
            'authorizedActions': [],
          }),
        );
        final coreSession = FakeSessionStorage('abc123');
        final validity = AuthSessionValidity(
          local: local,
          coreSessionStorage: coreSession,
        );

        expect(await validity.isSessionComplete(), isFalse);
        expect(await local.read(), isNull);
        expect(await coreSession.readSessionKey(), isNull);
      },
    );

    test('the machine number survives the persisted round trip', () {
      final restored = UserSessionModel.fromJson(
        const UserSessionModel(
          sessionKey: 'abc123',
          branchNo: '03',
          userCode: 'U001',
          userName: 'Test User',
          authorizedActions: [],
          machineNo: 'KPPOS05',
          site: 'CPX',
        ).toJson(),
      );
      expect(restored.site, 'CPX');
      expect(restored.machineNo, 'KPPOS05');
      expect(restored.isComplete, isTrue);
    });
  });

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
        remote: AuthRemoteDataSource(apiClient: apiClient),
        local: local,
        coreSessionStorage: coreSession,
        deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
      );

      await repo.logout();

      expect(await local.read(), isNull);
      expect(await coreSession.readSessionKey(), isNull);
    },
  );

  testWidgets(
    'a SignOut stuck on a dead connection gives up after the timeout and '
    'still clears the local session',
    (tester) async {
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
        remote: AuthRemoteDataSource(apiClient: FakeApiClient(hang: true)),
        local: local,
        coreSessionStorage: coreSession,
        deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
      );

      var done = false;
      unawaited(repo.logout().then((_) => done = true));
      await tester.pump(const Duration(seconds: 5));
      expect(done, isFalse, reason: 'still waiting on SignOut');

      await tester.pump(logoutSignOutTimeout);
      expect(done, isTrue);
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
      remote: AuthRemoteDataSource(apiClient: FakeApiClient()),
      local: FakeAuthLocalDataSource(session),
      coreSessionStorage: FakeSessionStorage(),
      deviceSettingsStorage: FakeDeviceSettingsStorage(deviceSettings),
    );

    expect(await repo.currentSession(), session);
  });
}
