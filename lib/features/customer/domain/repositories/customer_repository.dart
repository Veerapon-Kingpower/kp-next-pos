import '../entities/agent.dart';
import '../entities/customer.dart';
import '../entities/customer_registration.dart';

abstract class CustomerRepository {
  /// Ports `saleEngine.getCustomerInfo` / `flightProvider.getCustomerInfo`
  /// (`Register/GetCustomer`) — device branch/sub-branch/pickup/machine
  /// context is resolved from device settings, matching the legacy client's
  /// `SettingsProvider`-sourced fields. Throws [ApiException] on failure.
  Future<List<Customer>> search({
    required String shoppingCard,
    required bool isTour,
  });

  /// Ports `saleEngine.regsiter` (`Register/RegisterAPI`). Branch/sub-branch/
  /// machine context is resolved from device settings; [tour] and
  /// [listPersonal] are passed through as raw JSON since their internal
  /// shape is undocumented beyond field names in the source material.
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
  });

  /// Ports `saleEngine.getListAgent` (`SaleEngine/GetListAgent`).
  /// [typeSearch] selects agent (`"agent"`), guide (`"guide"`), or
  /// customer-type (`"customertype"`) results from the shared endpoint.
  Future<List<Agent>> agents({
    required String input,
    required String typeSearch,
  });

  /// Ports `saleEngine.getShippingAddress`
  /// (`Register/GetShippingBySessionID`).
  Future<String> shippingAddress(String sessionId);

  /// Ports `saleEngine.updateShippingAddress`
  /// (`SaleEngine/UpdateShippingAddress`) — a different domain base URL
  /// than the read above, preserved from the legacy client.
  Future<void> updateShippingAddress({
    required String shipAddress,
    required String sessionKey,
  });
}
