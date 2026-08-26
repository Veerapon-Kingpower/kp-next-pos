import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/domain/usecases/restore_session_usecase.dart';
import '../../customer/domain/entities/privilege.dart';
import '../domain/barcode_scan_input.dart';
import '../domain/entities/cart.dart';
import '../domain/usecases/add_item_to_cart_usecase.dart';
import '../domain/usecases/lookup_article_by_barcode_usecase.dart';
import '../domain/usecases/remove_cart_item_usecase.dart';
import '../domain/usecases/update_cart_item_quantity_usecase.dart';

/// Sale cart state: scan-to-add (with `qty*barcode` parsing and format
/// validation), quantity adjustment, and removal. Sale creation, full
/// totals, currency, and change calculation are task 4.4's scope, not this
/// controller's.
class SaleCartViewModel extends GetxController {
  final RestoreSessionUseCase _restoreSession;
  final LookupArticleByBarcodeUseCase _lookupArticle;
  final AddItemToCartUseCase _addItemToCart;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantity;
  final RemoveCartItemUseCase _removeCartItem;

  SaleCartViewModel({
    required RestoreSessionUseCase restoreSession,
    required LookupArticleByBarcodeUseCase lookupArticle,
    required AddItemToCartUseCase addItemToCart,
    required UpdateCartItemQuantityUseCase updateCartItemQuantity,
    required RemoveCartItemUseCase removeCartItem,
  }) : _restoreSession = restoreSession,
       _lookupArticle = lookupArticle,
       _addItemToCart = addItemToCart,
       _updateCartItemQuantity = updateCartItemQuantity,
       _removeCartItem = removeCartItem;

  Cart? cart;
  bool isBusy = false;
  String? scanError;

  /// The privilege chosen on the Customers tab before switching here, if
  /// the customer has any (see `HomePage._goToSale`'s picker). Client-side
  /// only — there's no discount-calculation or backend privilege API wired
  /// into the cart yet, so this is purely informational for now.
  Privilege? selectedPrivilege;

  void selectPrivilege(Privilege? privilege) {
    selectedPrivilege = privilege;
    update();
  }

  /// Set when the most recent scan's article came from the offline cache
  /// (see openspec/changes/add-offline-article-cache) rather than a fresh
  /// network lookup, so the cashier knows the price may not be current.
  String? staleNotice;

  Future<void> scan(String rawInput) async {
    scanError = null;
    staleNotice = null;

    final ParsedBarcodeScan parsed;
    try {
      parsed = parseBarcodeScan(rawInput);
    } on BarcodeScanFormatException catch (e) {
      scanError = e.message;
      update();
      return;
    }

    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      scanError = 'No active session.';
      update();
      return;
    }

    isBusy = true;
    update();
    try {
      final article = await _lookupArticle(parsed.barcode);
      if (article.isFromCache) {
        staleNotice =
            'Price may be outdated — cached ${_formatCachedAt(article.cachedAt!)}';
      }
      cart = await _addItemToCart(
        sessionKey: sessionKey,
        articleCode: article.articleCode,
        quantity: parsed.quantity,
      );
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<void> updateQuantity({
    required String row,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(row);
      return;
    }
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return;

    isBusy = true;
    update();
    try {
      cart = await _updateCartItemQuantity(
        sessionKey: sessionKey,
        row: row,
        quantity: quantity,
      );
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<void> removeItem(String row) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return;

    isBusy = true;
    update();
    try {
      cart = await _removeCartItem(sessionKey: sessionKey, row: row);
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<String?> _sessionKey() async {
    final session = await _restoreSession();
    return session?.sessionKey;
  }

  static String _formatCachedAt(DateTime cachedAt) {
    final local = cachedAt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}
