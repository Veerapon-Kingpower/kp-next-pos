import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

class AddItemToCartUseCase {
  final SaleRepository _repository;

  const AddItemToCartUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String articleCode,
    required int quantity,
  }) => _repository.addItemToCart(
    sessionKey: sessionKey,
    articleCode: articleCode,
    quantity: quantity,
  );
}
