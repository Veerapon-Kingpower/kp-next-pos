import '../../domain/entities/currency.dart';

class CurrencyModel extends Currency {
  const CurrencyModel({
    required super.code,
    required super.description,
    required super.rate,
    super.symbol,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) => CurrencyModel(
    code: json['curr_code'] as String? ?? '',
    description: json['curr_desc'] as String? ?? '',
    rate: (json['curr_rate'] as num?)?.toDouble() ?? 0,
    symbol: json['curr_short'] as String? ?? '',
  );
}
