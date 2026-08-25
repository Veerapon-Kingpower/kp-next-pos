import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

class UpdateCartItemQuantityUseCase {
  final SaleRepository _repository;

  const UpdateCartItemQuantityUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String row,
    required int quantity,
  }) => _repository.updateCartItemQuantity(
    sessionKey: sessionKey,
    row: row,
    quantity: quantity,
  );
}
