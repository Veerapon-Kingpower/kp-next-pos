import '../error/app_exception.dart';

/// The response envelope used by nearly every Sale Engine / Register /
/// Flight / Cash Card call (see `api-contracts.md` section 3):
/// `{ isCompleted, Data, Message: [{MessageType,MessageCode,MessageDesc}],
/// totalCount }`. Every feature's remote data source decodes its own `Data`
/// shape via [fromDataJson], then calls [unwrap] to apply the standard
/// success/failure branch instead of re-implementing it per call.
class ReturnObject<T> {
  final bool isCompleted;
  final T? data;
  final List<ReturnMessage> messages;
  final int? totalCount;

  const ReturnObject({
    required this.isCompleted,
    required this.data,
    required this.messages,
    this.totalCount,
  });

  factory ReturnObject.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromDataJson,
  ) {
    return ReturnObject(
      isCompleted: json['isCompleted'] as bool? ?? false,
      data: json['Data'] == null ? null : fromDataJson(json['Data']),
      messages: (json['Message'] as List<dynamic>? ?? const [])
          .map((m) => ReturnMessage.fromJson(m as Map<String, dynamic>))
          .toList(growable: false),
      totalCount: json['totalCount'] as int?,
    );
  }

  /// Applies the standard idiom confirmed across the legacy client
  /// (`checkout.ts`, `voucher.ts`, ...): `isCompleted && data != null` is
  /// success; otherwise throw with the first message, or a generic
  /// [ApiException] if the server sent no message at all.
  T unwrap() {
    if (isCompleted && data != null) return data as T;
    if (messages.isNotEmpty) {
      return throw ApiException(
        messageDesc: messages.first.messageDesc,
        messageCode: messages.first.messageCode,
      );
    }
    throw const ApiException(messageDesc: 'The request did not complete.');
  }
}

class ReturnMessage {
  final String messageType;
  final String messageCode;
  final String messageDesc;

  const ReturnMessage({
    required this.messageType,
    required this.messageCode,
    required this.messageDesc,
  });

  factory ReturnMessage.fromJson(Map<String, dynamic> json) => ReturnMessage(
    messageType: json['MessageType'] as String? ?? '',
    messageCode: json['MessageCode'] as String? ?? '',
    messageDesc: json['MessageDesc'] as String? ?? '',
  );
}
