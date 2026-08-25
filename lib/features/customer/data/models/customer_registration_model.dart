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
      runningNo: json['runningNo'] as String? ?? '',
      shoppingCard: json['shoppingCard'] as String? ?? '',
      qrShoppingCard: json['qrShoppingCard'] as String? ?? '',
      coupons: listCoupon
          .map((c) => RegisterCouponModel.fromJson(c as Map<String, dynamic>))
          .toList(growable: false),
    );
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
