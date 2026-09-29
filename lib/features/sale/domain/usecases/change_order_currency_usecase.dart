import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

/// Switches the whole order to another currency (legacy `change_currency`).
class ChangeOrderCurrencyUseCase {
  final SaleRepository _repository;

  const ChangeOrderCurrencyUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String shoppingCard,
    required String currencyCode,
  }) => _repository.changeOrderCurrency(
    sessionKey: sessionKey,
    shoppingCard: shoppingCard,
    currencyCode: currencyCode,
  );
}
