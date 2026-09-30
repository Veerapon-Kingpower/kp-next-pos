import '../../domain/entities/cart_item.dart';
import '../../domain/entities/line_discount.dart';

/// Mapping of an `OrderDetails` entry, keyed as legacy `OrderDetail`
/// (`OrderClass.ts`): `Guid` (what `Rows` / `Row` send back), `BarCode`,
/// `ItemDetail.Detail` (the name `sale.html` shows), `BillingQuantity` and
/// `BillingAmount` — the amounts follow the order's currency after a
/// `change_currency`, like the bill totals. The earlier guessed keys (`Row`,
/// `ItemCode`, `ItemName`, `Qty`, `Price`, `Amount`) remain as fallbacks.
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.row,
    required super.articleCode,
    required super.articleName,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
    super.isBasket,
    super.discounts,
    super.discountAmount,
    super.maxPercentDiscount,
    super.isLockDiscount,
    super.isFreeze,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final billingQty = _map(json['BillingQuantity'])['Quantity'];
    final quantity =
        (billingQty as num?)?.toInt() ?? (json['Qty'] as num?)?.toInt() ?? 1;
    final itemDetail = _map(json['ItemDetail']);
    final billing = _map(json['BillingAmount']);
    final gross = _map(billing['TotalAmount'])['CurrAmt'] as num?;
    final net = _map(billing['NetAmount'])['CurrAmt'] as num?;
    final unitPrice = gross != null && quantity > 0
        ? gross.toDouble() / quantity
        : (json['Price'] as num?)?.toDouble() ?? 0.0;
    return CartItemModel(
      row: json['Guid'] as String? ?? json['Row'] as String? ?? '',
      articleCode:
          json['BarCode'] as String? ?? json['ItemCode'] as String? ?? '',
      articleName:
          itemDetail['Detail'] as String? ?? json['ItemName'] as String? ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal:
          net?.toDouble() ??
          (json['Amount'] as num?)?.toDouble() ??
          unitPrice * quantity,
      isBasket: json['IsBasket'] as bool? ?? false,
      discounts: [
        for (final adjust
            in (billing['ValueAdjusts'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          _discount(adjust),
      ],
      discountAmount:
          (_map(billing['DiscountAmount'])['CurrAmt'] as num?)?.toDouble() ?? 0,
      maxPercentDiscount: (itemDetail['MaxPercentDiscount'] as num?)
          ?.toDouble(),
      isLockDiscount: json['IsLockDiscount'] as bool? ?? false,
      isFreeze: json['IsFreeze'] as bool? ?? false,
    );
  }

  // Legacy `ValueAdjust`.
  static LineDiscount _discount(Map<String, dynamic> json) {
    final detail = _map(json['VADetail']);
    final amount = _map(json['Amount']);
    return LineDiscount(
      guid: json['Guid'] as String? ?? '',
      code: detail['Code'] as String? ?? '',
      description: detail['Desc'] as String? ?? '',
      isPercent: json['IsPercent'] as bool? ?? false,
      percent: (json['Percent'] as num?)?.toDouble() ?? 0,
      amount: (amount['CurrAmt'] as num?)?.toDouble() ?? 0,
      calculatedAmount: (amount['CurrAmtForCal'] as num?)?.toDouble(),
      allowOverwrite: json['isAllowOverwrite'] as bool? ?? false,
      type: json['typeDiscount'] as String? ?? '',
      raw: json,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
}
