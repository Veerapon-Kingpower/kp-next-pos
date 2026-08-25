import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/domain/barcode_scan_input.dart';

void main() {
  group('parseBarcodeScan', () {
    test('a plain barcode implies quantity 1', () {
      final result = parseBarcodeScan('8850012345678');
      expect(result.quantity, 1);
      expect(result.barcode, '8850012345678');
    });

    test('"qty*barcode" parses the quantity and barcode', () {
      final result = parseBarcodeScan('5*8850012345678');
      expect(result.quantity, 5);
      expect(result.barcode, '8850012345678');
    });

    test('trims surrounding whitespace (hardware scanners may add it)', () {
      final result = parseBarcodeScan('  8850012345678  \n');
      expect(result.barcode, '8850012345678');
    });

    test('empty input throws BarcodeScanFormatException', () {
      expect(
        () => parseBarcodeScan(''),
        throwsA(isA<BarcodeScanFormatException>()),
      );
    });

    test('a non-numeric quantity throws BarcodeScanFormatException', () {
      expect(
        () => parseBarcodeScan('abc*8850012345678'),
        throwsA(isA<BarcodeScanFormatException>()),
      );
    });

    test('a zero or negative quantity throws BarcodeScanFormatException', () {
      expect(
        () => parseBarcodeScan('0*8850012345678'),
        throwsA(isA<BarcodeScanFormatException>()),
      );
      expect(
        () => parseBarcodeScan('-1*8850012345678'),
        throwsA(isA<BarcodeScanFormatException>()),
      );
    });

    test('an empty barcode after "*" throws BarcodeScanFormatException', () {
      expect(
        () => parseBarcodeScan('5*'),
        throwsA(isA<BarcodeScanFormatException>()),
      );
    });

    test(
      'a barcode with invalid characters throws BarcodeScanFormatException',
      () {
        expect(
          () => parseBarcodeScan('885 001!'),
          throwsA(isA<BarcodeScanFormatException>()),
        );
      },
    );
  });
}
