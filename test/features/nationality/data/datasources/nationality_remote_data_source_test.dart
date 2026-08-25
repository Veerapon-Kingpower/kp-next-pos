import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/nationality/data/datasources/nationality_remote_data_source.dart';

import '../../../../core/network/fake_api_client.dart';

void main() {
  late FakeApiClient apiClient;
  late NationalityRemoteDataSource dataSource;

  setUp(() {
    apiClient = FakeApiClient();
    dataSource = NationalityRemoteDataSource(apiClient: apiClient);
  });

  test('search posts to Register/GetNationality and parses the list', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {'CountryCode': 'THA', 'CountryName': 'Thailand'},
      ],
      'Message': [],
    };

    final result = await dataSource.search(
      webServiceEndpoint: 'https://web-service',
      countryCode: 'tha',
      pageNo: 0,
      pageSize: 0,
    );

    expect(apiClient.lastUrl, 'https://web-service/Register/GetNationality');
    expect(apiClient.lastData, {
      'countryCode': 'tha',
      'pageNo': 0,
      'pageSize': 0,
    });
    expect(result, hasLength(1));
    expect(result.first.countryCode, 'THA');
    expect(result.first.countryName, 'Thailand');
  });

  test('search throws when the envelope is not completed', () async {
    apiClient.response = {
      'isCompleted': false,
      'Data': null,
      'Message': [
        {
          'MessageType': 'error',
          'MessageCode': 'E01',
          'MessageDesc': 'Nationality service not available.',
        },
      ],
    };

    expect(
      () => dataSource.search(
        webServiceEndpoint: 'https://web-service',
        countryCode: '',
        pageNo: 0,
        pageSize: 50,
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
