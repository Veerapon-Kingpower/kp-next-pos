/// A single cart line item.
///
/// **Mock field mapping** — `OrderDetails` (the API's cart-line shape) has
/// no field-level schema documented anywhere in `api-contracts.md` or the
/// available source material (see `cart.dart`). The field names below
/// (`Row`, `ItemCode`, `ItemName`, `Qty`, `Price`, `Amount`) are a
/// reasonable guess for a POS cart line, chosen so the register UI has
/// something real to render against — they are NOT confirmed against a
/// live API or the legacy `OrderClass.ts` source and MUST be corrected
/// against real UAT before being treated as ground truth. See
/// `data/models/cart_item_model.dart`.
class CartItem {
  final String row;
  final String articleCode;
  final String articleName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const CartItem({
    required this.row,
    required this.articleCode,
    required this.articleName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });
}
