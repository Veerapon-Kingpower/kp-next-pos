import 'package:kp_pos/features/customer/domain/entities/agent.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';
import 'package:kp_pos/features/customer/domain/entities/customer_registration.dart';
import 'package:kp_pos/features/customer/domain/repositories/customer_repository.dart';

/// Shared test double for [CustomerRepository] — used wherever a test needs
/// a working customer search without a real network call.
class FakeCustomerRepository implements CustomerRepository {
  final List<Customer> searchResult;
  final Object? searchError;
  final RegisterResult? registerResult;
  final Object? registerError;
  final List<Agent> agentsResult;

  Map<String, dynamic>? lastRegisterCall;
  String? lastAgentsTypeSearch;
  final List<String> searchedShoppingCards = [];
  String? lastAgentsInput;

  FakeCustomerRepository({
    this.searchResult = const [],
    this.searchError,
    this.registerResult,
    this.registerError,
    this.agentsResult = const [],
  });

  @override
  Future<List<Customer>> search({
    required String shoppingCard,
    required bool isTour,
  }) async {
    searchedShoppingCards.add(shoppingCard);
    if (searchError != null) throw searchError!;
    return searchResult;
  }

  @override
  Future<RegisterResult> register({
    required String agentCode,
    required String subAgentCode,
    required String prefixShoppingCard,
    required String userCode,
    required String action,
    required bool allowTakeAway,
    required bool isAirport,
    required Map<String, dynamic> tour,
    required List<Map<String, dynamic>> listPersonal,
  }) async {
    lastRegisterCall = {
      'agentCode': agentCode,
      'subAgentCode': subAgentCode,
      'prefixShoppingCard': prefixShoppingCard,
      'userCode': userCode,
      'action': action,
      'allowTakeAway': allowTakeAway,
      'isAirport': isAirport,
      'tour': tour,
      'listPersonal': listPersonal,
    };
    if (registerError != null) throw registerError!;
    return registerResult ??
        const RegisterResult(outputs: [], messages: [], isComplete: true);
  }

  @override
  Future<List<Agent>> agents({
    required String input,
    required String typeSearch,
  }) async {
    lastAgentsInput = input;
    lastAgentsTypeSearch = typeSearch;
    return agentsResult;
  }

  @override
  Future<String> shippingAddress(String sessionId) async => '';

  @override
  Future<void> updateShippingAddress({
    required String shipAddress,
    required String sessionKey,
  }) async {}
}
