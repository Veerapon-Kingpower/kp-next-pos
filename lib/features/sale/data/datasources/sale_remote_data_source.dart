import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/article_model.dart';
import '../models/cart_model.dart';
import '../models/currency_model.dart';
import '../models/exchange_quote_model.dart';

/// Sale Engine (`{saleEngineEndpoint}`) cart calls (`api-contracts.md`
/// section 5b, ops 8-11 and 47).
class SaleRemoteDataSource {
  final ApiClient _apiClient;

  const SaleRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<ArticleModel> getMasterByBarcode({
    required String saleEngineEndpoint,
    required String siteCode,
    required String barcode,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetMasterByBarcodeDLL',
      data: {'siteCode': siteCode, 'barcode': barcode, 'priceDate': _today()},
    );

    final result = ReturnObject<ArticleModel>.fromJson(
      response,
      (data) => ArticleModel.fromJson(
        (data as Map<String, dynamic>)['Article'] as Map<String, dynamic>? ??
            const {},
      ),
    );
    return result.unwrap();
  }

  /// `Rows` semantics beyond api-contracts.md's own single-unit example
  /// (`Rows:["1"]`) are unverified — mapped to the requested quantity as the
  /// closest documented fit; confirm against live UAT before relying on
  /// multi-unit adds.
  Future<CartModel> addItemToOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String articleCode,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/AddItemToOrder',
      data: {
        'ItemCode': articleCode,
        'ItemGWP': '',
        'SessionKey': sessionKey,
        'Rows': [quantity.toString()],
      },
    );
    return _firstOrder(response);
  }

  Future<CartModel> updateItemQuantity({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String row,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ActionItemToOrder',
      data: {
        'ActionItemValues': [
          {'Action': 'change_qty', 'Value': quantity.toString()},
        ],
        'Row': row,
        'SessionKey': sessionKey,
      },
    );
    return _firstOrder(response);
  }

  Future<CartModel> removeItem({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String row,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ActionListItemToOrder',
      data: {
        'ActionItemValue': {'Action': 'delete', 'Value': ''},
        'Rows': [row],
        'SessionKey': sessionKey,
      },
    );
    return _firstOrder(response);
  }

  Future<CartModel> getOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String shoppingCard,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetOrder',
      data: {
        'SessionKey': sessionKey,
        'Attributes': [
          {
            'Group': 'BASKET',
            'Code': 'shoppingCard',
            'ValueOfString': shoppingCard,
          },
        ],
      },
    );
    return _firstOrder(response);
  }

  Future<CartModel> changeOrderCurrency({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String shoppingCard,
    required String currencyCode,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ActionItemToOrder',
      data: {
        'ActionItemValues': [
          {'Action': 'change_currency', 'Value': currencyCode},
        ],
        'Row': shoppingCard,
        'SessionKey': sessionKey,
      },
    );
    return _firstOrder(response);
  }

  /// Ports legacy `PaymentFormPage.addPaymentToOrder()` for cash
  /// (`TrasactionGroupEnum.Cash`): the `OrderPayment` it builds, field for
  /// field, posted to `SaleEngine/AddPaymentToOrder`.
  Future<CartModel> addCashPayment({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double currencyRate,
    required double amount,
    required double baseAmount,
  }) async {
    final currency = {'Code': currencyCode, 'Desc': currencyCode};
    const baht = {'Code': 'THB', 'Desc': 'THAI BAHT'};
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/AddPaymentToOrder',
      data: {
        'OrderGuid': orderGuid,
        'Payment': {
          'Guid': '',
          'LineNo': 0,
          'PaymentCode': '***', // legacy PaymentType.CASH
          'PaymentType': 'CASH',
          'PaymentShort': 'CASH',
          'PaymentIcon': '',
          'RefNo': '',
          'URLService': '',
          'CardHolderName': '',
          'ApproveCode': '',
          'BankOfEDC': '',
          'IssuerID': '',
          'WalletBarcode': '',
          'WalletMerchantID': '',
          'WalletTransID': '',
          'GatewayId': 0, // Gateway.OTHER
          'isDCC': false,
          'isCheckVoucher': false,
          'isFixAmount': false,
          'isNotAllowSMC': false,
          'isComplete': false,
          'PaymentAmounts': {
            'CurrCode': currency,
            'CurrRate': currencyRate,
            'CurrAmt': amount,
            'BaseCurrCode': baht,
            'BaseCurrRate': currencyRate,
            'BaseCurrAmt': baseAmount,
            'curChange': 0,
            'ExtendPoint': 0,
          },
          'ChangeAmounts': {
            'CurrCode': currency,
            'CurrRate': 0,
            'CurrAmt': 0,
            'BaseCurrCode': baht,
            'BaseCurrRate': 0,
            'BaseCurrAmt': 0,
            'curChange': 0,
          },
          'Transaction': {
            'TransactionId': 0,
            'GatewaySessionKey': '',
            'TransactionGroup': 1, // TrasactionGroupEnum.Cash
            'TransactionType': 1, // TrantypeEnum.P
            'PartnerId': 0,
            'LastStatus': 1, // PaymentTransactionStatusEnum.RequestPay
            'CurrentStatus': 1,
            'Movements': [
              {
                'TransactionMovementType': 1, // TranMovementTypeEnum.Request
                'Amount': amount,
                'Currency': currency,
                'Description': '',
                'Status': 1,
              },
            ],
            'PartnerType': '',
          },
          'status': 'SUCCESS', // OrderPaymentStatus.Success
          'PartnerTransID': '',
          'PaymentSessionKey': 0,
        },
        'SessionKey': sessionKey,
      },
    );
    return _firstOrder(response);
  }

  /// Ports legacy `ChangePage.onSave()`: `ActionOrderPayment` with
  /// `Action: "edit_exchange"` — hand [amount] of the change back in
  /// [currencyCode].
  Future<CartModel> saveChangeExchange({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double amount,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ActionOrderPayment',
      data: {
        'OrderGuid': orderGuid,
        'Action': 'edit_exchange',
        'Value': amount.toString(),
        'currency': currencyCode,
        'SessionKey': sessionKey,
      },
    );
    return _firstOrder(response);
  }

  Future<ExchangeQuoteModel> exchangeCurrency({
    required String saleEngineEndpoint,
    required String currencyCode,
    required double currencyAmount,
    required double baseAmount,
    required bool isChangeButton,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ExchangeCurrency',
      data: {
        'currCode': currencyCode,
        'currAmount': currencyAmount,
        'basecurrAmount': baseAmount,
        'isPaid': false,
        'isChangeButton': isChangeButton,
      },
    );
    final result = ReturnObject<ExchangeQuoteModel>.fromJson(
      response,
      (data) => ExchangeQuoteModel.fromJson(
        data as Map<String, dynamic>? ?? const {},
      ),
    );
    return result.unwrap();
  }

  Future<List<CurrencyModel>> getCurrencies({
    required String saleEngineEndpoint,
    required String branchNo,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetCurrency',
      data: {'branch_no': branchNo},
    );
    final result = ReturnObject<List<CurrencyModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>? ?? const [])
          .map((c) => CurrencyModel.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }

  CartModel _firstOrder(Map<String, dynamic> response) {
    final result = ReturnObject<List<CartModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((o) => CartModel.fromJson(o as Map<String, dynamic>))
          .toList(growable: false),
    );
    final orders = result.unwrap();
    if (orders.isEmpty) {
      throw const ApiException(messageDesc: 'The order was not returned.');
    }
    return orders.first;
  }

  String _today() {
    final now = DateTime.now();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${now.year}-${pad(now.month)}-${pad(now.day)}';
  }
}
