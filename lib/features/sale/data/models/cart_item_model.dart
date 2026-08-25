import '../../domain/entities/cart_item.dart';

/// Mock mapping of an `OrderDetails` entry — see `cart_item.dart`'s doc
/// comment for the confirmation caveat. Field names guessed: `Row`,
/// `ItemCode`, `ItemName`, `Qty`, `Price`, `Amount`.
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
    final quantity = (json['Qty'] as num?)?.toInt() ?? 1;
    final unitPrice = (json['Price'] as num?)?.toDouble() ?? 0;
    return CartItemModel(
      row: json['Row'] as String? ?? '',
      articleCode: json['ItemCode'] as String? ?? '',
      articleName: json['ItemName'] as String? ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: (json['Amount'] as num?)?.toDouble() ?? unitPrice * quantity,
    );
  }
}
