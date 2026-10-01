import 'cart_item.dart';
import 'line_discount.dart';

/// Port of the top-level `OrderClass` fields `api-contracts.md` actually
/// names (`Guid`, `OrderDetails`, `isCheckOut` — section 5b, ops 8-11).
/// `items` (from `OrderDetails`) uses a mock field mapping — see
/// `cart_item.dart`'s doc comment for the confirmation caveat.
/// [billing] carries the order-level amounts when the sale engine returns
/// them; `OrderPayments` is out of scope (task 5.x).
class Cart {
  final String guid;
  final bool isCheckOut;
  final List<CartItem> items;
  final CartBilling? billing;

  /// Tenders the sale engine holds on the order (`OrderPayments`).
  final List<CartPayment> payments;

  /// `RemainingAmount.NetAmount.CurrAmt` — still to pay, in the order's
  /// currency; null until the sale engine reports it.
  final double? remaining;

  /// `ChangeAmount.BaseCurrAmt` — change due in baht after cash tenders.
  final double change;

  /// The `order_no` header attribute (`ValueOfDecimal`) — what
  /// `UpdateOrderStatus` takes as `orderNo`.
  final String orderNo;

  /// `TotalBillingAmount.ValueAdjusts` — the bill (special) discounts
  /// legacy's Checkout → Discount page lists.
  final List<LineDiscount> billDiscounts;

  /// `GWPDetails` — legacy Checkout → More → Gift with Purchase.
  final List<GiftWithPurchase> giftsWithPurchase;

  /// `isRequireSignature` — legacy shows Signature only then.
  final bool requireSignature;

  /// `DFA` / `Promoter` / `CreateDate` — legacy's airport-mPOS profile.
  final String dfa;
  final String promoter;
  final String createDate;

  const Cart({
    required this.guid,
    required this.isCheckOut,
    required this.items,
    this.billing,
    this.payments = const [],
    this.remaining,
    this.change = 0,
    this.orderNo = '',
    this.billDiscounts = const [],
    this.giftsWithPurchase = const [],
    this.requireSignature = false,
    this.dfa = '',
    this.promoter = '',
    this.createDate = '',
  });

  int get itemCount => items.length;
}

/// One `GWPDetails` entry: the text legacy lists and whether this bill
/// already qualifies (`CanApplied`).
class GiftWithPurchase {
  final String text;
  final bool canApply;

  const GiftWithPurchase({required this.text, required this.canApply});
}

/// One `OrderPayment` on the order (legacy `OrderClass.ts`).
class CartPayment {
  final String guid;

  /// `PaymentCode` — `***` is cash (legacy `PaymentType.CASH`).
  final String code;

  /// `PaymentShort`, e.g. `CASH`.
  final String short;

  /// `PaymentAmounts.CurrAmt`.
  final double amount;

  /// `status` — `SUCCESS`, `FAIL`, `VOID`, `UNKNOWN` or empty.
  final String status;

  const CartPayment({
    required this.guid,
    required this.code,
    required this.short,
    required this.amount,
    required this.status,
  });

  bool get isCash => code == '***';
}

/// Order amounts in the order's own currency, as legacy's Sale page shows
/// them (`OrderClass.ts` `BillingAmount` / `TotalBillingAmount`, each an
/// `AmountModel` read at `CurrAmt`). After a `change_currency` the sale
/// engine returns these recalculated in the new currency.
class CartBilling {
  final String currencyCode;
  final String currencyDescription;

  /// `BillingAmount.TotalAmount.CurrRate` — legacy's "Rate:" line.
  final double currencyRate;

  /// `BillingAmount.NetAmount` — legacy's "Total:".
  final double total;

  /// `TotalBillingAmount.NetAmount` — "Grand:".
  final double grand;

  /// `TotalBillingAmount.DiscountAmount` — "Disc.".
  final double discount;

  /// `TotalBillingAmount.TotalSubsidize` — "Cash-D:".
  final double cashD;

  /// `TotalBillingAmount.TotalNetPay` — "Net Pay:".
  final double netPay;

  /// `TotalBillingAmount.TotalNetPay.BaseCurrAmt` — net pay in baht.
  final double netPayBase;

  /// `TotalBillingAmount.PercentDiscountSpecial` — legacy "(%)Discount".
  final double percentDiscountSpecial;

  /// `TotalBillingAmount.DiscountSpecial.CurrAmt` — legacy "Baht Disc."
  /// (0 when the order has none).
  final double discountSpecial;

  /// `TotalBillingAmount.CurrentValueAdjust.VADetail` — legacy "Promotion"
  /// (`Code | Desc`); empty without one.
  final String promotionCode;
  final String promotionName;

  const CartBilling({
    required this.currencyCode,
    required this.currencyDescription,
    required this.currencyRate,
    required this.total,
    required this.grand,
    required this.discount,
    required this.cashD,
    required this.netPay,
    required this.netPayBase,
    this.percentDiscountSpecial = 0,
    this.discountSpecial = 0,
    this.promotionCode = '',
    this.promotionName = '',
  });

  bool get isBaht => currencyCode.isEmpty || currencyCode == 'THB';
}
