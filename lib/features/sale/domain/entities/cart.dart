import 'cart_item.dart';

/// Port of the top-level `OrderClass` fields `api-contracts.md` actually
/// names (`Guid`, `OrderDetails`, `isCheckOut` — section 5b, ops 8-11).
/// `items` (from `OrderDetails`) uses a mock field mapping — see
/// `cart_item.dart`'s doc comment for the confirmation caveat.
/// `OrderPayments`/`BillingAmount`/`TotalBillingAmount` are out of this
/// task's scope (totals belong to task 4.4) and are not carried here.
class Cart {
  final String guid;
  final bool isCheckOut;
  final List<CartItem> items;

  const Cart({
    required this.guid,
    required this.isCheckOut,
    required this.items,
  });

  int get itemCount => items.length;
}
