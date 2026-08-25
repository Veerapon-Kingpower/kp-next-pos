import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/customer/data/datasources/customer_remote_data_source.dart';

import '../../../../core/network/fake_api_client.dart';

void main() {
  late FakeApiClient apiClient;
  late CustomerRemoteDataSource dataSource;

  setUp(() {
    apiClient = FakeApiClient();
    dataSource = CustomerRemoteDataSource(apiClient: apiClient);
  });

  test(
    'searchCustomer posts to Register/GetCustomer at the given base URL and parses the list',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'action': 'found',
            'isFound': true,
            'person': {
              'englishName': 'Jane Doe',
              'passportNo': 'P1234567',
              'nationality': 'THA',
              'listContact': [],
              'listPrivilege': [],
              'listWalletMember': [],
            },
            'tour': <String, dynamic>{},
            'agentCode': 'AG1',
            'isMember': true,
          },
        ],
        'Message': [],
      };

      final result = await dataSource.searchCustomer(
        baseUrl: 'https://web-service',
        branchNo: '03',
        subBranch: 'CPX-DT',
        shoppingCard: 'CPX0001',
        isTour: false,
        pickupCode: 'A1',
        machineNo: 'uuid-1',
      );

      expect(apiClient.lastUrl, 'https://web-service/Register/GetCustomer');
      expect(apiClient.lastData, {
        'branchNo': '03',
        'SubBranch': 'CPX-DT',
        'shoppingCard': 'CPX0001',
        'isTour': false,
        'pickupCode': 'A1',
        'machineNo': 'uuid-1',
      });
      expect(result, hasLength(1));
      expect(result.first.person.englishName, 'Jane Doe');
      expect(result.first.isMember, true);
    },
  );

  test('searchCustomer parses subAgentCode (Guide)', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {
          'action': 'found',
          'isFound': true,
          'person': {'englishName': 'Jane Doe'},
          'tour': <String, dynamic>{},
          'agentCode': 'AG1',
          'subAgentCode': 'GD1',
          'isMember': true,
        },
      ],
      'Message': [],
    };

    final result = await dataSource.searchCustomer(
      baseUrl: 'https://web-service',
      branchNo: '03',
      subBranch: 'CPX-DT',
      shoppingCard: 'CPX0001',
      isTour: false,
      pickupCode: 'A1',
      machineNo: 'uuid-1',
    );

    expect(result.first.subAgentCode, 'GD1');
  });

  test(
    'searchCustomer parses customer type and registration status',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'action': 'found',
            'isFound': true,
            'person': {
              'englishName': 'Jane Doe',
              'customerTypeCode': 'VIP',
              'customerTypeDetail': 'VIP Member',
              'isActivate': true,
            },
            'tour': <String, dynamic>{},
            'agentCode': '',
            'isMember': false,
          },
        ],
        'Message': [],
      };

      final result = await dataSource.searchCustomer(
        baseUrl: 'https://web-service',
        branchNo: '03',
        subBranch: 'CPX-DT',
        shoppingCard: 'CPX0001',
        isTour: false,
        pickupCode: 'A1',
        machineNo: 'uuid-1',
      );

      expect(result.first.person.customerTypeCode, 'VIP');
      expect(result.first.person.customerTypeDetail, 'VIP Member');
      expect(result.first.person.isActivate, true);
    },
  );

  test(
    'searchCustomer extracts the shopping card number from the SHOPCARD entry in listIdentity',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'action': 'found',
            'isFound': true,
            'person': {
              'englishName': 'Jane Doe',
              'listIdentity': [
                {'IdentityType': 'MID', 'IdentityValue': 'M001'},
                {'IdentityType': 'SHOPCARD', 'IdentityValue': 'CPX0001'},
              ],
            },
            'tour': <String, dynamic>{},
            'agentCode': '',
            'isMember': false,
          },
        ],
        'Message': [],
      };

      final result = await dataSource.searchCustomer(
        baseUrl: 'https://web-service',
        branchNo: '03',
        subBranch: 'CPX-DT',
        shoppingCard: 'CPX0001',
        isTour: false,
        pickupCode: 'A1',
        machineNo: 'uuid-1',
      );

      expect(result.first.person.shoppingCard, 'CPX0001');
    },
  );

  test('searchCustomer parses flight fields', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {
          'action': 'found',
          'isFound': true,
          'person': {
            'englishName': 'Jane Doe',
            'flightCode': 'TG101',
            'flightDate': '2026-08-18',
            'flightTime': '10:00',
            'flightRouteDetail': 'BKK - NRT',
            'flightpickup': 'Gate A1',
          },
          'tour': <String, dynamic>{},
          'agentCode': '',
          'isMember': false,
        },
      ],
      'Message': [],
    };

    final result = await dataSource.searchCustomer(
      baseUrl: 'https://web-service',
      branchNo: '03',
      subBranch: 'CPX-DT',
      shoppingCard: 'CPX0001',
      isTour: false,
      pickupCode: 'A1',
      machineNo: 'uuid-1',
    );

    expect(result.first.person.flightCode, 'TG101');
    expect(result.first.person.flightDate, '2026-08-18');
    expect(result.first.person.flightTime, '10:00');
    expect(result.first.person.flightRouteDetail, 'BKK - NRT');
    expect(result.first.person.flightPickup, 'Gate A1');
  });

  test(
    'register posts a bare array to Register/RegisterAPI and returns the first result',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'listOutput': [
              {
                'runningNo': '1',
                'shoppingCard': 'CPX0002',
                'qrShoppingCard': 'QR-CPX0002',
                'listCoupon': [],
              },
            ],
            'listMessage': [],
            'isComplete': true,
          },
        ],
        'Message': [],
      };

      final result = await dataSource.register(
        webServiceEndpoint: 'https://web-service',
        agentCode: 'AG1',
        subAgentCode: '',
        subBranchCode: 'CPX-DT',
        branchNo: '03',
        platformCode: 'MPOS',
        prefixShoppingCard: 'CPX',
        userCode: 'U001',
        machineNo: 'uuid-1',
        action: 'register',
        allowTakeAway: true,
        isAirport: true,
        tour: const {},
        listPersonal: const [],
      );

      expect(apiClient.lastUrl, 'https://web-service/Register/RegisterAPI');
      expect(apiClient.lastData, isA<List<dynamic>>());
      expect((apiClient.lastData as List<dynamic>), hasLength(1));
      expect(result.outputs.single.shoppingCard, 'CPX0002');
      expect(result.isComplete, true);
    },
  );

  test('register throws when the nested isComplete flag is false', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {'listOutput': [], 'listMessage': [], 'isComplete': false},
      ],
      'Message': [],
    };

    expect(
      () => dataSource.register(
        webServiceEndpoint: 'https://web-service',
        agentCode: 'AG1',
        subAgentCode: '',
        subBranchCode: 'CPX-DT',
        branchNo: '03',
        platformCode: 'MPOS',
        prefixShoppingCard: 'CPX',
        userCode: 'U001',
        machineNo: 'uuid-1',
        action: 'register',
        allowTakeAway: true,
        isAirport: true,
        tour: const {},
        listPersonal: const [],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'listAgents posts to SaleEngine/GetListAgent with the given typeSearch',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {
            'SubAgentCode': '',
            'SubAgentDesc': '',
            'AgentCode': 'AG1',
            'AgentDesc': 'Agent One',
            'CustomerType': '',
            'CustomerTypeDesc': '',
          },
        ],
        'Message': [],
      };

      final result = await dataSource.listAgents(
        saleEngineEndpoint: 'https://sale-engine',
        branchNo: '03',
        input: 'AG',
        typeSearch: 'agent',
      );

      expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/GetListAgent');
      expect(apiClient.lastData, {
        'branchNo': '03',
        'input': 'AG',
        'typeSearch': 'agent',
      });
      expect(result.single.agentCode, 'AG1');
    },
  );

  test(
    'getShippingAddress posts sessionID as a query parameter to Register/GetShippingBySessionID',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': '123 Main St, Bangkok',
        'Message': [],
      };

      final result = await dataSource.getShippingAddress(
        'session-1',
        webServiceEndpoint: 'https://web-service',
      );

      expect(
        apiClient.lastUrl,
        'https://web-service/Register/GetShippingBySessionID',
      );
      expect(apiClient.lastQueryParameters, {'sessionID': 'session-1'});
      expect(result, '123 Main St, Bangkok');
    },
  );

  test(
    'updateShippingAddress posts to SaleEngine/UpdateShippingAddress',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1'},
        ],
        'Message': [],
      };

      await dataSource.updateShippingAddress(
        saleEngineEndpoint: 'https://sale-engine',
        shipAddress: '123 Main St',
        sessionKey: 'abc123',
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/UpdateShippingAddress',
      );
      expect(apiClient.lastData, {
        'ShipAddress': '123 Main St',
        'SessionKey': 'abc123',
      });
    },
  );

  test(
    'updateShippingAddress throws when the envelope is not completed',
    () async {
      apiClient.response = {
        'isCompleted': false,
        'Data': null,
        'Message': [
          {
            'MessageType': 'error',
            'MessageCode': 'E01',
            'MessageDesc': 'Invalid address',
          },
        ],
      };

      expect(
        () => dataSource.updateShippingAddress(
          saleEngineEndpoint: 'https://sale-engine',
          shipAddress: '',
          sessionKey: 'abc123',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
