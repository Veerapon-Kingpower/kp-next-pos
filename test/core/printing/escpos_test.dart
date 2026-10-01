import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/printing/bluetooth_printer_transport.dart';
import 'package:kp_pos/core/printing/escpos.dart';
import 'package:kp_pos/core/printing/slip_renderer.dart';

RgbaImage _image(int width, int height, bool Function(int x, int y) ink) {
  final rgba = Uint8List(width * height * 4);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      final v = ink(x, y) ? 0 : 255;
      rgba
        ..[i] = v
        ..[i + 1] = v
        ..[i + 2] = v
        ..[i + 3] = 255;
    }
  }
  return RgbaImage(width: width, height: height, rgba: rgba);
}

void main() {
  group('EscPos.raster (GS v 0)', () {
    test('header carries bytes per row and rows; dark pixels are bits', () {
      // 10 px wide → 2 bytes per row; only x = 0 and x = 9 are black.
      final bytes = EscPos.raster(_image(10, 1, (x, _) => x == 0 || x == 9));
      expect(bytes, [0x1D, 0x76, 0x30, 0, 2, 0, 1, 0, 0x80, 0x40]);
    });

    test('transparent pixels count as paper', () {
      final image = RgbaImage(
        width: 8,
        height: 1,
        rgba: Uint8List(32), // all black but fully transparent
      );
      expect(EscPos.raster(image).last, 0);
    });

    test('tall images go out in bands of 128 rows', () {
      final bytes = EscPos.raster(_image(8, 300, (_, _) => true));
      // 128 + 128 + 44 rows, each band an 8-byte header + 1 byte per row.
      expect(bytes.length, 3 * 8 + 300);
      expect(bytes.sublist(0, 8), [0x1D, 0x76, 0x30, 0, 1, 0, 128, 0]);
      expect(bytes.sublist(8 + 128, 8 + 128 + 8), [
        0x1D, 0x76, 0x30, 0, 1, 0, 128, 0, //
      ]);
      expect(bytes.sublist(2 * (8 + 128), 2 * (8 + 128) + 8), [
        0x1D, 0x76, 0x30, 0, 1, 0, 44, 0, //
      ]);
    });
  });

  test('job wraps the body in reset … feed and cut', () {
    expect(EscPos.job([1, 2]), [
      0x1B, 0x40, 1, 2, 0x1B, 0x64, 4, 0x1D, 0x56, 0x42, 0, //
    ]);
  });

  test('cleanSlipText strips legacy escapes and adds three lines', () {
    expect(
      EscPos.cleanSlipText('\u001b!!\u0001TOTAL\u001b 100'),
      'TOTAL 100\n\n\n',
    );
  });

  test('isAscii tells printer-font text from Thai', () {
    expect(EscPos.isAscii('TOTAL 100\n'), isTrue);
    expect(EscPos.isAscii('รวม 100'), isFalse);
  });

  group('BluetoothPrinterTransport.pick', () {
    test('the printer named in Settings first', () {
      expect(
        BluetoothPrinterTransport.pick(['InnerPrinter', 'WOOSIM'], ' woosim '),
        1,
      );
    });

    test('else Sunmi InnerPrinter, else the first paired', () {
      expect(
        BluetoothPrinterTransport.pick(['Headset', 'InnerPrinter'], ''),
        1,
      );
      expect(BluetoothPrinterTransport.pick(['WSP-i350', 'X'], 'missing'), 0);
      expect(BluetoothPrinterTransport.pick(const [], ''), isNull);
    });
  });

  testWidgets('SlipRenderer draws text as a white page with ink', (
    tester,
  ) async {
    final image = await tester.runAsync(
      () => SlipRenderer.text('รวม TOTAL', width: 384),
    );
    expect(image!.width, 384);
    expect(image.height, greaterThan(0));
    final raster = EscPos.raster(image);
    expect(raster.skip(8).any((b) => b != 0), isTrue, reason: 'some ink');
  });
}
