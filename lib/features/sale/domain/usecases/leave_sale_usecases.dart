import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

/// Legacy `doSaveOrder()` — "Yes" on the leave-Sale prompt.
class SaveOrderUseCase {
  final SaleRepository _repository;

  const SaveOrderUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String shoppingCard,
  }) =>
      _repository.saveOrder(sessionKey: sessionKey, shoppingCard: shoppingCard);
}

/// Legacy `reverseVirtualStock()` — "No" on the leave-Sale prompt.
class ReverseVirtualStockUseCase {
  final SaleRepository _repository;

  const ReverseVirtualStockUseCase(this._repository);

  Future<void> call({required String sessionKey}) =>
      _repository.reverseVirtualStock(sessionKey: sessionKey);
}
