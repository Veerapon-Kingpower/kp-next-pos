import 'dart:typed_data';

/// A decoded image as RGBA bytes, row by row.
class RgbaImage {
  final int width;
  final int height;
  final Uint8List rgba;

  const RgbaImage({
    required this.width,
    required this.height,
    required this.rgba,
  });
}

/// The ESC/POS commands the slips need, shared by every printer (Epson on
/// Windows, Woosim over Bluetooth, Sunmi's built-in "InnerPrinter").
abstract final class EscPos {
  /// `ESC @` — reset the printer.
  static const List<int> initialize = [0x1B, 0x40];

  /// `ESC d 4` then `GS V B 0` — feed past the tear bar and cut (a printer
  /// without a cutter ignores the cut).
  static const List<int> feedAndCut = [0x1B, 0x64, 4, 0x1D, 0x56, 0x42, 0];

  /// Rows sent per `GS v 0` — small bands keep every printer's buffer happy.
  static const int bandRows = 128;

  /// [image] as 1-bit raster (`GS v 0`): a pixel prints black when it is
  /// opaque and dark; transparent counts as paper.
  static List<int> raster(RgbaImage image) {
    final bytesPerRow = (image.width + 7) ~/ 8;
    final out = <int>[];
    for (var top = 0; top < image.height; top += bandRows) {
      final rows = (image.height - top).clamp(0, bandRows);
      out.addAll([
        0x1D, 0x76, 0x30, 0, //
        bytesPerRow & 0xFF, bytesPerRow >> 8,
        rows & 0xFF, rows >> 8,
      ]);
      for (var y = top; y < top + rows; y++) {
        for (var bx = 0; bx < bytesPerRow; bx++) {
          var byte = 0;
          for (var bit = 0; bit < 8; bit++) {
            final x = bx * 8 + bit;
            if (x < image.width && _isInk(image, x, y)) byte |= 0x80 >> bit;
          }
          out.add(byte);
        }
      }
    }
    return out;
  }

  static bool _isInk(RgbaImage image, int x, int y) {
    final i = (y * image.width + x) * 4;
    final a = image.rgba[i + 3];
    if (a < 128) return false;
    final r = image.rgba[i], g = image.rgba[i + 1], b = image.rgba[i + 2];
    return (r * 299 + g * 587 + b * 114) ~/ 1000 < 128;
  }

  /// Legacy `printSlipText` / `PrintSlipt`: the server's slip text with its
  /// stray escape sequences (`ESC ! ! 1`, lone `ESC`) stripped, then three
  /// blank lines.
  static String cleanSlipText(String text) =>
      '${text.replaceAll('\u001b!!\u0001', '').replaceAll('\u001b', '')}'
      '\n\n\n';

  /// Whether [text] prints as-is in the printer's own font; anything else
  /// (Thai, …) is drawn as an image instead of relying on a codepage.
  static bool isAscii(String text) => text.codeUnits.every((c) => c < 0x80);

  /// One whole job: reset, [body], feed and cut.
  static List<int> job(List<int> body) => [
    ...initialize,
    ...body,
    ...feedAndCut,
  ];
}
