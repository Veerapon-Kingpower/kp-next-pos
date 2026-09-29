import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/sale/data/datasources/sale_remote_data_source.dart';

import '../../../../core/network/fake_api_client.dart';

void main() {
  late FakeApiClient apiClient;
  late SaleRemoteDataSource dataSource;

  setUp(() {
    apiClient = FakeApiClient();
    dataSource = SaleRemoteDataSource(apiClient: apiClient);
  });

  test(
    'getMasterByBarcode posts to SaleEngine/GetMasterByBarcodeDLL and parses the article',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': {
          'Article': {
            'ArticleCode': 'ART001',
            'ArticleName': 'Test Article',
            'EANCode': '8850012345678',
            'Brand': {'Code': 'B1', 'Name': 'Brand One'},
            'VatRate': 7,
            'Price': 100,
          },
        },
        'Message': [],
      };

      final result = await dataSource.getMasterByBarcode(
        saleEngineEndpoint: 'https://sale-engine',
        siteCode: 'CPX-DT',
        barcode: '8850012345678',
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/GetMasterByBarcodeDLL',
      );
      final sent = apiClient.lastData as Map<String, dynamic>;
      expect(sent['siteCode'], 'CPX-DT');
      expect(sent['barcode'], '8850012345678');
      expect(sent['priceDate'], isA<String>());
      expect(result.articleCode, 'ART001');
      expect(result.brandName, 'Brand One');
      expect(result.price, 100);
    },
  );

  test('getMasterByBarcode throws when the article is not found', () async {
    apiClient.response = {
      'isCompleted': false,
      'Data': null,
      'Message': [
        {
          'MessageType': 'error',
          'MessageCode': 'E01',
          'MessageDesc': 'Article not found',
        },
      ],
    };

    expect(
      () => dataSource.getMasterByBarcode(
        saleEngineEndpoint: 'https://sale-engine',
        siteCode: 'CPX-DT',
        barcode: 'unknown',
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test(
    'addItemToOrder posts to SaleEngine/AddItemToOrder with the item code, quantity, and session key',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };

      final result = await dataSource.addItemToOrder(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        articleCode: 'ART001',
        quantity: 5,
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/AddItemToOrder',
      );
      expect(apiClient.lastData, {
        'ItemCode': 'ART001',
        'ItemGWP': '',
        'SessionKey': 'abc123',
        'Rows': ['5'],
      });
      expect(result.guid, 'order-1');
    },
  );

  test(
    'updateItemQuantity posts to SaleEngine/ActionItemToOrder with a change_qty action',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };

      await dataSource.updateItemQuantity(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        row: '1',
        quantity: 2,
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/ActionItemToOrder',
      );
      expect(apiClient.lastData, {
        'ActionItemValues': [
          {'Action': 'change_qty', 'Value': '2'},
        ],
        'Row': '1',
        'SessionKey': 'abc123',
      });
    },
  );

  test(
    'removeItem posts to SaleEngine/ActionListItemToOrder with a delete action',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };

      await dataSource.removeItem(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        row: '1',
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/ActionListItemToOrder',
      );
      expect(apiClient.lastData, {
        'ActionItemValue': {'Action': 'delete', 'Value': ''},
        'Rows': ['1'],
        'SessionKey': 'abc123',
      });
    },
  );

  test(
    'getOrder posts to SaleEngine/GetOrder scoped by shoppingCard',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };

      await dataSource.getOrder(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        shoppingCard: 'CPX0001',
      );

      expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/GetOrder');
      expect(apiClient.lastData, {
        'SessionKey': 'abc123',
        'Attributes': [
          {
            'Group': 'BASKET',
            'Code': 'shoppingCard',
            'ValueOfString': 'CPX0001',
          },
        ],
      });
    },
  );

  test(
    'an order mutation throws when the envelope returns no orders',
    () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': <dynamic>[],
        'Message': [],
      };

      expect(
        () => dataSource.getOrder(
          saleEngineEndpoint: 'https://sale-engine',
          sessionKey: 'abc123',
          shoppingCard: 'CPX0001',
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );

  test('exchangeCurrency posts legacy ChangePage\'s ExchangeCurrencyParam '
      'and reads the AmountModel', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': {
        'CurrCode': {'Code': 'USD', 'Desc': 'US Dollar'},
        'CurrRate': 35.5,
        'CurrAmt': 20,
        'totalLocalChange': 710,
        'totalChange': 290,
      },
      'Message': [],
    };

    final quote = await dataSource.exchangeCurrency(
      saleEngineEndpoint: 'https://sale-engine',
      currencyCode: 'USD',
      currencyAmount: 20,
      baseAmount: 1000,
      isChangeButton: false,
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/ExchangeCurrency',
    );
    expect(apiClient.lastData, {
      'currCode': 'USD',
      'currAmount': 20.0,
      'basecurrAmount': 1000.0,
      'isPaid': false,
      'isChangeButton': false,
    });
    expect(quote.currencyCode, 'USD');
    expect(quote.rate, 35.5);
    expect(quote.currencyAmount, 20);
    expect(quote.currencyAmountInBaht, 710);
    expect(quote.localChange, 290);
  });

  test('getCurrencies posts branch_no to SaleEngine/GetCurrency', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {
          'branch_no': '03',
          'curr_code': 'USD',
          'curr_desc': 'US Dollar',
          'curr_rate': 35.5,
          'curr_short': r'$',
        },
      ],
      'Message': [],
    };

    final result = await dataSource.getCurrencies(
      saleEngineEndpoint: 'https://sale-engine',
      branchNo: '03',
    );

    expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/GetCurrency');
    expect(apiClient.lastData, {'branch_no': '03'});
    expect(result.single.code, 'USD');
    expect(result.single.rate, 35.5);
  });

  test('changeOrderCurrency sends change_currency with the shopping card '
      'as Row (legacy CurrencyPickerPage)', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {'Guid': 'g1', 'isCheckOut': false, 'OrderDetails': []},
      ],
      'Message': [],
    };

    final cart = await dataSource.changeOrderCurrency(
      saleEngineEndpoint: 'https://sale-engine',
      sessionKey: 'abc123',
      shoppingCard: 'CPX0001',
      currencyCode: 'USD',
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/ActionItemToOrder',
    );
    expect(apiClient.lastData, {
      'ActionItemValues': [
        {'Action': 'change_currency', 'Value': 'USD'},
      ],
      'Row': 'CPX0001',
      'SessionKey': 'abc123',
    });
    expect(cart.guid, 'g1');
  });
}
