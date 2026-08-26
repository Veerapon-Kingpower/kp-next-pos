import '../../domain/entities/customer_registration.dart';

class RegisterResultModel extends RegisterResult {
  const RegisterResultModel({
    required super.outputs,
    required super.messages,
    required super.isComplete,
  });

  factory RegisterResultModel.fromJson(Map<String, dynamic> json) {
    final listOutput = json['listOutput'] as List<dynamic>? ?? const [];
    return RegisterResultModel(
      outputs: listOutput
          .map((o) => RegisterOutputModel.fromJson(o as Map<String, dynamic>))
          .toList(growable: false),
      messages: json['listMessage'] as List<dynamic>? ?? const [],
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }
}

class RegisterOutputModel extends RegisterOutput {
  const RegisterOutputModel({
    required super.runningNo,
    required super.shoppingCard,
    required super.qrShoppingCard,
    required super.coupons,
  });

  factory RegisterOutputModel.fromJson(Map<String, dynamic> json) {
    final listCoupon = json['listCoupon'] as List<dynamic>? ?? const [];
    return RegisterOutputModel(
      runningNo: _stringValue(json['runningNo']),
      shoppingCard: _stringValue(json['shoppingCard']),
      qrShoppingCard: _stringValue(json['qrShoppingCard']),
      coupons: listCoupon
          .map((c) => RegisterCouponModel.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  // `runningNo`/`shoppingCard` come back as raw JSON numbers for purely
  // numeric card values (confirmed via a real response: `runningNo: 0`,
  // `shoppingCard: 9900000033194`) rather than the quoted strings other
  // shopping-card examples (`"CPX0001"`) use elsewhere — a plain `as
  // String?` cast throws a TypeError on that shape (not caught as
  // ApiException), which silently surfaced as "Could not register the
  // customer" on an otherwise-successful registration.
  static String _stringValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
  }
}

class RegisterCouponModel extends RegisterCoupon {
  const RegisterCouponModel({
    required super.couponCode,
    required super.couponDetail,
    required super.couponQRCode,
  });

  factory RegisterCouponModel.fromJson(Map<String, dynamic> json) =>
      RegisterCouponModel(
        couponCode: json['couponCode'] as String? ?? '',
        couponDetail: json['couponDetail'] as String? ?? '',
        couponQRCode: json['couponQRCode'] as String? ?? '',
      );
}
