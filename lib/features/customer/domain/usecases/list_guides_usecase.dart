import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `GuidPickerPage` — `typeSearch: "guide"` on the shared
/// `SaleEngine/GetListAgent` endpoint.
class ListGuidesUseCase {
  final CustomerRepository _repository;

  const ListGuidesUseCase(this._repository);

  Future<List<Agent>> call({required String input}) {
    return _repository.agents(input: input, typeSearch: 'guide');
  }
}
