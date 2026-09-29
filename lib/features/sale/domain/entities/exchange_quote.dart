/// `SaleEngine/ExchangeCurrency`'s `AmountModel` (`api-contracts.md` op
/// 29), read the way legacy `ChangePage.onExchangeCurrency()` reads it.
class ExchangeQuote {
  /// `CurrCode.Code`.
  final String currencyCode;

  /// `CurrRate` — "Currency Rate".
  final double rate;

  /// `CurrAmt` — change handed over in [currencyCode] ("Currency Change").
  final double currencyAmount;

  /// `totalLocalChange` — that amount's baht value (the THB box beside it).
  final double currencyAmountInBaht;

  /// `totalChange` — baht still to give ("Local Change (THB)").
  final double localChange;

  const ExchangeQuote({
    required this.currencyCode,
    required this.rate,
    required this.currencyAmount,
    required this.currencyAmountInBaht,
    required this.localChange,
  });
}
