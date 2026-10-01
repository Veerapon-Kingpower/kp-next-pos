import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'escpos.dart';

/// Turns slips into [RgbaImage]s the width of the paper, with Flutter's
/// own engine — no image package needed.
abstract final class SlipRenderer {
  /// Decodes [encoded] (PNG / JPEG), scaled down to [maxWidth] dots when it
  /// is wider; a narrower image keeps its size.
  static Future<RgbaImage> decode(
    Uint8List encoded, {
    required int maxWidth,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(encoded);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final codec = await descriptor.instantiateCodec(
      targetWidth: descriptor.width > maxWidth ? maxWidth : null,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    descriptor.dispose();
    buffer.dispose();
    return _rgba(frame.image);
  }

  /// Draws [text] in black on white, [width] dots wide, in a monospaced
  /// font so the server's space-aligned columns stay lined up — for slips
  /// the printer's own font can't show (Thai).
  static Future<RgbaImage> text(String text, {required int width}) async {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFF000000),
          fontSize: 22,
          height: 1.2,
          fontFamily: 'monospace',
          fontFamilyFallback: ['Courier New', 'Noto Sans Thai', 'Tahoma'],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width.toDouble());
    final height = painter.height.ceil().clamp(1, 1 << 15);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    painter.paint(canvas, Offset.zero);
    painter.dispose();
    final image = await recorder.endRecording().toImage(width, height);
    return _rgba(image);
  }

  static Future<RgbaImage> _rgba(ui.Image image) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final result = RgbaImage(
      width: image.width,
      height: image.height,
      rgba: data!.buffer.asUint8List(),
    );
    image.dispose();
    return result;
  }
}
