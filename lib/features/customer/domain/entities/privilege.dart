/// Port of legacy's `PrivilegeModel` (`CustomerModel.ts`) — a member tier/
/// discount privilege attached to a customer. Only the fields relevant to
/// *displaying* a privilege are modeled here; the discount-stacking flags
/// (`AllowStackable`, `BillDiscount`, `CheckItemMaxDiscount`, ...) are
/// checkout-time concerns with no current caller in this app — extend this
/// entity if/when a checkout privilege-selection flow needs them, rather
/// than modeling them speculatively now.
class Privilege {
  final String name;
  final double discount;
  final String promoCode;
  final String typeCode;
  final String subTypeCode;
  final double minimumSpendingPerBill;
  final double maxAmountPerBill;
  // The privilege exactly as `GetCustomer` sent it — what legacy Sale
  // passes back to `GetOrder` as the `member` / `tier` attribute.
  final Map<String, dynamic> raw;

  const Privilege({
    required this.name,
    required this.discount,
    this.promoCode = '',
    this.typeCode = '',
    this.subTypeCode = '',
    this.minimumSpendingPerBill = 0,
    this.maxAmountPerBill = 0,
    this.raw = const {},
  });
}
