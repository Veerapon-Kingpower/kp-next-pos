import 'line_discount.dart';

/// A single cart line item — one `OrderDetails` entry. [row] is the line's
/// `Guid`, which `AddItemToOrder`'s `Rows` and `ActionItemToOrder`'s `Row`
/// take. Mapped from legacy `OrderDetail` (`OrderClass.ts`); see
/// `data/models/cart_item_model.dart`.
class CartItem {
  final String row;
  final String articleCode;
  final String articleName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  // `IsBasket`: a line already in the basket (a saved order), not one
  // being bought now — legacy's Buying list is the lines without it.
  final bool isBasket;

  /// `BillingAmount.ValueAdjusts` — the promotions / discounts on the line.
  final List<LineDiscount> discounts;

  /// `BillingAmount.DiscountAmount.CurrAmt`.
  final double discountAmount;

  /// `ItemDetail.MaxPercentDiscount` (null or 0: no ceiling).
  final double? maxPercentDiscount;

  /// `IsLockDiscount` / `IsFreeze`: legacy offers no discount on such a line.
  final bool isLockDiscount;
  final bool isFreeze;

  /// `IsCancel`: a basket line cancelled on this order.
  final bool isCancel;

  /// `LineNo` — the line's number on the order (0 when not sent).
  final int lineNo;

  /// `ItemDetail.ItemAttributes` `collect_status`: `T` take now, `C`
  /// collect (at the airport); empty when not set.
  final String collectStatus;

  /// `serialNo` — the serial captured on the line.
  final String serialNo;

  /// `outputDLL.RequireSerial`: legacy Edit Detail shows the serial field
  /// only for such an article.
  final bool requireSerial;

  /// `cites` / `citesPermitNo`: legacy Edit Detail shows "Cites
  /// Infomation" when [cites] is set.
  final String cites;
  final String citesPermitNo;

  /// `VASs` — the value-added-service articles tied to the line.
  final List<VasItem> vasItems;

  /// `recordInfos` — the sale engine's messages on the line (a missing
  /// serial, CITES or VAS, …), shown by legacy Sale as a status icon.
  final List<LineRecordInfo> recordInfos;

  /// Legacy `isRequireOnly()`: an `Error` message — the icon is red.
  bool get hasRecordError => recordInfos.any((r) => r.isError);

  const CartItem({
    required this.row,
    required this.articleCode,
    required this.articleName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.isBasket = false,
    this.discounts = const [],
    this.discountAmount = 0,
    this.maxPercentDiscount,
    this.isLockDiscount = false,
    this.isFreeze = false,
    this.isCancel = false,
    this.lineNo = 0,
    this.collectStatus = '',
    this.serialNo = '',
    this.requireSerial = false,
    this.cites = '',
    this.citesPermitNo = '',
    this.vasItems = const [],
    this.recordInfos = const [],
  });
}

/// Legacy `ReturnMessage` in a line's `recordInfos`.
class LineRecordInfo {
  /// `MessageType`: legacy `MessageErrorMode.Error` ("Error") or `Warning`.
  final String type;
  final String code;
  final String desc;

  const LineRecordInfo({
    required this.type,
    required this.code,
    required this.desc,
  });

  bool get isError => type == 'Error';
}

/// Legacy `VasItem` (`OutputDLL.ts`), as Edit Detail lists it.
class VasItem {
  final String articleCode;
  final String articleName;
  final num totalRequireQty;
  final num existQty;
  final num remainQty;

  const VasItem({
    required this.articleCode,
    required this.articleName,
    required this.totalRequireQty,
    required this.existQty,
    required this.remainQty,
  });
}
