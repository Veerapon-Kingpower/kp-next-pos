/// Port of `AgentModel` from `SaleEngine/GetListAgent`
/// (`api-contracts.md` section 5b, op 32). Shared by the agent, guide, and
/// customer-type pickers — all three call the same endpoint with a
/// different `typeSearch` value.
class Agent {
  final String subAgentCode;
  final String subAgentDesc;
  final String agentCode;
  final String agentDesc;
  final String customerType;
  final String customerTypeDesc;

  const Agent({
    required this.subAgentCode,
    required this.subAgentDesc,
    required this.agentCode,
    required this.agentDesc,
    required this.customerType,
    required this.customerTypeDesc,
  });
}
