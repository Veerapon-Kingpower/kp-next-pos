import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.articleCode,
    required super.articleName,
    required super.eanCode,
    required super.brandCode,
    required super.brandName,
    required super.price,
    required super.vatRate,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final brand = json['Brand'] as Map<String, dynamic>? ?? const {};
    return ArticleModel(
      articleCode: json['ArticleCode'] as String? ?? '',
      articleName: json['ArticleName'] as String? ?? '',
      eanCode: json['EANCode'] as String? ?? '',
      brandCode: brand['Code'] as String? ?? '',
      brandName: brand['Name'] as String? ?? '',
      price: (json['Price'] as num?)?.toDouble() ?? 0,
      vatRate: (json['VatRate'] as num?)?.toDouble() ?? 0,
    );
  }
}
