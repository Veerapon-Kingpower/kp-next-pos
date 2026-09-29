import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../error/app_exception.dart';
import '../error/failure.dart';
import 'auth_interceptor.dart';

/// Thin transport boundary shared by every feature's remote data source.
/// Deliberately does not know about response envelopes (`ReturnObject<T>`,
/// `CommonResponse`, `ReturnMemberObject<T>`, ...) — each domain's data
/// source decodes its own envelope shape, since they differ per service
/// (see `api-contracts.md` section 3).
///
/// Abstract so feature tests can supply a fake instead of a real HTTP
/// stack — see `DioApiClient` for the concrete implementation.
abstract class ApiClient {
  Future<Map<String, dynamic>> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  });
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  });
}

class DioApiClient implements ApiClient {
  final Dio _dio;

  DioApiClient({Dio? dio}) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    dio.interceptors.add(AuthInterceptor());
    return dio;
  }

  @override
  Future<Map<String, dynamic>> post(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(
      () => _dio.post(url, data: data, queryParameters: queryParameters),
    );
  }

  @override
  Future<Map<String, dynamic>> get(
    String url, {
    Map<String, dynamic>? queryParameters,
  }) async {
    return _send(() => _dio.get(url, queryParameters: queryParameters));
  }

  Future<Map<String, dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      final response = await request();
      if (kDebugMode) {
        // debugPrint(
        //   '[ApiClient] ${response.requestOptions.uri} -> HTTP ${response.statusCode}\n'
        //   '  request: ${response.requestOptions.data}\n'
        //   '  response: ${response.data}',
        // );
      }
      final body = response.data;
      if (body is Map<String, dynamic>) return body;
      throw ApiException(
        messageDesc:
            'Unexpected response shape from ${response.requestOptions.uri}',
      );
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[ApiClient] ${e.requestOptions.uri} -> HTTP ${e.response?.statusCode ?? 'no response'}\n'
          '  request: ${e.requestOptions.data}\n'
          '  response: ${e.response?.data}',
        );
      }
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(messageDesc: 'The request timed out.');
      case DioExceptionType.connectionError:
        return const ApiException(messageDesc: 'No network connection.');
      case DioExceptionType.badResponse:
        return ApiException(
          messageDesc: 'Server returned ${e.response?.statusCode}.',
          messageCode: e.response?.statusCode?.toString(),
        );
      default:
        return ApiException(
          messageDesc: e.message ?? 'An unexpected network error occurred.',
        );
    }
  }
}

/// Maps a caught [ApiException]/[DioException]-derived exception to a
/// domain [Failure]. Repositories call this at the data → domain boundary.
///
/// [DioApiClient._mapDioException] already collapses every Dio-level error
/// into an [ApiException], keeping only its `messageDesc`/`messageCode` —
/// the connectivity/timeout distinction survives solely as those two
/// literal messages it sets, so that's what this checks first. A caller
/// that needs to tell "unreachable" apart from a legitimate server-side
/// business error (e.g. to fall back to a local cache only for the former)
/// depends on this returning [NetworkFailure]/[TimeoutFailure] specifically
/// for those two cases, not a generic [ApiFailure].
Failure mapExceptionToFailure(Object error) {
  if (error is ApiException) {
    if (error.messageDesc == 'No network connection.') {
      return const NetworkFailure();
    }
    if (error.messageDesc == 'The request timed out.') {
      return const TimeoutFailure();
    }
    return ApiFailure(
      messageDesc: error.messageDesc,
      messageCode: error.messageCode,
    );
  }
  return const UnknownFailure();
}
