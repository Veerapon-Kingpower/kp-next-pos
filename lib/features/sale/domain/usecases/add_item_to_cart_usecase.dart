import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

class AddItemToCartUseCase {
  final SaleRepository _repository;

  const AddItemToCartUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String itemCode,
    List<String> rows = const [],
  }) => _repository.addItemToCart(
    sessionKey: sessionKey,
    itemCode: itemCode,
    rows: rows,
  );
}
