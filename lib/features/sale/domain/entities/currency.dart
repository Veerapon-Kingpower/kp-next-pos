/// Port of legacy's `CurrencyModel` from `SaleEngine/GetCurrency`
/// (`api-contracts.md` section 5b, op 13): `{branch_no, curr_code,
/// curr_desc, curr_rate, curr_short}`.
class Currency {
  final String code;
  final String description;

  /// The branch rate for this currency (the contract's example: USD
  /// `35.5`), shown as legacy's picker lists it.
  final double rate;
  final String symbol;

  const Currency({
    required this.code,
    required this.description,
    required this.rate,
    this.symbol = '',
  });
}
