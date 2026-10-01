import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/sale/data/datasources/sale_remote_data_source.dart';
import 'package:kp_pos/features/sale/domain/entities/order_status.dart';
import 'package:kp_pos/features/sale/domain/entities/sale_order_context.dart';

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
    'addItemToOrder posts the scanned text as ItemCode and the selected lines as Rows, as legacy onSubmit does',
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
        itemCode: '5*8850012345678',
        rows: ['line-guid-1'],
      );

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/AddItemToOrder',
      );
      expect(apiClient.lastData, {
        'SessionKey': 'abc123',
        'ItemCode': '5*8850012345678',
        'Rows': ['line-guid-1'],
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

  test('getSerialByBarcode returns Article.SerialNo', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': {
        'Article': {'SerialNo': 'SN-REAL-1'},
      },
      'Message': [],
    };

    final serial = await dataSource.getSerialByBarcode(
      saleEngineEndpoint: 'https://sale-engine',
      siteCode: 'CPX',
      barcode: '012345678901234567890123',
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/GetMasterByBarcodeDLL',
    );
    final sent = apiClient.lastData as Map<String, dynamic>;
    expect(sent['siteCode'], 'CPX');
    expect(sent['barcode'], '012345678901234567890123');
    expect(serial, 'SN-REAL-1');
  });

  group('editItem (legacy EditSalePage.saveItem)', () {
    Future<({dynamic order, String? warning})> edit() async {
      final r = await dataSource.editItem(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        row: '1',
        quantity: 3,
        isFreeze: true,
        isLockDiscount: false,
        collectStatus: 'C',
        serialNo: 'SN1',
      );
      return (order: r.order, warning: r.warning);
    }

    test('sends all five actions in one ActionItemToOrder', () async {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };

      final result = await edit();

      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/ActionItemToOrder',
      );
      expect(apiClient.lastData, {
        'SessionKey': 'abc123',
        'Row': '1',
        'ActionItemValues': [
          {'Action': 'change_qty', 'Value': '3'},
          {'Action': 'is_freeze', 'Value': '1'},
          {'Action': 'is_lock', 'Value': '0'},
          {'Action': 'take_collect', 'Value': 'C'},
          {'Action': 'SerialNo', 'Value': 'SN1'},
        ],
      });
      expect(result.warning, isNull);
    });

    test('a WARNING still returns the order with the warning', () async {
      apiClient.response = {
        'isCompleted': false,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [
          {
            'MessageType': 'WARNING',
            'MessageCode': 'W1',
            'MessageDesc': 'Stock is low.',
          },
        ],
      };

      final result = await edit();

      expect(result.warning, 'Stock is low.');
      expect(result.order.guid, 'order-1');
    });

    test('any other failure throws the server message', () async {
      apiClient.response = {
        'isCompleted': false,
        'Data': null,
        'Message': [
          {
            'MessageType': 'ERROR',
            'MessageCode': 'E1',
            'MessageDesc': 'Not allowed.',
          },
        ],
      };

      await expectLater(
        edit(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.messageCode, 'messageCode', 'E1')
              .having((e) => e.messageDesc, 'messageDesc', 'Not allowed.'),
        ),
      );
    });
  });

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
    'getOrder sends only tran_no / shopping_card for a non-member, as legacy',
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
        context: const SaleOrderContext(shoppingCard: 'CPX0001'),
      );

      expect(apiClient.lastUrl, 'https://sale-engine/SaleEngine/GetOrder');
      expect(apiClient.lastData, {
        'SessionKey': 'abc123',
        'Attributes': [
          {
            'Group': 'tran_no',
            'Code': 'shopping_card',
            'ValueOfString': 'CPX0001',
          },
        ],
      });
    },
  );

  test(
    'getOrder adds the member attributes legacy sends for a member',
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
        context: const SaleOrderContext(
          shoppingCard: 'CPX0001',
          memberId: 'M001',
          tier: {'Name': 'Elite 10%', 'Discount': 10},
          walletMembers: [
            {'PaymentCode': 'CARAT', 'Balance': 1475.0},
          ],
          cardGroupCode: 'KPE',
          cardTypeCode: 'GOLD',
        ),
      );

      expect(apiClient.lastData, {
        'SessionKey': 'abc123',
        'Attributes': [
          {
            'Group': 'tran_no',
            'Code': 'shopping_card',
            'ValueOfString': 'CPX0001',
          },
          {'Group': 'member', 'Code': 'member_id', 'ValueOfString': 'M001'},
          {
            'Group': 'member',
            'Code': 'tier',
            'ValueOfString': '{"Name":"Elite 10%","Discount":10}',
          },
          {
            'Group': 'member',
            'Code': 'WALLETS',
            'ValueOfString': '[{"PaymentCode":"CARAT","Balance":1475.0}]',
          },
          {'Group': 'member', 'Code': 'cardgroupcode', 'ValueOfString': 'KPE'},
          {'Group': 'member', 'Code': 'cardtypecode', 'ValueOfString': 'GOLD'},
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
          context: const SaleOrderContext(shoppingCard: 'CPX0001'),
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

  test('addCashPayment posts legacy PaymentFormPage\'s cash OrderPayment '
      'and reads payments / remaining / change back', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {
          'Guid': 'g1',
          'OrderDetails': [],
          'OrderPayments': [
            {
              'Guid': 'p1',
              'PaymentCode': '***',
              'PaymentShort': 'CASH',
              'PaymentAmounts': {'CurrAmt': 1000},
              'status': 'SUCCESS',
            },
          ],
          'RemainingAmount': {
            'NetAmount': {'CurrAmt': 0, 'BaseCurrAmt': 0},
          },
          'ChangeAmount': {'CurrAmt': 100, 'BaseCurrAmt': 100},
        },
      ],
      'Message': [],
    };

    final cart = await dataSource.addCashPayment(
      saleEngineEndpoint: 'https://sale-engine',
      sessionKey: 'abc123',
      orderGuid: 'g1',
      currencyCode: 'THB',
      currencyRate: 1,
      amount: 1000,
      baseAmount: 1000,
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/AddPaymentToOrder',
    );
    final sent = apiClient.lastData as Map<String, dynamic>;
    expect(sent['OrderGuid'], 'g1');
    expect(sent['SessionKey'], 'abc123');
    final payment = sent['Payment'] as Map<String, dynamic>;
    expect(payment['PaymentCode'], '***');
    expect(payment['PaymentShort'], 'CASH');
    expect(payment['GatewayId'], 0);
    expect(payment['status'], 'SUCCESS');
    final amounts = payment['PaymentAmounts'] as Map<String, dynamic>;
    expect(amounts['CurrAmt'], 1000);
    expect(amounts['BaseCurrAmt'], 1000);
    expect((amounts['CurrCode'] as Map)['Code'], 'THB');
    final transaction = payment['Transaction'] as Map<String, dynamic>;
    expect(transaction['TransactionGroup'], 1);
    expect(transaction['TransactionType'], 1);
    expect((transaction['Movements'] as List).single['Amount'], 1000);

    expect(cart.payments.single.isCash, isTrue);
    expect(cart.payments.single.amount, 1000);
    expect(cart.remaining, 0);
    expect(cart.change, 100);
  });

  group('actionOrderPayment (legacy SpecialDiscountPage)', () {
    setUp(() {
      apiClient.response = {
        'isCompleted': true,
        'Data': [
          {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
        ],
        'Message': [],
      };
    });

    test('sends Action / Value with empty Rows and the OrderGuid', () async {
      await dataSource.actionOrderPayment(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        action: 'update_special_discount',
        value: '{"Percent":10}',
        orderGuid: 'order-1',
      );
      expect(
        apiClient.lastUrl,
        'https://sale-engine/SaleEngine/ActionOrderPayment',
      );
      expect(apiClient.lastData, {
        'OrderGuid': 'order-1',
        'SessionKey': 'abc123',
        'Rows': <String>[],
        'Action': 'update_special_discount',
        'Value': '{"Percent":10}',
      });
    });

    test('clear-all leaves OrderGuid out, as legacy', () async {
      await dataSource.actionOrderPayment(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        action: 'clear_all_special_discount',
        value: '',
      );
      expect(
        (apiClient.lastData as Map<String, dynamic>).containsKey('OrderGuid'),
        isFalse,
      );
    });
  });

  test('saveChangeExchange posts ActionOrderPayment edit_exchange '
      '(legacy ChangePage)', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {'Guid': 'g1', 'OrderDetails': []},
      ],
      'Message': [],
    };

    await dataSource.saveChangeExchange(
      saleEngineEndpoint: 'https://sale-engine',
      sessionKey: 'abc123',
      orderGuid: 'g1',
      currencyCode: 'USD',
      amount: 2,
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/ActionOrderPayment',
    );
    expect(apiClient.lastData, {
      'OrderGuid': 'g1',
      'Action': 'edit_exchange',
      'Value': '2.0',
      'currency': 'USD',
      'SessionKey': 'abc123',
    });
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

  test('updateOrderStatus posts legacy UpdateOrderStatusModel', () async {
    apiClient.response = {'isCompleted': true, 'Data': null, 'Message': []};

    await dataSource.updateOrderStatus(
      saleEngineEndpoint: 'https://sale-engine',
      branchNo: '1001',
      sessionKey: 'abc123',
      shoppingCard: 'CPX0001',
      orderNo: '42',
      status: OrderStatus.lock,
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/UpdateOrderStatus',
    );
    expect(apiClient.lastData, {
      'branchNo': '1001',
      'shoppingCard': 'CPX0001',
      'orderStatus': 'a',
      'SessionKey': 'abc123',
      'orderNo': '42',
    });
  });

  test('updateOrderStatus throws the server message when not completed', () {
    apiClient.response = {
      'isCompleted': false,
      'Data': null,
      'Message': [
        {
          'MessageType': 'E',
          'MessageCode': 'S01',
          'MessageDesc': 'Shopping card is locked',
        },
      ],
    };

    expect(
      () => dataSource.updateOrderStatus(
        saleEngineEndpoint: 'https://sale-engine',
        branchNo: '1001',
        sessionKey: 'abc123',
        shoppingCard: 'CPX0001',
        orderNo: '42',
        status: OrderStatus.lock,
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.messageDesc,
          'messageDesc',
          'Shopping card is locked',
        ),
      ),
    );
  });

  test('getPromotionList posts legacy PromotionContractModel', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {
          'promo_code': 'B500',
          'promo_name': 'Baht 500 off',
          'allowOverWriteDISC': true,
          'discAmt': 500,
          'discRate': 0,
        },
      ],
      'Message': [],
    };

    final list = await dataSource.getPromotionList(
      saleEngineEndpoint: 'https://sale-engine',
      branchNo: '03',
      subBranchCode: 'CPX',
      query: 'B5',
      excludeMember: true,
    );

    expect(
      apiClient.lastUrl,
      'https://sale-engine/SaleEngine/GetPromotionList',
    );
    expect(apiClient.lastData, {
      'branch_no': '03',
      'subbranch_code': 'CPX',
      'promo_code': 'B5',
      'excludeMember': true,
    });
    expect(list.single.code, 'B500');
    expect(list.single.discountAmount, 500);
    expect(list.single.allowOverwrite, isTrue);
  });

  test(
    'getPromotion returns null when the call completes without one',
    () async {
      apiClient.response = {'isCompleted': true, 'Data': null, 'Message': []};

      final promotion = await dataSource.getPromotion(
        saleEngineEndpoint: 'https://sale-engine',
        sessionKey: 'abc123',
        branchNo: '03',
        subBranchCode: 'CPX',
        code: 'NOPE',
        excludeMember: false,
      );

      expect(apiClient.lastData, {
        'session_key': 'abc123',
        'branch_no': '03',
        'subbranch_code': 'CPX',
        'promo_code': 'NOPE',
        'excludeMember': false,
      });
      expect(promotion, isNull);
    },
  );

  test('actionListItemToOrder posts one action on the rows', () async {
    apiClient.response = {
      'isCompleted': true,
      'Data': [
        {'Guid': 'order-1', 'isCheckOut': false, 'OrderDetails': []},
      ],
      'Message': [],
    };

    await dataSource.actionListItemToOrder(
      saleEngineEndpoint: 'https://sale-engine',
      sessionKey: 'abc123',
      rows: ['line-1'],
      action: 'clear_item_discount',
      value: '["va-1"]',
    );

    expect(apiClient.lastData, {
      'ActionItemValue': {'Action': 'clear_item_discount', 'Value': '["va-1"]'},
      'Rows': ['line-1'],
      'SessionKey': 'abc123',
    });
  });
}
