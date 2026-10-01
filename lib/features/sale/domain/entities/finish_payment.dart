/// One `Message` entry of a sale-engine answer (`MessageType`,
/// `MessageCode`, `MessageDesc`).
class SaleEngineMessage {
  final String type;
  final String code;
  final String desc;

  const SaleEngineMessage({
    required this.type,
    required this.code,
    required this.desc,
  });
}

/// A sale-engine answer read for its `isCompleted` and `Message` — what
/// legacy `validateGWP()` / `savePaymentV2()` branch on.
class SaleEngineAnswer {
  final bool completed;
  final List<SaleEngineMessage> messages;

  const SaleEngineAnswer({required this.completed, this.messages = const []});

  SaleEngineMessage? message(String code) {
    for (final m in messages) {
      if (m.code == code) return m;
    }
    return null;
  }
}

/// Legacy `OrderSignatureModel` sent with `FinishPaymentOrder`.
class OrderSignatureEntry {
  /// Legacy `OrderSignature.CODE_CUSTOMER`.
  static const customerCode = '1';

  /// Legacy `OrderSignature.CODE_PAID`.
  static const paidByCode = '2';

  final String code;

  /// The pad as a PNG data URL (legacy `SignaturePad.toDataURL()`).
  final String value;

  const OrderSignatureEntry({required this.code, required this.value});
}

/// Legacy `MessageErrorMode` codes the finish flow branches on.
abstract final class FinishMessageCode {
  static const gwpAuthorize = 'GWP_authorize';
  static const gwp = 'GWP';
  static const sessionExpire = 'SESSION_EXPIRE';
  static const earnError = 'EARN_ERROR';
}
