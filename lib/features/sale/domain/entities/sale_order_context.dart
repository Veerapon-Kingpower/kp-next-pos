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

  /// The same order with another privilege ([tier] null = none) — legacy
  /// Sale's Privilege Selection re-sends `GetOrder` this way.
  SaleOrderContext withTier(Map<String, dynamic>? tier) => SaleOrderContext(
    shoppingCard: shoppingCard,
    memberId: memberId,
    tier: tier,
    walletMembers: walletMembers,
    cardGroupCode: cardGroupCode,
    cardTypeCode: cardTypeCode,
  );
}
