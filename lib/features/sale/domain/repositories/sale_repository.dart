import '../entities/article.dart';
import '../entities/cart.dart';
import '../entities/currency.dart';
import '../entities/exchange_quote.dart';

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

  /// `SaleEngine/ExchangeCurrency` (op 29) as legacy `ChangePage` calls
  /// it: [changeInBaht] is `basecurrAmount`, [currencyAmount] is
  /// `currAmount`, `isPaid` is always false. [isChangeButton] is true when
  /// a currency was picked, false when the cashier typed an amount.
  Future<ExchangeQuote> exchangeChange({
    required String currencyCode,
    required double currencyAmount,
    required double changeInBaht,
    required bool isChangeButton,
  });

  /// `SaleEngine/AddPaymentToOrder` — a cash tender, as legacy
  /// `PaymentFormPage` sends it. Returns the order with its payments,
  /// remaining and change.
  Future<Cart> addCashPayment({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double currencyRate,
    required double amount,
    required double baseAmount,
  });

  /// `SaleEngine/ActionOrderPayment` `edit_exchange` (legacy `ChangePage`
  /// Save): [amount] of the change handed back in [currencyCode].
  Future<Cart> saveChangeExchange({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double amount,
  });

  /// `SaleEngine/GetOrder` (op 8).
  Future<Cart> getCart({
    required String sessionKey,
    required String shoppingCard,
  });
}
