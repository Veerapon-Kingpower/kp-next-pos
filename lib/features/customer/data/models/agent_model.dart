import '../../domain/entities/agent.dart';

class AgentModel extends Agent {
  const AgentModel({
    required super.subAgentCode,
    required super.subAgentDesc,
    required super.agentCode,
    required super.agentDesc,
    required super.customerType,
    required super.customerTypeDesc,
  });

  factory AgentModel.fromJson(Map<String, dynamic> json) => AgentModel(
    subAgentCode: json['SubAgentCode'] as String? ?? '',
    subAgentDesc: json['SubAgentDesc'] as String? ?? '',
    agentCode: json['AgentCode'] as String? ?? '',
    agentDesc: json['AgentDesc'] as String? ?? '',
    customerType: json['CustomerType'] as String? ?? '',
    customerTypeDesc: json['CustomerTypeDesc'] as String? ?? '',
  );
}
