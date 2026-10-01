import '../entities/article.dart';
import '../entities/cart.dart';
import '../entities/currency.dart';
import '../entities/exchange_quote.dart';
import '../entities/finish_payment.dart';
import '../entities/line_edit.dart';
import '../entities/promotion.dart';
import '../entities/sale_order_context.dart';

abstract class SaleRepository {
  /// `SaleEngine/GetMasterByBarcodeDLL` (`api-contracts.md` op 47).
  Future<Article> lookupArticleByBarcode(String barcode);

  /// `SaleEngine/AddItemToOrder` (op 9): [itemCode] is the scanned / typed
  /// text as-is, [rows] the selected lines' Guids (legacy `onSubmit()`).
  Future<Cart> addItemToCart({
    required String sessionKey,
    required String itemCode,
    List<String> rows = const [],
  });

  /// `SaleEngine/ActionItemToOrder` with `Action: "change_qty"` (op 10).
  Future<Cart> updateCartItemQuantity({
    required String sessionKey,
    required String row,
    required int quantity,
  });

  /// `SaleEngine/ActionItemToOrder` with every legacy Edit Detail value
  /// (`change_qty`, `is_freeze`, `is_lock`, `take_collect`, `SerialNo`).
  Future<LineEditResult> editCartItem({
    required String sessionKey,
    required String row,
    required LineEdit edit,
  });

  /// `SaleEngine/GetMasterByBarcodeDLL` for a scanned serial barcode:
  /// the article's `SerialNo`. [site] is the session's `MachineEnv.site`
  /// (empty: this device's sub-branch).
  Future<String> lookupSerial({required String site, required String barcode});

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
    required SaleOrderContext context,
  });

  /// `SaleEngine/GetPromotionList`: the branch's promotion master.
  Future<List<Promotion>> listPromotions({
    required String query,
    required bool excludeMember,
  });

  /// `SaleEngine/GetPromotion`: null when there is no such promotion.
  Future<Promotion?> findPromotion({
    required String sessionKey,
    required String code,
    required bool excludeMember,
  });

  /// `SaleEngine/ActionListItemToOrder`: [action] with [value] on [rows].
  Future<Cart> actOnLines({
    required String sessionKey,
    required List<String> rows,
    required String action,
    required String value,
  });

  /// `SaleEngine/ActionOrderPayment`: a bill (special) discount [action]
  /// with [value]; [orderGuid] as legacy sends it for that action.
  Future<Cart> actOnOrder({
    required String sessionKey,
    required String action,
    required String value,
    String? orderGuid,
  });

  /// `SaleEngine/ValidateGWP` (legacy `CheckOutPaymentOrderParam`): the
  /// gift-with-purchase check before finishing.
  Future<SaleEngineAnswer> validateGwp({
    required String sessionKey,
    required String orderGuid,
  });

  /// `SaleEngine/FinishPaymentOrder`: completes the paid order, with the
  /// signatures when it requires them (null otherwise, as legacy sends).
  Future<SaleEngineAnswer> finishPaymentOrder({
    required String sessionKey,
    required String orderGuid,
    List<OrderSignatureEntry>? signatures,
  });

  /// `SaleEngine/SaveOrder`: saves the shopping card's order.
  Future<Cart> saveOrder({
    required String sessionKey,
    required String shoppingCard,
  });

  /// `SaleEngine/ReverseVirtualStock`: releases the unsaved lines' stock.
  Future<void> reverseVirtualStock({required String sessionKey});

  /// `SaleEngine/UpdateOrderStatus`: [status] is an `OrderStatus` code
  /// (lock / unlock the shopping card's order).
  Future<void> updateOrderStatus({
    required String sessionKey,
    required String shoppingCard,
    required String orderNo,
    required String status,
  });
}
