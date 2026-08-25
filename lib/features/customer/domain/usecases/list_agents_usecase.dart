import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `AgentPickerPage` — `typeSearch: "agent"` on the shared
/// `SaleEngine/GetListAgent` endpoint.
class ListAgentsUseCase {
  final CustomerRepository _repository;

  const ListAgentsUseCase(this._repository);

  Future<List<Agent>> call({required String input}) {
    return _repository.agents(input: input, typeSearch: 'agent');
  }
}
