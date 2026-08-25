import '../../../../core/network/api_client.dart';
import '../../../../core/network/return_object.dart';
import '../models/sub_branch_model.dart';

/// Register (`{webServiceEndpoint}`) lookups behind the Settings page
/// (`api-contracts.md` section 6).
class SettingsRemoteDataSource {
  final ApiClient _apiClient;

  const SettingsRemoteDataSource({required ApiClient apiClient})
    : _apiClient = apiClient;

  /// [baseUrl] is the Register endpoint being configured on the Settings
  /// page itself, not a build-time default — sub-branches are re-fetched
  /// against whatever the user has currently entered there.
  Future<List<SubBranchModel>> listSubBranches({
    required String baseUrl,
    required String key,
  }) async {
    final response = await _apiClient.post(
      '$baseUrl/Register/GetListSubbranch',
      data: {'key': key, 'pageNo': 0, 'pageSize': 50},
    );

    final result = ReturnObject<List<SubBranchModel>>.fromJson(
      response,
      (data) => (data as List<dynamic>)
          .map((s) => SubBranchModel.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
    return result.unwrap();
  }
}
