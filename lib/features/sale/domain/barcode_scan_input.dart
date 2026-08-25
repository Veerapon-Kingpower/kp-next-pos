/// Parsed result of a scanned/typed register input.
class ParsedBarcodeScan {
  final int quantity;
  final String barcode;

  const ParsedBarcodeScan({required this.quantity, required this.barcode});
}

/// Raised when scanner/keyboard-wedge input isn't a well-formed record —
/// the "serial/record validation" half of task 4.2, kept separate from a
/// failed article lookup (a well-formed barcode that isn't found is a
/// different, later failure mode handled by the article lookup use case).
class BarcodeScanFormatException implements Exception {
  final String message;

  const BarcodeScanFormatException(this.message);

  @override
  String toString() => 'BarcodeScanFormatException($message)';
}

final _barcodePattern = RegExp(r'^[0-9A-Za-z-]+$');

/// Parses register scan input, supporting the quick-entry `qty*barcode`
/// syntax (e.g. `"5*8850012345678"` scans 5 units) alongside a plain
/// barcode, which implies a quantity of 1. Pure and side-effect-free so it
/// can be unit-tested without a scanner or network — the caller (the sale
/// cart view model) is responsible for the article lookup and cart mutation
/// that follow a successful parse.
ParsedBarcodeScan parseBarcodeScan(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const BarcodeScanFormatException('Scan input is empty.');
  }

  final starIndex = trimmed.indexOf('*');
  if (starIndex == -1) {
    _validateBarcode(trimmed);
    return ParsedBarcodeScan(quantity: 1, barcode: trimmed);
  }

  final quantityPart = trimmed.substring(0, starIndex);
  final barcodePart = trimmed.substring(starIndex + 1);
  final quantity = int.tryParse(quantityPart);
  if (quantity == null || quantity <= 0) {
    throw BarcodeScanFormatException(
      '"$quantityPart" is not a valid quantity.',
    );
  }
  _validateBarcode(barcodePart);
  return ParsedBarcodeScan(quantity: quantity, barcode: barcodePart);
}

void _validateBarcode(String barcode) {
  if (barcode.isEmpty) {
    throw const BarcodeScanFormatException('Barcode is empty.');
  }
  if (!_barcodePattern.hasMatch(barcode)) {
    throw BarcodeScanFormatException('"$barcode" is not a valid barcode.');
  }
}
