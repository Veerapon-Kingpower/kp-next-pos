import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/customer/domain/entities/agent.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_agents_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_customer_types_usecase.dart';
import 'package:kp_pos/features/customer/domain/usecases/list_guides_usecase.dart';

import '../../fake_customer_repository.dart';

const _rows = [
  Agent(
    subAgentCode: 'G01',
    subAgentDesc: 'Guide One',
    agentCode: 'AG01',
    agentDesc: 'Asia Tours',
    customerType: 'TOURIST',
    customerTypeDesc: 'Tourist',
  ),
  Agent(
    subAgentCode: 'G02',
    subAgentDesc: 'Sunny Guide',
    agentCode: 'AG02',
    agentDesc: 'Bangkok Travel',
    customerType: 'VIP',
    customerTypeDesc: 'Tourist VIP',
  ),
];

void main() {
  test('agents send typeSearch "A" and keep code/description matches', () async {
    final repo = FakeCustomerRepository(agentsResult: _rows);

    final result = await ListAgentsUseCase(repo)(input: 'BANGKOK');

    expect(repo.lastAgentsTypeSearch, 'A');
    expect(result.map((a) => a.agentCode), ['AG02']);
  });

  test('guides send typeSearch "S" and keep sub agent code/description '
      'matches', () async {
    final repo = FakeCustomerRepository(agentsResult: _rows);

    final result = await ListGuidesUseCase(repo)(input: 'sunny');

    expect(repo.lastAgentsTypeSearch, 'S');
    expect(result.map((a) => a.subAgentCode), ['G02']);
  });

  test('customer types send typeSearch "C" and match the code only', () async {
    final repo = FakeCustomerRepository(agentsResult: _rows);

    // "TOURIST" is VIP's description, not its code — legacy ignores it.
    final result = await ListCustomerTypesUseCase(repo)(input: 'tourist');

    expect(repo.lastAgentsTypeSearch, 'C');
    expect(result.map((a) => a.customerType), ['TOURIST']);
  });

  test('an empty query keeps every row', () async {
    final repo = FakeCustomerRepository(agentsResult: _rows);

    expect(await ListAgentsUseCase(repo)(input: ''), hasLength(2));
  });
}
