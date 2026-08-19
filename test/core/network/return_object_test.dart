import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/core/network/return_object.dart';

void main() {
  test('unwrap returns Data when isCompleted and Data are present', () {
    final json = {
      'isCompleted': true,
      'Data': {'value': 42},
      'Message': [],
      'totalCount': 1,
    };

    final result = ReturnObject<int>.fromJson(
      json,
      (data) => (data as Map<String, dynamic>)['value'] as int,
    );

    expect(result.unwrap(), 42);
  });

  test(
    'unwrap throws ApiException with the first message when not completed',
    () {
      final json = {
        'isCompleted': false,
        'Data': null,
        'Message': [
          {
            'MessageType': 'Error',
            'MessageCode': 'E001',
            'MessageDesc': 'Invalid session',
          },
        ],
      };

      final result = ReturnObject<String>.fromJson(
        json,
        (data) => data as String,
      );

      expect(
        () => result.unwrap(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.messageCode,
            'messageCode',
            'E001',
          ),
        ),
      );
    },
  );

  test('unwrap throws a generic ApiException when no message is present', () {
    final json = {'isCompleted': false, 'Data': null, 'Message': []};

    final result = ReturnObject<String>.fromJson(
      json,
      (data) => data as String,
    );

    expect(() => result.unwrap(), throwsA(isA<ApiException>()));
  });
}
