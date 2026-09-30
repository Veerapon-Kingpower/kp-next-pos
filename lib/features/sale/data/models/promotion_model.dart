import '../../domain/entities/promotion.dart';

/// Legacy `PromotionViewModel` — snake_case keys, as the sale engine sends.
class PromotionModel extends Promotion {
  const PromotionModel({
    required super.code,
    required super.name,
    super.allowOverwrite,
    super.discountAmount,
    super.discountRate,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) => PromotionModel(
    code: json['promo_code'] as String? ?? '',
    name: json['promo_name'] as String? ?? '',
    allowOverwrite: json['allowOverWriteDISC'] as bool? ?? false,
    discountAmount: (json['discAmt'] as num?)?.toDouble() ?? 0,
    discountRate: (json['discRate'] as num?)?.toDouble() ?? 0,
  );
}
