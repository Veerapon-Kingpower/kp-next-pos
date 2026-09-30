/// What legacy `customer.ts`'s `goToSalePage()` hands the Sale page, which
/// sends it on `GetOrder` to open the shopping card's order in the session.
/// [tier] and [walletMembers] only count for a member ([memberId] set), as
/// in legacy.
class SaleOrderContext {
  final String shoppingCard;
  final String memberId;
  // The selected privilege, raw as `GetCustomer` sent it; null when none.
  final Map<String, dynamic>? tier;
  final List<Map<String, dynamic>> walletMembers;
  final String cardGroupCode;
  final String cardTypeCode;

  const SaleOrderContext({
    required this.shoppingCard,
    this.memberId = '',
    this.tier,
    this.walletMembers = const [],
    this.cardGroupCode = '',
    this.cardTypeCode = '',
  });

  bool get isMember => memberId.isNotEmpty;
}
