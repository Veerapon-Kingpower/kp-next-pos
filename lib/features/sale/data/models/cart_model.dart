import '../../domain/entities/cart.dart';
import 'cart_item_model.dart';

class CartModel extends Cart {
  const CartModel({
    required super.guid,
    required super.isCheckOut,
    required super.items,
    super.billing,
    super.payments,
    super.remaining,
    super.change,
    super.orderNo,
    super.billDiscounts,
    super.giftsWithPurchase,
    super.requireSignature,
    super.dfa,
    super.promoter,
    super.createDate,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final remaining = _map(json['RemainingAmount'])['NetAmount'];
    final totals = _map(json['TotalBillingAmount']);
    return CartModel(
      guid: json['Guid'] as String? ?? '',
      isCheckOut: json['isCheckOut'] as bool? ?? false,
      items: (json['OrderDetails'] as List<dynamic>? ?? const [])
          .map((d) => CartItemModel.fromJson(d as Map<String, dynamic>))
          .toList(growable: false),
      billing: _billing(json),
      payments: (json['OrderPayments'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => CartPayment(
              guid: p['Guid'] as String? ?? '',
              code: p['PaymentCode'] as String? ?? '',
              short: p['PaymentShort'] as String? ?? '',
              amount: _num(_map(p['PaymentAmounts'])['CurrAmt']),
              status: p['status'] as String? ?? '',
            ),
          )
          .toList(growable: false),
      remaining: remaining is Map<String, dynamic>
          ? _num(remaining['CurrAmt'])
          : null,
      change: _num(_map(json['ChangeAmount'])['BaseCurrAmt']),
      orderNo: _orderNo(json['HeaderAttributes']),
      billDiscounts: [
        for (final adjust
            in (totals['ValueAdjusts'] as List<dynamic>? ?? [])
                .whereType<Map<String, dynamic>>())
          CartItemModel.discountFromJson(adjust),
      ],
      giftsWithPurchase: [
        for (final gwp
            in (json['GWPDetails'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>())
          GiftWithPurchase(
            text: gwp['DetailTextShow'] as String? ?? '',
            canApply: gwp['CanApplied'] as bool? ?? false,
          ),
      ],
      requireSignature: json['isRequireSignature'] as bool? ?? false,
      dfa: '${json['DFA'] ?? ''}',
      promoter: '${json['Promoter'] ?? ''}',
      createDate: '${json['CreateDate'] ?? ''}',
    );
  }

  // Legacy: `HeaderAttributes.find(x => x.Code == "order_no")
  // .ValueOfDecimal.toString()` — a whole number, sent without a decimal
  // point.
  static String _orderNo(Object? headerAttributes) {
    if (headerAttributes is! List) return '';
    for (final attribute
        in headerAttributes.whereType<Map<String, dynamic>>()) {
      if (attribute['Code'] != 'order_no') continue;
      final value = attribute['ValueOfDecimal'];
      if (value is! num) return '';
      return value == value.truncate()
          ? value.toInt().toString()
          : value.toString();
    }
    return '';
  }

  // Field names from legacy `OrderClass.ts` (`BillingAmount`,
  // `TotalBillingAmount`, `AmountModel`, `CodeAndDescription`).
  static CartBilling? _billing(Map<String, dynamic> json) {
    final billing = json['BillingAmount'];
    if (billing is! Map<String, dynamic>) return null;
    final totals = json['TotalBillingAmount'] is Map<String, dynamic>
        ? json['TotalBillingAmount'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final totalAmount = _map(billing['TotalAmount']);
    final currency = _map(totalAmount['CurrCode']);
    final promotion = _map(_map(totals['CurrentValueAdjust'])['VADetail']);
    return CartBilling(
      percentDiscountSpecial: _num(totals['PercentDiscountSpecial']),
      discountSpecial: _num(_map(totals['DiscountSpecial'])['CurrAmt']),
      promotionCode: promotion['Code'] as String? ?? '',
      promotionName: promotion['Desc'] as String? ?? '',
      currencyCode: currency['Code'] as String? ?? '',
      currencyDescription: currency['Desc'] as String? ?? '',
      currencyRate: _num(totalAmount['CurrRate']),
      total: _num(_map(billing['NetAmount'])['CurrAmt']),
      grand: _num(_map(totals['NetAmount'])['CurrAmt']),
      discount: _num(_map(totals['DiscountAmount'])['CurrAmt']),
      cashD: _num(_map(totals['TotalSubsidize'])['CurrAmt']),
      netPay: _num(_map(totals['TotalNetPay'])['CurrAmt']),
      netPayBase: _num(_map(totals['TotalNetPay'])['BaseCurrAmt']),
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};

  static double _num(Object? value) => value is num ? value.toDouble() : 0;
}
