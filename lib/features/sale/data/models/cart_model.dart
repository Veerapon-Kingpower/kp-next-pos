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
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final remaining = _map(json['RemainingAmount'])['NetAmount'];
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
    );
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
    return CartBilling(
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
