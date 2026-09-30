/// One discount on a cart line — legacy `ValueAdjust` in
/// `OrderDetail.BillingAmount.ValueAdjusts`.
class LineDiscount {
  final String guid;
  final String code;
  final String description;
  final bool isPercent;
  final double percent;

  /// `Amount.CurrAmt`: the baht discount (amount mode).
  final double amount;

  /// `Amount.CurrAmtForCal`: what a percent discount came to.
  final double? calculatedAmount;

  /// Only a `Privilege` discount with `isAllowOverwrite` can be edited
  /// (legacy `DiscountPage.edit()`).
  final bool allowOverwrite;
  final String type;

  /// The `ValueAdjust` as the sale engine sent it — an edit sends it back
  /// whole with the new values (legacy clones it).
  final Map<String, dynamic> raw;

  const LineDiscount({
    required this.guid,
    required this.code,
    required this.description,
    required this.isPercent,
    this.percent = 0,
    this.amount = 0,
    this.calculatedAmount,
    this.allowOverwrite = false,
    this.type = '',
    this.raw = const {},
  });

  bool get isEditable => allowOverwrite && type == 'Privilege';
}

/// The Discount page's form — legacy `discountModel`, sent as the
/// `ValueAdjust` JSON of `add_item_discount` / `update_item_discount`.
class LineDiscountDraft {
  final String code;
  final String description;
  final bool isPercent;
  final double percent;
  final double amount;

  /// The discount being edited, if any.
  final LineDiscount? editing;

  const LineDiscountDraft({
    required this.code,
    required this.description,
    required this.isPercent,
    required this.percent,
    required this.amount,
    this.editing,
  });

  /// Legacy `JSON.stringify(discountModel)`: a fresh `ValueAdjust()` only
  /// has `Amount.CurrAmt`, `Percent`, `VADetail` and `typeDiscount`, plus
  /// `IsPercent`; an edit is the original with these values replaced.
  Map<String, dynamic> toValueAdjust() {
    final base = editing?.raw;
    if (base == null) {
      return {
        'Amount': {'CurrAmt': amount},
        'Percent': percent,
        'VADetail': {'Code': code, 'Desc': description},
        'typeDiscount': '',
        'IsPercent': isPercent,
      };
    }
    final amountModel = base['Amount'];
    final detail = base['VADetail'];
    return {
      ...base,
      'Amount': {
        if (amountModel is Map<String, dynamic>) ...amountModel,
        'CurrAmt': amount,
      },
      'Percent': percent,
      'VADetail': {
        if (detail is Map<String, dynamic>) ...detail,
        'Code': code,
        'Desc': description,
      },
      'IsPercent': isPercent,
    };
  }
}
