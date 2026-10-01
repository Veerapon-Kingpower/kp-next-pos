import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/currency.dart';
import '../../domain/entities/exchange_quote.dart';
import '../../domain/entities/line_edit.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/entities/sale_order_context.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_data_source.dart';
import '../local/article_local_data_source.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDataSource _remote;
  final DeviceSettingsStorage _deviceSettingsStorage;
  final ArticleLocalDataSource _articleLocal;

  SaleRepositoryImpl({
    required SaleRemoteDataSource remote,
    required DeviceSettingsStorage deviceSettingsStorage,
    required ArticleLocalDataSource articleLocal,
  }) : _remote = remote,
       _deviceSettingsStorage = deviceSettingsStorage,
       _articleLocal = articleLocal;

  @override
  Future<Article> lookupArticleByBarcode(String barcode) async {
    final settings = await _deviceSettingsStorage.read();

    // Staff-confirmed outage (Settings' "force offline" switch) — skip the
    // network attempt/timeout entirely rather than waiting one out on every
    // scan, and go straight to the cache. See
    // openspec/changes/add-offline-article-cache/design.md.
    if (settings.forceOfflineMode) {
      final cached = _articleLocal.getByBarcode(barcode);
      if (cached != null) return cached;
      throw const ApiException(
        messageDesc:
            'Offline mode is on and this item has not been scanned on '
            'this device before, so there is no cached price for it.',
      );
    }

    try {
      final article = await _remote.getMasterByBarcode(
        saleEngineEndpoint: settings.saleEngineEndpoint,
        // `siteCode` (api-contracts.md op 47 example: "CPX") isn't a
        // documented device-settings field — mapped to `subBranchCode` as
        // the closest available site-scoping value used elsewhere (e.g. op
        // 22's `subbranch_code`); confirm against live UAT.
        siteCode: settings.subBranchCode,
        barcode: barcode,
      );
      _articleLocal.upsert(barcode: barcode, article: article);
      return article;
    } on ApiException catch (e) {
      // Only a connectivity/timeout failure falls back to the cache — a
      // reachable server's own "not found" is not a connectivity problem
      // and must keep failing exactly as it does without a cache (see
      // openspec/changes/add-offline-article-cache/design.md).
      final failure = mapExceptionToFailure(e);
      if (failure is NetworkFailure || failure is TimeoutFailure) {
        final cached = _articleLocal.getByBarcode(barcode);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  @override
  Future<Cart> addItemToCart({
    required String sessionKey,
    required String itemCode,
    List<String> rows = const [],
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.addItemToOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      itemCode: itemCode,
      rows: rows,
    );
  }

  @override
  Future<Cart> updateCartItemQuantity({
    required String sessionKey,
    required String row,
    required int quantity,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.updateItemQuantity(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      row: row,
      quantity: quantity,
    );
  }

  @override
  Future<LineEditResult> editCartItem({
    required String sessionKey,
    required String row,
    required LineEdit edit,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    final result = await _remote.editItem(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      row: row,
      quantity: edit.quantity,
      isFreeze: edit.isFreeze,
      isLockDiscount: edit.isLockDiscount,
      collectStatus: edit.collectStatus,
      serialNo: edit.serialNo,
    );
    return LineEditResult(cart: result.order, warning: result.warning);
  }

  @override
  Future<String> lookupSerial({
    required String site,
    required String barcode,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getSerialByBarcode(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      siteCode: site.isEmpty ? settings.subBranchCode : site,
      barcode: barcode,
    );
  }

  @override
  Future<Cart> removeCartItem({
    required String sessionKey,
    required String row,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.removeItem(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      row: row,
    );
  }

  @override
  Future<List<Currency>> listCurrencies() async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getCurrencies(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      branchNo: settings.branch,
    );
  }

  @override
  Future<Cart> changeOrderCurrency({
    required String sessionKey,
    required String shoppingCard,
    required String currencyCode,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.changeOrderCurrency(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      shoppingCard: shoppingCard,
      currencyCode: currencyCode,
    );
  }

  @override
  Future<ExchangeQuote> exchangeChange({
    required String currencyCode,
    required double currencyAmount,
    required double changeInBaht,
    required bool isChangeButton,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.exchangeCurrency(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      currencyCode: currencyCode,
      currencyAmount: currencyAmount,
      baseAmount: changeInBaht,
      isChangeButton: isChangeButton,
    );
  }

  @override
  Future<Cart> addCashPayment({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double currencyRate,
    required double amount,
    required double baseAmount,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.addCashPayment(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      orderGuid: orderGuid,
      currencyCode: currencyCode,
      currencyRate: currencyRate,
      amount: amount,
      baseAmount: baseAmount,
    );
  }

  @override
  Future<Cart> saveChangeExchange({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double amount,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.saveChangeExchange(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      orderGuid: orderGuid,
      currencyCode: currencyCode,
      amount: amount,
    );
  }

  @override
  Future<Cart> getCart({
    required String sessionKey,
    required SaleOrderContext context,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      context: context,
    );
  }

  @override
  Future<List<Promotion>> listPromotions({
    required String query,
    required bool excludeMember,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getPromotionList(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      branchNo: settings.branch,
      subBranchCode: settings.subBranchCode,
      query: query,
      excludeMember: excludeMember,
    );
  }

  @override
  Future<Promotion?> findPromotion({
    required String sessionKey,
    required String code,
    required bool excludeMember,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getPromotion(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      branchNo: settings.branch,
      subBranchCode: settings.subBranchCode,
      code: code,
      excludeMember: excludeMember,
    );
  }

  @override
  Future<Cart> actOnLines({
    required String sessionKey,
    required List<String> rows,
    required String action,
    required String value,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.actionListItemToOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      rows: rows,
      action: action,
      value: value,
    );
  }

  @override
  Future<Cart> actOnOrder({
    required String sessionKey,
    required String action,
    required String value,
    String? orderGuid,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.actionOrderPayment(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      action: action,
      value: value,
      orderGuid: orderGuid,
    );
  }

  @override
  Future<Cart> saveOrder({
    required String sessionKey,
    required String shoppingCard,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.saveOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      shoppingCard: shoppingCard,
    );
  }

  @override
  Future<void> reverseVirtualStock({required String sessionKey}) async {
    final settings = await _deviceSettingsStorage.read();
    await _remote.reverseVirtualStock(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
    );
  }

  @override
  Future<void> updateOrderStatus({
    required String sessionKey,
    required String shoppingCard,
    required String orderNo,
    required String status,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    await _remote.updateOrderStatus(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      branchNo: settings.branch,
      sessionKey: sessionKey,
      shoppingCard: shoppingCard,
      orderNo: orderNo,
      status: status,
    );
  }
}
