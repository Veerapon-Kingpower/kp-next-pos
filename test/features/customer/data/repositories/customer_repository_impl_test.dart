import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/data/datasources/customer_remote_data_source.dart';
import 'package:kp_pos/features/customer/data/repositories/customer_repository_impl.dart';

import '../../../../core/network/fake_api_client.dart';
import '../../../../core/storage/fakes.dart';
import '../../../auth/fake_auth_repository.dart';

void main() {
  const deviceSettings = DeviceSettings(
    branch: '03',
    subBranchCode: 'CPX-DT',
    uuid: 'device-uuid-1',
    pickupCode: 'A1',
    saleEngineEndpoint: 'https://sale-engine',
    webServiceEndpoint: 'https://web-service',
    flightApi: 'https://flight',
  );

  final searchResponse = {
    'isCompleted': true,
    'Data': <Map<String, dynamic>>[],
    'Message': <dynamic>[],
  };

  CustomerRepositoryImpl buildRepo(
    FakeApiClient apiClient,
    DeviceSettings settings,
  ) {
    return CustomerRepositoryImpl(
      remote: CustomerRemoteDataSource(apiClient: apiClient),
      deviceSettingsStorage: FakeDeviceSettingsStorage(settings),
      restoreSession: RestoreSessionUseCase(
        FakeAuthRepository(
          currentSessionResult: const UserSession(
            sessionKey: 'S1',
            branchNo: '03',
            userCode: 'U001',
            userName: 'Test User',
            authorizedActions: [],
            machineNo: 'KPPOS05',
          ),
        ),
      ),
    );
  }

  test(
    'search uses webServiceEndpoint and device-settings context when isAirportMpos is false',
    () async {
      final apiClient = FakeApiClient(response: searchResponse);
      final repo = buildRepo(
        apiClient,
        deviceSettings.copyWith(isAirportMpos: false),
      );

      await repo.search(shoppingCard: 'CPX0001', isTour: false);

      expect(apiClient.lastUrl, 'https://web-service/Register/GetCustomer');
      expect(apiClient.lastData, {
        'branchNo': '03',
        'SubBranch': 'CPX-DT',
        'shoppingCard': 'CPX0001',
        'isTour': false,
        'pickupCode': 'A1',
        // The login's MachineEnv.MachineNo, not the device uuid.
        'machineNo': 'KPPOS05',
      });
    },
  );

  test('search uses saleEngineEndpoint when isAirportMpos is true', () async {
    final apiClient = FakeApiClient(response: searchResponse);
    final repo = buildRepo(
      apiClient,
      deviceSettings.copyWith(isAirportMpos: true),
    );

    await repo.search(shoppingCard: 'CPX0001', isTour: false);

    expect(apiClient.lastUrl, 'https://sale-engine/Register/GetCustomer');
  });

  test('agents resolves branchNo from device settings', () async {
    final apiClient = FakeApiClient(
      response: {
        'isCompleted': true,
        'Data': <Map<String, dynamic>>[],
        'Message': <dynamic>[],
      },
    );
    final repo = buildRepo(apiClient, deviceSettings);

    await repo.agents(input: 'AG', typeSearch: 'agent');

    expect(apiClient.lastData, {
      'branchNo': '03',
      'input': 'AG',
      'typeSearch': 'agent',
    });
  });

  test(
    'register resolves subBranchCode/branchNo from device settings, machineNo from the login session, and sends the MOBILE platform code',
    () async {
      final apiClient = FakeApiClient(
        response: {
          'isCompleted': true,
          'Data': [
            {'listOutput': [], 'listMessage': [], 'isComplete': true},
          ],
          'Message': <dynamic>[],
        },
      );
      final repo = buildRepo(apiClient, deviceSettings);

      await repo.register(
        agentCode: 'AG1',
        subAgentCode: '',
        prefixShoppingCard: 'CPX',
        userCode: 'U001',
        action: 'register',
        allowTakeAway: true,
        isAirport: true,
        tour: const {},
        listPersonal: const [],
      );

      final sent = apiClient.lastData as List<dynamic>;
      final body = sent.single as Map<String, dynamic>;
      expect(body['subBranchCode'], 'CPX-DT');
      expect(body['branchNo'], '03');
      expect(body['machineNo'], 'KPPOS05');
      expect(body['platformCode'], 'MOBILE');
    },
  );
}
