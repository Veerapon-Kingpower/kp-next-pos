import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

class RemoveCartItemUseCase {
  final SaleRepository _repository;

  const RemoveCartItemUseCase(this._repository);

  Future<Cart> call({required String sessionKey, required String row}) =>
      _repository.removeCartItem(sessionKey: sessionKey, row: row);
}
