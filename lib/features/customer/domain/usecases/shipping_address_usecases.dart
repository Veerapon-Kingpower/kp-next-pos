import '../repositories/customer_repository.dart';

class GetShippingAddressUseCase {
  final CustomerRepository _repository;

  const GetShippingAddressUseCase(this._repository);

  Future<String> call(String sessionId) =>
      _repository.shippingAddress(sessionId);
}

class UpdateShippingAddressUseCase {
  final CustomerRepository _repository;

  const UpdateShippingAddressUseCase(this._repository);

  Future<void> call({required String shipAddress, required String sessionKey}) {
    return _repository.updateShippingAddress(
      shipAddress: shipAddress,
      sessionKey: sessionKey,
    );
  }
}
