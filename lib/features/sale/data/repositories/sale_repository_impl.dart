import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/cart.dart';
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
    required String articleCode,
    required int quantity,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.addItemToOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      articleCode: articleCode,
      quantity: quantity,
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
  Future<Cart> getCart({
    required String sessionKey,
    required String shoppingCard,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getOrder(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      sessionKey: sessionKey,
      shoppingCard: shoppingCard,
    );
  }
}
