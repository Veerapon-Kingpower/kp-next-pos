import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/flight/data/datasources/flight_remote_data_source.dart';

import '../../../../core/network/fake_api_client.dart';

void main() {
  late FakeApiClient apiClient;
  late FlightRemoteDataSource dataSource;

  setUp(() {
    apiClient = FakeApiClient();
    dataSource = FlightRemoteDataSource(apiClient: apiClient);
  });

  test(
    'getFlightByCode posts to flight/GetFlightByCode and parses the list',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'flightCode': 'TG101',
            'flightDescription': 'Bangkok - Tokyo',
            'ArrDepAirportName': 'Suvarnabhumi',
            'DestAirportName': 'Narita',
            'flightType': 'D',
            'airlineCode': 'TG',
            'flightNo': '101',
            'flightDate': '2026-08-18',
          },
        ],
        'Message': [],
      };

      final result = await dataSource.getFlightByCode(
        flightApi: 'https://flight',
        flightCode: 'TG101',
        subBranchCode: 'CPX-DT',
        flightType: 'D',
        isAirport: true,
        pageNo: 0,
        pageSize: 60,
      );

      expect(apiClient.lastUrl, 'https://flight/flight/GetFlightByCode');
      expect(apiClient.lastData, {
        'flightCode': 'TG101',
        'subBranchCode': 'CPX-DT',
        'flightType': 'D',
        'isAirport': true,
        'pageNo': 0,
        'pageSize': 60,
      });
      expect(result, hasLength(1));
      expect(result.first.flightCode, 'TG101');
      expect(result.first.arrDepAirportName, 'Suvarnabhumi');
    },
  );

  test(
    'getDateByFlight posts to flight/getDateByFlight (lower-case g)',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': <Map<String, dynamic>>[],
        'Message': [],
      };

      await dataSource.getDateByFlight(
        flightApi: 'https://flight',
        flightCode: 'TG101',
        subBranchCode: 'CPX-DT',
        flightType: '',
        isAirport: false,
        pageNo: 0,
        pageSize: 60,
      );

      expect(apiClient.lastUrl, 'https://flight/flight/getDateByFlight');
    },
  );

  test('validateFlight posts to flight/ValidateFlight', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': {
        'flightValidate': true,
        'pickupCode': 'A1',
        'pickupName': 'Counter A1',
        'puImageUrl': 'https://example.com/a1.png',
      },
      'Message': [],
    };

    final result = await dataSource.validateFlight(
      flightApi: 'https://flight',
      flightCode: 'TG101',
      flightDateTime: '2026-08-18T14:30:00',
    );

    expect(apiClient.lastUrl, 'https://flight/flight/ValidateFlight');
    expect(apiClient.lastData, {
      'flightCode': 'TG101',
      'flightDateTime': '2026-08-18T14:30:00',
    });
    expect(result.flightValidate, true);
    expect(result.pickupCode, 'A1');
  });

  test('getFlightByCode throws when the envelope is not completed', () async {
    apiClient.response = {
      'isCompleted': false,
      'Data': null,
      'Message': [
        {
          'MessageType': 'error',
          'MessageCode': 'E01',
          'MessageDesc': 'Flight service not available.',
        },
      ],
    };

    expect(
      () => dataSource.getFlightByCode(
        flightApi: 'https://flight',
        flightCode: 'TG101',
        subBranchCode: 'CPX-DT',
        flightType: '',
        isAirport: false,
        pageNo: 0,
        pageSize: 60,
      ),
      throwsA(isA<ApiException>()),
    );
  });
}
