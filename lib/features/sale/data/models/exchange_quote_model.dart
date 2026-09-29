import '../../domain/entities/exchange_quote.dart';

class ExchangeQuoteModel extends ExchangeQuote {
  const ExchangeQuoteModel({
    required super.currencyCode,
    required super.rate,
    required super.currencyAmount,
    required super.currencyAmountInBaht,
    required super.localChange,
  });

  factory ExchangeQuoteModel.fromJson(Map<String, dynamic> json) {
    double number(String key) => (json[key] as num?)?.toDouble() ?? 0;
    final code = json['CurrCode'];
    return ExchangeQuoteModel(
      currencyCode: code is Map<String, dynamic>
          ? code['Code'] as String? ?? ''
          : '',
      rate: number('CurrRate'),
      currencyAmount: number('CurrAmt'),
      currencyAmountInBaht: number('totalLocalChange'),
      localChange: number('totalChange'),
    );
  }
}
