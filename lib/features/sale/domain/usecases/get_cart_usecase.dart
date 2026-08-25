import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

class GetCartUseCase {
  final SaleRepository _repository;

  const GetCartUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String shoppingCard,
  }) => _repository.getCart(sessionKey: sessionKey, shoppingCard: shoppingCard);
}
