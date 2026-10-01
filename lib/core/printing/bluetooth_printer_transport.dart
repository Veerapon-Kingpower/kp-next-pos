import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'slip_printer.dart';

/// A paired Bluetooth printer (Android): the one named in Settings, else
/// Sunmi's built-in [sunmiInnerPrinter], else the first paired device —
/// legacy Woosim used the first paired one.
class BluetoothPrinterTransport implements PrinterTransport {
  /// The name Sunmi gives its built-in printer's Bluetooth service.
  static const sunmiInnerPrinter = 'InnerPrinter';

  /// Sunmi's built-in printer takes 58 mm paper.
  static const sunmiDots = 384;

  /// Woosim and other 80 mm printers.
  static const wideDots = 576;

  final String preferredName;

  const BluetoothPrinterTransport(this.preferredName);

  /// Which of [paired] (device names) to print to, or null when none.
  static int? pick(List<String> paired, String preferredName) {
    if (paired.isEmpty) return null;
    final want = preferredName.trim().toLowerCase();
    if (want.isNotEmpty) {
      final i = paired.indexWhere((n) => n.trim().toLowerCase() == want);
      if (i >= 0) return i;
    }
    final inner = paired.indexWhere((n) => n.trim() == sunmiInnerPrinter);
    return inner >= 0 ? inner : 0;
  }

  @override
  Future<int> open() async {
    if (!await PrintBluetoothThermal.bluetoothEnabled) {
      throw const PrinterException('Bluetooth is off.');
    }
    final paired = await PrintBluetoothThermal.pairedBluetooths;
    final i = pick([for (final d in paired) d.name], preferredName);
    if (i == null) throw const PrinterException('No paired printer found.');
    final device = paired[i];
    if (!await PrintBluetoothThermal.connectionStatus &&
        !await PrintBluetoothThermal.connect(
          macPrinterAddress: device.macAdress,
        )) {
      throw PrinterException('Could not connect to ${device.name}.');
    }
    return device.name.trim() == sunmiInnerPrinter ? sunmiDots : wideDots;
  }

  @override
  Future<void> send(List<int> bytes) async {
    if (!await PrintBluetoothThermal.writeBytes(bytes)) {
      throw const PrinterException('The printer did not take the slip.');
    }
  }
}
