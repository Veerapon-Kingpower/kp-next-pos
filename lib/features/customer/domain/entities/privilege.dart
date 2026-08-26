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

  const Privilege({
    required this.name,
    required this.discount,
    this.promoCode = '',
    this.typeCode = '',
    this.subTypeCode = '',
    this.minimumSpendingPerBill = 0,
    this.maxAmountPerBill = 0,
  });
}
