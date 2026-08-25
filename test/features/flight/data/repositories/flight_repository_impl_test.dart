import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/features/flight/data/datasources/flight_remote_data_source.dart';
import 'package:kp_pos/features/flight/data/repositories/flight_repository_impl.dart';

import '../../../../core/network/fake_api_client.dart';
import '../../../../core/storage/fakes.dart';

void main() {
  const deviceSettings = DeviceSettings(
    subBranchCode: 'CPX-DT',
    flightApi: 'https://flight',
  );

  final emptyListResponse = {
    'isCompleted': true,
    'Data': <Map<String, dynamic>>[],
    'Message': <dynamic>[],
  };

  FlightRepositoryImpl buildRepo(
    FakeApiClient apiClient,
    DeviceSettings settings,
  ) {
    return FlightRepositoryImpl(
      remote: FlightRemoteDataSource(apiClient: apiClient),
      deviceSettingsStorage: FakeDeviceSettingsStorage(settings),
    );
  }

  test(
    'getFlightByCode resolves flightApi, subBranchCode, and isAirport from device settings',
    () async {
      final apiClient = FakeApiClient(response: emptyListResponse);
      final repo = buildRepo(
        apiClient,
        deviceSettings.copyWith(isAirportMpos: true),
      );

      await repo.getFlightByCode(flightCode: 'TG101', flightType: 'D');

      expect(apiClient.lastUrl, 'https://flight/flight/GetFlightByCode');
      expect(apiClient.lastData, {
        'flightCode': 'TG101',
        'subBranchCode': 'CPX-DT',
        'flightType': 'D',
        'isAirport': true,
        'pageNo': 0,
        'pageSize': 60,
      });
    },
  );

  test('getDateByFlight resolves the same device-settings context', () async {
    final apiClient = FakeApiClient(response: emptyListResponse);
    final repo = buildRepo(apiClient, deviceSettings);

    await repo.getDateByFlight(flightCode: 'TG101');

    expect(apiClient.lastUrl, 'https://flight/flight/getDateByFlight');
    expect(apiClient.lastData, {
      'flightCode': 'TG101',
      'subBranchCode': 'CPX-DT',
      'flightType': '',
      'isAirport': false,
      'pageNo': 0,
      'pageSize': 60,
    });
  });

  test('validateFlight resolves flightApi from device settings', () async {
    final apiClient = FakeApiClient(
      response: {
        'isCompleted': true,
        'Data': {
          'flightValidate': true,
          'pickupCode': 'A1',
          'pickupName': 'Counter A1',
          'puImageUrl': '',
        },
        'Message': <dynamic>[],
      },
    );
    final repo = buildRepo(apiClient, deviceSettings);

    final result = await repo.validateFlight(
      flightCode: 'TG101',
      flightDateTime: '2026-08-18T14:30:00',
    );

    expect(apiClient.lastUrl, 'https://flight/flight/ValidateFlight');
    expect(result.flightValidate, true);
  });
}
