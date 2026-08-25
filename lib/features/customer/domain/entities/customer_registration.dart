/// Port of `RegisterResponse` from `Register/RegisterAPI`
/// (`api-contracts.md` section 6, op 3). `isComplete` is a flag nested
/// inside this response, distinct from the envelope's own `isCompleted`.
class RegisterResult {
  final List<RegisterOutput> outputs;
  final List<dynamic> messages;
  final bool isComplete;

  const RegisterResult({
    required this.outputs,
    required this.messages,
    required this.isComplete,
  });
}

class RegisterOutput {
  final String runningNo;
  final String shoppingCard;
  final String qrShoppingCard;
  final List<RegisterCoupon> coupons;

  const RegisterOutput({
    required this.runningNo,
    required this.shoppingCard,
    required this.qrShoppingCard,
    required this.coupons,
  });
}

class RegisterCoupon {
  final String couponCode;
  final String couponDetail;
  final String couponQRCode;

  const RegisterCoupon({
    required this.couponCode,
    required this.couponDetail,
    required this.couponQRCode,
  });
}
