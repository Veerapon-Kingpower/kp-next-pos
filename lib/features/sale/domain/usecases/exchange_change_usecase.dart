import '../entities/exchange_quote.dart';
import '../repositories/sale_repository.dart';

/// Quotes change due in another currency (legacy `ChangePage`,
/// `SaleEngine/ExchangeCurrency`). A calculation only — nothing is paid.
class ExchangeChangeUseCase {
  final SaleRepository _repository;

  const ExchangeChangeUseCase(this._repository);

  Future<ExchangeQuote> call({
    required String currencyCode,
    required double currencyAmount,
    required double changeInBaht,
    required bool isChangeButton,
  }) => _repository.exchangeChange(
    currencyCode: currencyCode,
    currencyAmount: currencyAmount,
    changeInBaht: changeInBaht,
    isChangeButton: isChangeButton,
  );
}
