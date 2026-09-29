/// Client-side line-discount arithmetic for the discount previews (desktop
/// S7 overlay, handheld Discount sheet). Pure and presentation-only: it
/// never applies anything — the sale engine owns real discounts, ceilings
/// and promotions.
enum DiscountKind { percent, amount, newPrice }

class DiscountPreview {
  /// unitPrice × quantity.
  final double gross;
  final double discount;
  final double net;

  /// discount / gross × 100 (0 for a zero-priced line).
  final double percent;

  const DiscountPreview({
    required this.gross,
    required this.discount,
    required this.net,
    required this.percent,
  });
}

double _cents(double v) => (v * 100).roundToDouble() / 100;

/// Preview of a line after a [kind] discount of [value]: a percent, a baht
/// amount off the line, or a new unit price. Values are clamped so the
/// line can't go negative or be marked up.
DiscountPreview previewLineDiscount({
  required double unitPrice,
  required int quantity,
  required DiscountKind kind,
  required double value,
}) {
  final gross = _cents(unitPrice * quantity);
  final double discount;
  switch (kind) {
    case DiscountKind.percent:
      discount = gross * value.clamp(0, 100) / 100;
    case DiscountKind.amount:
      discount = value.clamp(0, gross).toDouble();
    case DiscountKind.newPrice:
      final newUnit = value.clamp(0, unitPrice).toDouble();
      discount = gross - newUnit * quantity;
  }
  final rounded = _cents(discount);
  return DiscountPreview(
    gross: gross,
    discount: rounded,
    net: _cents(gross - rounded),
    percent: gross == 0 ? 0 : _cents(rounded / gross * 100),
  );
}
