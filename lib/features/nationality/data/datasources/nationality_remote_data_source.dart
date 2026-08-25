import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/nationality_model.dart';

/// Ports `SaleEngineProvider.getNationality` (`Register/GetNationality`,
/// `api-contracts.md` section 6, op 4). Callers resolve `webServiceEndpoint`
/// from the user's saved device settings, not a build-time default.
class NationalityRemoteDataSource {
  final ApiClient _apiClient;

  const NationalityRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<List<NationalityModel>> search({
    required String webServiceEndpoint,
    required String countryCode,
    required int pageNo,
    required int pageSize,
  }) async {
    final response = await _apiClient.post(
      '$webServiceEndpoint/Register/GetNationality',
      data: {
        'countryCode': countryCode,
        'pageNo': pageNo,
        'pageSize': pageSize,
      },
    );

    final result = ReturnObject<List<NationalityModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((n) => NationalityModel.fromJson(n as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }
}
