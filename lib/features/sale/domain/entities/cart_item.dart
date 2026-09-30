import 'line_discount.dart';

/// A single cart line item — one `OrderDetails` entry. [row] is the line's
/// `Guid`, which `AddItemToOrder`'s `Rows` and `ActionItemToOrder`'s `Row`
/// take. Mapped from legacy `OrderDetail` (`OrderClass.ts`); see
/// `data/models/cart_item_model.dart`.
class CartItem {
  final String row;
  final String articleCode;
  final String articleName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  // `IsBasket`: a line already in the basket (a saved order), not one
  // being bought now — legacy's Buying list is the lines without it.
  final bool isBasket;

  /// `BillingAmount.ValueAdjusts` — the promotions / discounts on the line.
  final List<LineDiscount> discounts;

  /// `BillingAmount.DiscountAmount.CurrAmt`.
  final double discountAmount;

  /// `ItemDetail.MaxPercentDiscount` (null or 0: no ceiling).
  final double? maxPercentDiscount;

  /// `IsLockDiscount` / `IsFreeze`: legacy offers no discount on such a line.
  final bool isLockDiscount;
  final bool isFreeze;

  const CartItem({
    required this.row,
    required this.articleCode,
    required this.articleName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.isBasket = false,
    this.discounts = const [],
    this.discountAmount = 0,
    this.maxPercentDiscount,
    this.isLockDiscount = false,
    this.isFreeze = false,
  });
}
