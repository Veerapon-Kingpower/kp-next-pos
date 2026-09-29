import '../entities/currency.dart';
import '../repositories/sale_repository.dart';

/// The branch's exchange-rate table (`SaleEngine/GetCurrency`, op 13).
class ListCurrenciesUseCase {
  final SaleRepository _repository;

  const ListCurrenciesUseCase(this._repository);

  Future<List<Currency>> call() => _repository.listCurrencies();
}
