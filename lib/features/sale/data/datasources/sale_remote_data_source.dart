import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/article_model.dart';
import '../models/cart_model.dart';
import '../models/currency_model.dart';

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
