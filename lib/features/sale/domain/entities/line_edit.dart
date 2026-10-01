import 'cart.dart';

/// Legacy `EditSalePage.saveItem()`'s values for one line, all sent
/// together in one `ActionItemToOrder`.
class LineEdit {
  final int quantity;
  final bool isFreeze;
  final bool isLockDiscount;

  /// `collect_status`: `T` take now, `C` collect.
  final String collectStatus;
  final String serialNo;

  const LineEdit({
    required this.quantity,
    required this.isFreeze,
    required this.isLockDiscount,
    required this.collectStatus,
    required this.serialNo,
  });
}

/// The order after a line edit. [warning] is set when the sale engine
/// answered with a `WARNING` message but still returned the order — legacy
/// shows it and keeps the returned line.
class LineEditResult {
  final Cart cart;
  final String? warning;

  const LineEditResult({required this.cart, this.warning});
}
