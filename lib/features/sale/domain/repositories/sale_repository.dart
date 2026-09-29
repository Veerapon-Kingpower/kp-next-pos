import '../entities/article.dart';
import '../entities/cart.dart';
import '../entities/currency.dart';

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

  /// `SaleEngine/GetCurrency` (op 13) for this device's branch.
  Future<List<Currency>> listCurrencies();

  /// `SaleEngine/ActionItemToOrder` with `Action: "change_currency"` —
  /// ports legacy `CurrencyPickerPage.onChange()`, which sends the order's
  /// shopping card as `Row`. The sale engine recalculates the whole order
  /// in [currencyCode].
  Future<Cart> changeOrderCurrency({
    required String sessionKey,
    required String shoppingCard,
    required String currencyCode,
  });

  /// `SaleEngine/GetOrder` (op 8).
  Future<Cart> getCart({
    required String sessionKey,
    required String shoppingCard,
  });
}
