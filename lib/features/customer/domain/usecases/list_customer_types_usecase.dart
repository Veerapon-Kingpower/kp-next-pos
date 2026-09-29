import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `CustomertypePickerPage` — `typeSearch: "customertype"` on the
/// shared `SaleEngine/GetListAgent` endpoint. Results carry the type in
/// [Agent.customerType] / [Agent.customerTypeDesc].
class ListCustomerTypesUseCase {
  final CustomerRepository _repository;

  const ListCustomerTypesUseCase(this._repository);

  Future<List<Agent>> call({required String input}) {
    return _repository.agents(input: input, typeSearch: 'customertype');
  }
}
