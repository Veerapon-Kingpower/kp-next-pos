import '../repositories/sale_repository.dart';

class UpdateOrderStatusUseCase {
  final SaleRepository _repository;

  const UpdateOrderStatusUseCase(this._repository);

  Future<void> call({
    required String sessionKey,
    required String shoppingCard,
    required String orderNo,
    required String status,
  }) => _repository.updateOrderStatus(
    sessionKey: sessionKey,
    shoppingCard: shoppingCard,
    orderNo: orderNo,
    status: status,
  );
}
