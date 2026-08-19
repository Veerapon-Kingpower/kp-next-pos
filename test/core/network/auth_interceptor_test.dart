import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/network/auth_interceptor.dart';

class _RecordingHandler extends RequestInterceptorHandler {
  RequestOptions? passed;

  @override
  void next(RequestOptions requestOptions) {
    passed = requestOptions;
  }
}

void main() {
  late AuthInterceptor interceptor;

  setUp(() => interceptor = AuthInterceptor());

  test(
    'default branch sets the static app bearer token, CallerID, and JSON headers',
    () {
      final options = RequestOptions(
        path:
            'https://uat-api2.kingpower.com/registerapi/api/Register/GetNationality',
      );
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.passed!.headers['Authorization'], startsWith('Bearer '));
      expect(handler.passed!.headers['CallerID'], isNotNull);
      expect(handler.passed!.headers['Content-Type'], 'application/json');
      expect(handler.passed!.extra['withCredentials'], true);
    },
  );

  test(
    'Member-domain requests use the Member-specific bearer token, not the default one',
    () {
      final options = RequestOptions(
        path:
            'https://uat-api2.kingpower.com/KPServicesapi/api/Member/GetLoyaltyValue',
      );
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      // Distinct header set from the default branch — no Content-Type forced here.
      expect(handler.passed!.headers['Authorization'], startsWith('Bearer '));
      expect(handler.passed!.headers['CallerID'], isNotNull);
      expect(handler.passed!.headers.containsKey('Content-Type'), isFalse);
    },
  );

  test(
    'OAuth token endpoint requests carry no bearer token, only form-urlencoded content type',
    () {
      final options = RequestOptions(
        path: 'https://api2.kingpower.com/identityserverapi/connect/token',
      );
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.passed!.headers.containsKey('Authorization'), isFalse);
      expect(handler.passed!.contentType, Headers.formUrlEncodedContentType);
    },
  );

  test(
    'Order Gateway requests are left untouched — caller sets its own Authorization header',
    () {
      final options = RequestOptions(
        path: 'https://orders.kingpower.com/api/OrderManagement/GetOrderType',
      );
      final handler = _RecordingHandler();

      interceptor.onRequest(options, handler);

      expect(handler.passed!.headers.containsKey('Authorization'), isFalse);
      expect(handler.passed!.headers.containsKey('CallerID'), isFalse);
    },
  );
}
