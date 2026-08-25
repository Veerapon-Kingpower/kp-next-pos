import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/error/failure.dart';
import 'package:kp_pos/core/network/api_client.dart';

void main() {
  group('mapExceptionToFailure', () {
    test('maps the "no network connection" message to NetworkFailure', () {
      const error = ApiException(messageDesc: 'No network connection.');

      expect(mapExceptionToFailure(error), isA<NetworkFailure>());
    });

    test('maps the "request timed out" message to TimeoutFailure', () {
      const error = ApiException(messageDesc: 'The request timed out.');

      expect(mapExceptionToFailure(error), isA<TimeoutFailure>());
    });

    test('maps any other ApiException to ApiFailure, preserving its message', () {
      const error = ApiException(
        messageDesc: 'Article not found',
        messageCode: 'E01',
      );

      final failure = mapExceptionToFailure(error);

      expect(failure, isA<ApiFailure>());
      expect(failure.message, 'Article not found');
      expect((failure as ApiFailure).messageCode, 'E01');
    });

    test('maps a non-ApiException error to UnknownFailure', () {
      expect(mapExceptionToFailure(Exception('boom')), isA<UnknownFailure>());
    });
  });
}
