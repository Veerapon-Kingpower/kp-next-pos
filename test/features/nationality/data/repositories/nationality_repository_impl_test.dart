import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/config/device_settings.dart';
import 'package:kp_pos/features/nationality/data/datasources/nationality_remote_data_source.dart';
import 'package:kp_pos/features/nationality/data/repositories/nationality_repository_impl.dart';

import '../../../../core/network/fake_api_client.dart';
import '../../../../core/storage/fakes.dart';

void main() {
  const deviceSettings = DeviceSettings(
    webServiceEndpoint: 'https://web-service',
  );

  NationalityRepositoryImpl buildRepo(
    FakeApiClient apiClient,
    DeviceSettings settings,
  ) {
    return NationalityRepositoryImpl(
      remote: NationalityRemoteDataSource(apiClient: apiClient),
      deviceSettingsStorage: FakeDeviceSettingsStorage(settings),
    );
  }

  test('search resolves webServiceEndpoint from device settings', () async {
    final apiClient = FakeApiClient(
      response: {
        'isCompleted': true,
        'Data': <Map<String, dynamic>>[],
        'Message': <dynamic>[],
      },
    );
    final repo = buildRepo(apiClient, deviceSettings);

    await repo.search(countryCode: 'tha');

    expect(apiClient.lastUrl, 'https://web-service/Register/GetNationality');
    expect(apiClient.lastData, {
      'countryCode': 'tha',
      'pageNo': 0,
      'pageSize': 50,
    });
  });
}
