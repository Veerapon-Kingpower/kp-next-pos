import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/agent_model.dart';
import '../models/customer_model.dart';
import '../models/customer_registration_model.dart';

/// Register (`{webServiceEndpoint}`) and Sale Engine (`{saleEngineEndpoint}`)
/// domain calls behind the customer workflows (`api-contracts.md` sections
/// 5b and 6). Both base URLs are supplied per call because the legacy client
/// splits these operations across the two domains inconsistently — preserved
/// here rather than normalized, since it reflects the real backend topology.
/// Callers resolve the current values from the user's saved device settings,
/// not a build-time default, since either endpoint can be edited from the
/// Settings page at any time.
class CustomerRemoteDataSource {
  final ApiClient _apiClient;

  const CustomerRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// [baseUrl] is resolved by the caller from the `isAirportMpos` device
  /// setting — the legacy client hits `saleEngineEndpoint` when true, else
  /// `webServiceEndpoint` (`api-contracts.md` section 6, op 2).
  Future<List<CustomerModel>> searchCustomer({
    required String baseUrl,
    required String branchNo,
    required String subBranch,
    required String shoppingCard,
    required bool isTour,
    required String pickupCode,
    required String machineNo,
  }) async {
    final response = await _apiClient.post(
      '$baseUrl/Register/GetCustomer',
      data: {
        'branchNo': branchNo,
        'SubBranch': subBranch,
        'shoppingCard': shoppingCard,
        'isTour': isTour,
        'pickupCode': pickupCode,
        'machineNo': machineNo,
      },
    );

    final result = ReturnObject<List<CustomerModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((c) => CustomerModel.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }

  Future<RegisterResultModel> register({
    required String webServiceEndpoint,
    required String agentCode,
    required String subAgentCode,
    required String subBranchCode,
    required String branchNo,
    required String platformCode,
    required String prefixShoppingCard,
    required String userCode,
    required String machineNo,
    required String action,
    required bool allowTakeAway,
    required bool isAirport,
    required Map<String, dynamic> tour,
    required List<Map<String, dynamic>> listPersonal,
  }) async {
    final url = '$webServiceEndpoint/Register/RegisterAPI';
    // Bare array request body, ported as-is from `RegisterParamModel[]`.
    final data = [
      {
        'agentCode': agentCode,
        'subAgentCode': subAgentCode,
        'subBranchCode': subBranchCode,
        'branchNo': branchNo,
        'platformCode': platformCode,
        'prefixShoppingCard': prefixShoppingCard,
        'userCode': userCode,
        'machineNo': machineNo,
        'action': action,
        'allowTakeAway': allowTakeAway,
        'isAirport': isAirport,
        'tour': tour,
        'listPersonal': listPersonal,
      },
    ];
    if (kDebugMode) {
      debugPrint(
        '[CustomerRemoteDataSource.register] POST $url\n'
        '  request: ${_json(data)}',
      );
    }
    final response = await _apiClient.post(url, data: data);
    if (kDebugMode) {
      debugPrint(
        '[CustomerRemoteDataSource.register] '
        'isCompleted=${response['isCompleted']} '
        'Message=${_json(response['Message'])}\n'
        '  response: ${_json(response)}',
      );
    }

    final result = ReturnObject<List<RegisterResultModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((r) => RegisterResultModel.fromJson(r as Map<String, dynamic>))
          .toList(growable: false),
    );
    final results = result.unwrap();
    if (results.isEmpty) {
      throw const ApiException(
        messageDesc: 'Registration did not return a result.',
      );
    }
    final registration = results.first;
    if (!registration.isComplete) {
      throw const ApiException(messageDesc: 'Registration did not complete.');
    }
    return registration;
  }

  Future<List<AgentModel>> listAgents({
    required String saleEngineEndpoint,
    required String branchNo,
    required String input,
    required String typeSearch,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/GetListAgent',
      data: {'branchNo': branchNo, 'input': input, 'typeSearch': typeSearch},
    );

    final result = ReturnObject<List<AgentModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((a) => AgentModel.fromJson(a as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }

  Future<String> getShippingAddress(
    String sessionId, {
    required String webServiceEndpoint,
  }) async {
    final response = await _apiClient.post(
      '$webServiceEndpoint/Register/GetShippingBySessionID',
      data: const {},
      queryParameters: {'sessionID': sessionId},
    );

    final result = ReturnObject<String>.fromJson(
      response,
      (data) => data as String,
    );
    return result.unwrap();
  }

  /// Response is `ReturnObject<OrderClass[]>` — outside this feature's
  /// domain, so only the standard success/failure envelope is applied and
  /// the order payload itself is discarded.
  Future<void> updateShippingAddress({
    required String saleEngineEndpoint,
    required String shipAddress,
    required String sessionKey,
  }) async {
    final response = await _apiClient.post(
      '$saleEngineEndpoint/SaleEngine/UpdateShippingAddress',
      data: {'ShipAddress': shipAddress, 'SessionKey': sessionKey},
    );

    // `(_) => true` stands in for the discarded `OrderClass[]` payload so
    // `unwrap()`'s `data != null` success check still applies correctly.
    ReturnObject<bool>.fromJson(response, (_) => true).unwrap();
  }

  // Debug logs only: JSON, with anything not encodable (e.g. a raw
  // `dateOfBirth`) printed as its toString().
  static String _json(Object? value) =>
      jsonEncode(value, toEncodable: (v) => v.toString());
}
