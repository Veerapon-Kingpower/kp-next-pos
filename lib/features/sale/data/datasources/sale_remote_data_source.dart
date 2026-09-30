import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../../domain/entities/sale_order_context.dart';
import '../models/article_model.dart';
import '../models/cart_model.dart';
import '../models/currency_model.dart';
import '../models/exchange_quote_model.dart';
import '../models/promotion_model.dart';

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

  /// Ports legacy `sale.ts`'s `onSubmit()` `OrderAddContract`: `ItemCode`
  /// is the scanned / typed text as-is and `Rows` the Guids of the lines
  /// selected in the cart (empty when none). `ItemGWP` is left unset there,
  /// so it is not sent.
  Future<CartModel> addItemToOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String itemCode,
    List<String> rows = const [],
  }) async {
    final url = '$saleEngineEndpoint/SaleEngine/AddItemToOrder';
    final data = {'SessionKey': sessionKey, 'ItemCode': itemCode, 'Rows': rows};
    if (kDebugMode) {
      debugPrint(
        '[SaleRemoteDataSource.addItemToOrder] POST $url\n'
        '  request: ${jsonEncode(data)}',
      );
    }
    final response = await _apiClient.post(url, data: data);
    if (kDebugMode) {
      debugPrint(
        '[SaleRemoteDataSource.addItemToOrder] '
        'isCompleted=${response['isCompleted']} '
        'Message=${jsonEncode(response['Message'])}\n'
        '  response: ${jsonEncode(response)}',
      );
    }
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

  /// Ports legacy `sale.ts`'s `getOrder()` (run on every Sale page enter):
  /// opens [context]'s shopping-card order in the session, which
  /// `AddItemToOrder` and the other order calls then work against.
  Future<CartModel> getOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required SaleOrderContext context,
  }) async {
    Map<String, dynamic> attribute(String group, String code, String value) => {
      'Group': group,
      'Code': code,
      'ValueOfString': value,
    };
    final tier = context.tier;
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetOrder',
      data: {
        'SessionKey': sessionKey,
        'Attributes': [
          attribute('tran_no', 'shopping_card', context.shoppingCard),
          if (context.isMember) ...[
            attribute('member', 'member_id', context.memberId),
            attribute('member', 'tier', tier == null ? '' : jsonEncode(tier)),
            attribute('member', 'WALLETS', jsonEncode(context.walletMembers)),
          ],
          if (context.cardGroupCode.isNotEmpty)
            attribute('member', 'cardgroupcode', context.cardGroupCode),
          if (context.cardTypeCode.isNotEmpty)
            attribute('member', 'cardtypecode', context.cardTypeCode),
        ],
      },
    );
    return _firstOrder(response);
  }

  /// Ports legacy `sale.ts`'s `updateOrderStatus()` /
  /// `onlyUnlockShoppingCard()`: `UpdateOrderStatusModel` posted to
  /// `SaleEngine/UpdateOrderStatus`. Only `isCompleted` matters there; a
  /// failure throws with the server's first message.
  Future<void> updateOrderStatus({
    required String saleEngineEndpoint,
    required String branchNo,
    required String sessionKey,
    required String shoppingCard,
    required String orderNo,
    required String status,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/UpdateOrderStatus',
      data: {
        'branchNo': branchNo,
        'shoppingCard': shoppingCard,
        'orderStatus': status,
        'SessionKey': sessionKey,
        'orderNo': orderNo,
      },
    );
    final result = ReturnObject<Object?>.fromJson(response, (data) => data);
    if (result.isCompleted) return;
    final message = result.messages.isEmpty ? null : result.messages.first;
    throw ApiException(
      messageDesc: message?.messageDesc ?? 'The order status was not updated.',
      messageCode: message?.messageCode,
    );
  }

  /// Ports legacy `sale.ts`'s `doSaveOrder()`: `SaleEngine/SaveOrder`
  /// with the same `tran_no` / `shopping_card` attribute `GetOrder` takes.
  Future<CartModel> saveOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String shoppingCard,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/SaveOrder',
      data: {
        'SessionKey': sessionKey,
        'Attributes': [
          {
            'Group': 'tran_no',
            'Code': 'shopping_card',
            'ValueOfString': shoppingCard,
          },
        ],
      },
    );
    return _firstOrder(response);
  }

  /// Ports legacy `sale.ts`'s `reverseVirtualStock()`: releases the stock
  /// the unsaved lines reserved. Fails (with the first message) as legacy
  /// alerts: not completed or no `Data`, and a message sent.
  Future<void> reverseVirtualStock({
    required String saleEngineEndpoint,
    required String sessionKey,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ReverseVirtualStock',
      data: {'SessionKey': sessionKey},
    );
    final result = ReturnObject<Object?>.fromJson(response, (data) => data);
    if ((result.isCompleted && result.data == true) ||
        result.messages.isEmpty) {
      return;
    }
    throw ApiException(
      messageDesc: result.messages.first.messageDesc,
      messageCode: result.messages.first.messageCode,
    );
  }

  /// Legacy `PromotionPickerPage.setItems()`: the promotion master for the
  /// branch, filtered by [query] (code). No session key, as in legacy.
  Future<List<PromotionModel>> getPromotionList({
    required String saleEngineEndpoint,
    required String branchNo,
    required String subBranchCode,
    required String query,
    required bool excludeMember,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetPromotionList',
      data: {
        'branch_no': branchNo,
        'subbranch_code': subBranchCode,
        'promo_code': query,
        'excludeMember': excludeMember,
      },
    );
    final result = ReturnObject<List<PromotionModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(PromotionModel.fromJson)
          .toList(growable: false),
    );
    // Legacy shows an empty list when not completed.
    return result.isCompleted ? result.data ?? const [] : const [];
  }

  /// Legacy `DiscountPage.getPromotion()`: one promotion by code; null when
  /// the call completes without one ("not found"), a failure throws the
  /// server's message.
  Future<PromotionModel?> getPromotion({
    required String saleEngineEndpoint,
    required String sessionKey,
    required String branchNo,
    required String subBranchCode,
    required String code,
    required bool excludeMember,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetPromotion',
      data: {
        'session_key': sessionKey,
        'branch_no': branchNo,
        'subbranch_code': subBranchCode,
        'promo_code': code,
        'excludeMember': excludeMember,
      },
    );
    final result = ReturnObject<PromotionModel>.fromJson(
      response,
      (data) => PromotionModel.fromJson(data as Map<String, dynamic>),
    );
    if (result.isCompleted) return result.data;
    return result.unwrap();
  }

  /// `SaleEngine/ActionListItemToOrder` with one action on [rows] — the
  /// Discount page's `add_item_discount`, `update_item_discount`,
  /// `clear_item_discount`, `clear_discount_all` and
  /// `add_item_discount_by_qrcode`.
  Future<CartModel> actionListItemToOrder({
    required String saleEngineEndpoint,
    required String sessionKey,
    required List<String> rows,
    required String action,
    required String value,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/ActionListItemToOrder',
      data: {
        'ActionItemValue': {'Action': action, 'Value': value},
        'Rows': rows,
        'SessionKey': sessionKey,
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
