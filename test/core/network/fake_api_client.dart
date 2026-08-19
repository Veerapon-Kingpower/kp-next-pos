import 'package:kp_pos/core/network/api_client.dart';

/// Shared test double for [ApiClient] — records the last call and returns
/// a canned response (or throws a canned error) without any real HTTP.
class FakeApiClient implements ApiClient {
  String? lastUrl;
  Object? lastData;
  Map<String, dynamic> response;
  Object? errorToThrow;

  FakeApiClient({Map<String, dynamic>? response, this.errorToThrow})
    : response = response ?? const {};

  @override
  Future<Map<String, dynamic>> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    lastUrl = url;
    lastData = data;
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }

  @override
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    lastUrl = url;
    if (errorToThrow != null) throw errorToThrow!;
    return response;
  }
}
