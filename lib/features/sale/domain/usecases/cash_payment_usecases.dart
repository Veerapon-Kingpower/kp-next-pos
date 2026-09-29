import '../entities/cart.dart';
import '../repositories/sale_repository.dart';

/// Records a cash tender on the order (legacy `PaymentFormPage`,
/// `SaleEngine/AddPaymentToOrder`).
class AddCashPaymentUseCase {
  final SaleRepository _repository;

  const AddCashPaymentUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double currencyRate,
    required double amount,
    required double baseAmount,
  }) => _repository.addCashPayment(
    sessionKey: sessionKey,
    orderGuid: orderGuid,
    currencyCode: currencyCode,
    currencyRate: currencyRate,
    amount: amount,
    baseAmount: baseAmount,
  );
}

/// Saves change handed back in another currency (legacy `ChangePage`,
/// `ActionOrderPayment` `edit_exchange`).
class SaveChangeExchangeUseCase {
  final SaleRepository _repository;

  const SaveChangeExchangeUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double amount,
  }) => _repository.saveChangeExchange(
    sessionKey: sessionKey,
    orderGuid: orderGuid,
    currencyCode: currencyCode,
    amount: amount,
  );
}
