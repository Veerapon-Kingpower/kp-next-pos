import '../../domain/entities/cart_item.dart';

/// Mapping of an `OrderDetails` entry — see `cart_item.dart`'s doc comment
/// for the confirmation caveat. Guessed keys: `Row`, `ItemCode`, `ItemName`,
/// `Qty`, `Price`, `Amount`. When the entry carries legacy `OrderDetail`'s
/// `BillingQuantity` / `BillingAmount` (`OrderClass.ts`), those win for
/// quantity and amounts, so lines follow the order's currency after a
/// `change_currency` just like the bill totals.
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.row,
    required super.articleCode,
    required super.articleName,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final billingQty = _map(json['BillingQuantity'])['Quantity'];
    final quantity =
        (json['Qty'] as num?)?.toInt() ?? (billingQty as num?)?.toInt() ?? 1;
    final billing = _map(json['BillingAmount']);
    final gross = _map(billing['TotalAmount'])['CurrAmt'] as num?;
    final net = _map(billing['NetAmount'])['CurrAmt'] as num?;
    final unitPrice = gross != null && quantity > 0
        ? gross.toDouble() / quantity
        : (json['Price'] as num?)?.toDouble() ?? 0.0;
    return CartItemModel(
      row: json['Row'] as String? ?? '',
      articleCode: json['ItemCode'] as String? ?? '',
      articleName: json['ItemName'] as String? ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal:
          net?.toDouble() ??
          (json['Amount'] as num?)?.toDouble() ??
          unitPrice * quantity,
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
}
