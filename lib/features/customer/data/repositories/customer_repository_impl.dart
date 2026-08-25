import '../../../../core/storage/device_settings_storage.dart';
import '../../domain/entities/agent.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_registration.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_data_source.dart';

/// Matches the legacy mobile client's hardcoded `RegisterParamModel
/// .platformCode = "MOBILE"` (`customer-form.ts`) — `api-contracts.md`'s
/// inferred example of `"MPOS"` for this field was wrong.
const _platformCode = 'MOBILE';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerRemoteDataSource _remote;
  final DeviceSettingsStorage _deviceSettingsStorage;

  CustomerRepositoryImpl({
    required CustomerRemoteDataSource remote,
    required DeviceSettingsStorage deviceSettingsStorage,
  }) : _remote = remote,
       _deviceSettingsStorage = deviceSettingsStorage;

  @override
  Future<List<Customer>> search({
    required String shoppingCard,
    required bool isTour,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.searchCustomer(
      baseUrl: settings.isAirportMpos
          ? settings.saleEngineEndpoint
          : settings.webServiceEndpoint,
      branchNo: settings.branch,
      subBranch: settings.subBranchCode,
      shoppingCard: shoppingCard,
      isTour: isTour,
      pickupCode: settings.pickupCode,
      machineNo: settings.uuid,
    );
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
    final settings = await _deviceSettingsStorage.read();
    return _remote.register(
      webServiceEndpoint: settings.webServiceEndpoint,
      agentCode: agentCode,
      subAgentCode: subAgentCode,
      subBranchCode: settings.subBranchCode,
      branchNo: settings.branch,
      platformCode: _platformCode,
      prefixShoppingCard: prefixShoppingCard,
      userCode: userCode,
      machineNo: settings.uuid,
      action: action,
      allowTakeAway: allowTakeAway,
      isAirport: isAirport,
      tour: tour,
      listPersonal: listPersonal,
    );
  }

  @override
  Future<List<Agent>> agents({
    required String input,
    required String typeSearch,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.listAgents(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      branchNo: settings.branch,
      input: input,
      typeSearch: typeSearch,
    );
  }

  @override
  Future<String> shippingAddress(String sessionId) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.getShippingAddress(
      sessionId,
      webServiceEndpoint: settings.webServiceEndpoint,
    );
  }

  @override
  Future<void> updateShippingAddress({
    required String shipAddress,
    required String sessionKey,
  }) async {
    final settings = await _deviceSettingsStorage.read();
    return _remote.updateShippingAddress(
      saleEngineEndpoint: settings.saleEngineEndpoint,
      shipAddress: shipAddress,
      sessionKey: sessionKey,
    );
  }
}
