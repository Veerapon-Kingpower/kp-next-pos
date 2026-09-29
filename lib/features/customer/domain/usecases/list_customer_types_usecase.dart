import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `CustomertypePickerPage` — `typeSearch: "C"` on the
/// shared `SaleEngine/GetListAgent` endpoint. Results carry the type in
/// [Agent.customerType] / [Agent.customerTypeDesc]. Like
/// `customertype-picker.ts`, only rows whose customer type code contains
/// [input] (ignoring case) are kept.
class ListCustomerTypesUseCase {
  final CustomerRepository _repository;

  const ListCustomerTypesUseCase(this._repository);

  Future<List<Agent>> call({required String input}) async {
    final types = await _repository.agents(input: input, typeSearch: 'C');
    final query = input.toLowerCase();
    return types
        .where((a) => a.customerType.toLowerCase().contains(query))
        .toList();
  }
}
