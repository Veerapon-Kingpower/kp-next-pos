import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `AgentPickerPage` — `typeSearch: "A"` on the shared
/// `SaleEngine/GetListAgent` endpoint, keeping (like `agent-picker.ts`)
/// only rows whose agent code or description contains [input], ignoring
/// case.
class ListAgentsUseCase {
  final CustomerRepository _repository;

  const ListAgentsUseCase(this._repository);

  Future<List<Agent>> call({required String input}) async {
    final agents = await _repository.agents(input: input, typeSearch: 'A');
    final query = input.toLowerCase();
    return agents
        .where(
          (a) =>
              a.agentCode.toLowerCase().contains(query) ||
              a.agentDesc.toLowerCase().contains(query),
        )
        .toList();
  }
}
