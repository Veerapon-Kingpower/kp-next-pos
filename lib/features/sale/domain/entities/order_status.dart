/// Legacy `OrderStatus` (`OrderClass.ts`) — the `orderStatus` codes
/// `SaleEngine/UpdateOrderStatus` takes.
abstract final class OrderStatus {
  /// Sale page holds the shopping card.
  static const lock = 'a';

  /// Released when the Sale page is left.
  static const unlock = 'A';

  /// Sent by legacy `goCheckout()` on the way to Checkout.
  static const checkout = 'e';
}
