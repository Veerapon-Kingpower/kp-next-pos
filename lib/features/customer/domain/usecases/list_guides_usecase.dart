import '../entities/agent.dart';
import '../repositories/customer_repository.dart';

/// Ports `GuidPickerPage` — `typeSearch: "S"` (sub agent) on the shared
/// `SaleEngine/GetListAgent` endpoint, keeping (like `guid-picker.ts`)
/// only rows whose sub agent code or description contains [input],
/// ignoring case.
class ListGuidesUseCase {
  final CustomerRepository _repository;

  const ListGuidesUseCase(this._repository);

  Future<List<Agent>> call({required String input}) async {
    final guides = await _repository.agents(input: input, typeSearch: 'S');
    final query = input.toLowerCase();
    return guides
        .where(
          (a) =>
              a.subAgentCode.toLowerCase().contains(query) ||
              a.subAgentDesc.toLowerCase().contains(query),
        )
        .toList();
  }
}
