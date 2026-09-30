import '../entities/cart.dart';
import '../entities/sale_order_context.dart';
import '../repositories/sale_repository.dart';

class GetCartUseCase {
  final SaleRepository _repository;

  const GetCartUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required SaleOrderContext context,
  }) => _repository.getCart(sessionKey: sessionKey, context: context);
}
