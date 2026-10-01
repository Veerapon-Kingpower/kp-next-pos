import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../storage/device_settings_storage.dart';
import 'bluetooth_printer_transport.dart';
import 'escpos.dart';
import 'slip_renderer.dart';
import 'windows_spooler_transport.dart';

/// Why a slip did not print.
class PrinterException implements Exception {
  final String message;

  const PrinterException(this.message);

  @override
  String toString() => message;
}

/// Where the ESC/POS bytes go — a Bluetooth printer or a Windows queue.
abstract interface class PrinterTransport {
  /// Connects when needed and answers the paper width in dots.
  Future<int> open();

  Future<void> send(List<int> bytes);
}

/// Prints the sale engine's slips: an image URL (invoice, coupon) or slip
/// text (loyalty, cash card) — legacy `printSlipt` / `printSlipText`.
abstract interface class SlipPrinter {
  Future<void> printImageUrl(String url);

  Future<void> printText(String text);
}

/// [SlipPrinter] for every printer here, all ESC/POS: Sunmi's built-in
/// "InnerPrinter" and Woosim over Bluetooth, Epson through the Windows
/// spooler.
class EscPosSlipPrinter implements SlipPrinter {
  final Future<PrinterTransport> Function() _transport;
  final Future<Uint8List> Function(String url) _download;

  EscPosSlipPrinter({
    required Future<PrinterTransport> Function() transport,
    Future<Uint8List> Function(String url)? download,
  }) : _transport = transport,
       _download = download ?? _dioDownload;

  /// The transport for this platform, picking the printer named in Settings
  /// (`printerName`) when there is one.
  factory EscPosSlipPrinter.forPlatform(DeviceSettingsStorage settings) =>
      EscPosSlipPrinter(
        transport: () async {
          final name = (await settings.read()).printerName.trim();
          if (Platform.isWindows) return WindowsSpoolerTransport(name);
          if (Platform.isAndroid) return BluetoothPrinterTransport(name);
          throw const PrinterException(
            'Printing is not supported on this device.',
          );
        },
      );

  @override
  Future<void> printImageUrl(String url) async {
    final transport = await _transport();
    final dots = await transport.open();
    final Uint8List bytes;
    try {
      bytes = await _download(url);
    } on DioException catch (e) {
      throw PrinterException('Could not download the slip: ${e.message}');
    }
    final image = await SlipRenderer.decode(bytes, maxWidth: dots);
    await transport.send(EscPos.job(EscPos.raster(image)));
  }

  @override
  Future<void> printText(String text) async {
    final transport = await _transport();
    final dots = await transport.open();
    final clean = EscPos.cleanSlipText(text);
    final body = EscPos.isAscii(clean)
        ? ascii.encode(clean)
        : EscPos.raster(await SlipRenderer.text(clean, width: dots));
    await transport.send(EscPos.job(body));
  }

  static Future<Uint8List> _dioDownload(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data ?? const []);
  }
}
