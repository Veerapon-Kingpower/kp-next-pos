import 'cart_item.dart';

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

  const Cart({
    required this.guid,
    required this.isCheckOut,
    required this.items,
    this.billing,
  });

  int get itemCount => items.length;
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
  });

  bool get isBaht => currencyCode.isEmpty || currencyCode == 'THB';
}
