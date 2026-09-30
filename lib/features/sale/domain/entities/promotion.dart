/// Legacy `PromotionViewModel` — a row of the promotion master
/// (`SaleEngine/GetPromotionList` / `GetPromotion`). A promotion carries
/// either a baht discount ([discountAmount]) or a percent ([discountRate]);
/// [allowOverwrite] lets the cashier change that value.
class Promotion {
  final String code;
  final String name;
  final bool allowOverwrite;
  final double discountAmount;
  final double discountRate;

  const Promotion({
    required this.code,
    required this.name,
    this.allowOverwrite = false,
    this.discountAmount = 0,
    this.discountRate = 0,
  });
}
