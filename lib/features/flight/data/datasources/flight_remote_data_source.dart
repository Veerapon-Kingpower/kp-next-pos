import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/flight_model.dart';
import '../models/flight_validation_model.dart';

/// Flight domain calls (`{flightApi}`, `api-contracts.md` section 7).
/// Callers resolve `flightApi`/`subBranchCode`/`isAirport` from the user's
/// saved device settings, not a build-time default, matching how the
/// customer feature's remote data source resolves its base URLs.
class FlightRemoteDataSource {
  final ApiClient _apiClient;

  const FlightRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<List<FlightModel>> getFlightByCode({
    required String flightApi,
    required String flightCode,
    required String subBranchCode,
    required String flightType,
    required bool isAirport,
    required int pageNo,
    required int pageSize,
  }) => _listFlights(
    '$flightApi/flight/GetFlightByCode',
    flightCode: flightCode,
    subBranchCode: subBranchCode,
    flightType: flightType,
    isAirport: isAirport,
    pageNo: pageNo,
    pageSize: pageSize,
  );

  /// Endpoint path is lower-case `g` in `getDateByFlight` — preserved as-is
  /// from the legacy client (`api-contracts.md` section 7, op 2).
  Future<List<FlightModel>> getDateByFlight({
    required String flightApi,
    required String flightCode,
    required String subBranchCode,
    required String flightType,
    required bool isAirport,
    required int pageNo,
    required int pageSize,
  }) => _listFlights(
    '$flightApi/flight/getDateByFlight',
    flightCode: flightCode,
    subBranchCode: subBranchCode,
    flightType: flightType,
    isAirport: isAirport,
    pageNo: pageNo,
    pageSize: pageSize,
  );

  Future<List<FlightModel>> _listFlights(
    String url, {
    required String flightCode,
    required String subBranchCode,
    required String flightType,
    required bool isAirport,
    required int pageNo,
    required int pageSize,
  }) async {
    final response = await _apiClient.post(
      url,
      data: {
        'flightCode': flightCode,
        'subBranchCode': subBranchCode,
        'flightType': flightType,
        'isAirport': isAirport,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
    );

    final result = ReturnObject<List<FlightModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((f) => FlightModel.fromJson(f as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }

  Future<FlightValidationModel> validateFlight({
    required String flightApi,
    required String flightCode,
    required String flightDateTime,
  }) async {
    final response = await _apiClient.post(
      '$flightApi/flight/ValidateFlight',
      data: {'flightCode': flightCode, 'flightDateTime': flightDateTime},
    );

    final result = ReturnObject<FlightValidationModel>.fromJson(
      response,
      (data) => FlightValidationModel.fromJson(data as Map<String, dynamic>),
    );
    return result.unwrap();
  }
}
