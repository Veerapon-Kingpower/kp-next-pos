import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends Cart {
  const CartModel({
    required super.guid,
    required super.isCheckOut,
    required super.items,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) => CartModel(
    guid: json['Guid'] as String? ?? '',
    isCheckOut: json['isCheckOut'] as bool? ?? false,
    items: (json['OrderDetails'] as List<dynamic>? ?? const [])
        .map((d) => CartItemModel.fromJson(d as Map<String, dynamic>))
        .toList(growable: false),
  );
}
