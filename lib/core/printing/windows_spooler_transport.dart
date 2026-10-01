import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'slip_printer.dart';

/// A Windows printer queue (the Epson thermal): ESC/POS sent through the
/// spooler as `RAW`, so the driver passes it straight to the printer. The
/// queue named in Settings, else the default printer.
class WindowsSpoolerTransport implements PrinterTransport {
  /// 80 mm paper.
  static const dots = 576;

  final String printerName;

  const WindowsSpoolerTransport(this.printerName);

  @override
  Future<int> open() async => dots;

  @override
  Future<void> send(List<int> bytes) async {
    final spool = _Winspool();
    final name = printerName.trim().isEmpty
        ? spool.defaultPrinter()
        : printerName.trim();
    if (name == null) throw const PrinterException('No printer is set up.');

    final pName = name.toNativeUtf16();
    final handle = calloc<IntPtr>();
    final doc = calloc<_DocInfo1>();
    final docName = 'KP POS slip'.toNativeUtf16();
    final dataType = 'RAW'.toNativeUtf16();
    final data = calloc<Uint8>(bytes.length);
    final written = calloc<Uint32>();
    try {
      if (spool.openPrinter(pName, handle, nullptr) == 0) {
        throw PrinterException('Could not open printer "$name".');
      }
      final h = handle.value;
      try {
        doc.ref
          ..pDocName = docName
          ..pOutputFile = nullptr
          ..pDatatype = dataType;
        if (spool.startDoc(h, 1, doc) == 0) {
          throw PrinterException('Printer "$name" did not start the job.');
        }
        spool.startPage(h);
        data.asTypedList(bytes.length).setAll(0, bytes);
        final ok = spool.write(h, data, bytes.length, written);
        spool.endPage(h);
        spool.endDoc(h);
        if (ok == 0 || written.value != bytes.length) {
          throw PrinterException('Printer "$name" did not take the slip.');
        }
      } finally {
        spool.close(h);
      }
    } finally {
      calloc
        ..free(pName)
        ..free(handle)
        ..free(doc)
        ..free(docName)
        ..free(dataType)
        ..free(data)
        ..free(written);
    }
  }
}

/// `DOC_INFO_1W`.
final class _DocInfo1 extends Struct {
  external Pointer<Utf16> pDocName;
  external Pointer<Utf16> pOutputFile;
  external Pointer<Utf16> pDatatype;
}

/// The few `winspool.drv` calls a RAW job needs.
class _Winspool {
  static final _lib = DynamicLibrary.open('winspool.drv');

  final openPrinter = _lib
      .lookupFunction<
        Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>),
        int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>)
      >('OpenPrinterW');
  final startDoc = _lib
      .lookupFunction<
        Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>),
        int Function(int, int, Pointer<_DocInfo1>)
      >('StartDocPrinterW');
  final startPage = _lib
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'StartPagePrinter',
      );
  final write = _lib
      .lookupFunction<
        Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>),
        int Function(int, Pointer<Uint8>, int, Pointer<Uint32>)
      >('WritePrinter');
  final endPage = _lib
      .lookupFunction<Int32 Function(IntPtr), int Function(int)>(
        'EndPagePrinter',
      );
  final endDoc = _lib.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
    'EndDocPrinter',
  );
  final close = _lib.lookupFunction<Int32 Function(IntPtr), int Function(int)>(
    'ClosePrinter',
  );
  final _getDefault = _lib
      .lookupFunction<
        Int32 Function(Pointer<Utf16>, Pointer<Uint32>),
        int Function(Pointer<Utf16>, Pointer<Uint32>)
      >('GetDefaultPrinterW');

  /// The default printer's name, or null when there is none.
  String? defaultPrinter() {
    final size = calloc<Uint32>()..value = 0;
    try {
      _getDefault(nullptr, size);
      if (size.value == 0) return null;
      final buffer = calloc<Uint16>(size.value).cast<Utf16>();
      try {
        if (_getDefault(buffer, size) == 0) return null;
        return buffer.toDartString();
      } finally {
        calloc.free(buffer);
      }
    } finally {
      calloc.free(size);
    }
  }
}
