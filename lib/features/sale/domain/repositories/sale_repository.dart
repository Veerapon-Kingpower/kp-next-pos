import '../entities/article.dart';
import '../entities/cart.dart';

abstract class SaleRepository {
  /// `SaleEngine/GetMasterByBarcodeDLL` (`api-contracts.md` op 47).
  Future<Article> lookupArticleByBarcode(String barcode);

  /// `SaleEngine/AddItemToOrder` (op 9).
  Future<Cart> addItemToCart({
    required String sessionKey,
    required String articleCode,
    required int quantity,
  });

  /// `SaleEngine/ActionItemToOrder` with `Action: "change_qty"` (op 10).
  Future<Cart> updateCartItemQuantity({
    required String sessionKey,
    required String row,
    required int quantity,
  });

  /// `SaleEngine/ActionListItemToOrder` with `Action: "delete"` (op 11).
  Future<Cart> removeCartItem({
    required String sessionKey,
    required String row,
  });

  /// `SaleEngine/GetOrder` (op 8).
  Future<Cart> getCart({
    required String sessionKey,
    required String shoppingCard,
  });
}
