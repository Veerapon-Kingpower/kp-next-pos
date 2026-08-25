import '../entities/customer_registration.dart';
import '../repositories/customer_repository.dart';

class RegisterCustomerUseCase {
  final CustomerRepository _repository;

  const RegisterCustomerUseCase(this._repository);

  Future<RegisterResult> call({
    required String agentCode,
    required String subAgentCode,
    required String prefixShoppingCard,
    required String userCode,
    required String action,
    required bool allowTakeAway,
    required bool isAirport,
    required Map<String, dynamic> tour,
    required List<Map<String, dynamic>> listPersonal,
  }) {
    return _repository.register(
      agentCode: agentCode,
      subAgentCode: subAgentCode,
      prefixShoppingCard: prefixShoppingCard,
      userCode: userCode,
      action: action,
      allowTakeAway: allowTakeAway,
      isAirport: isAirport,
      tour: tour,
      listPersonal: listPersonal,
    );
  }
}
