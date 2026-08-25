/// Field-for-field port of the documented `GetMasterByBarcodeDLL` response
/// fields (`api-contracts.md` section 5b, op 47): `Data.Article.{ArticleCode,
/// ArticleName, EANCode, Brand:{Code,Name}, VatRate, Price}`. `MCDetail`,
/// `VASs`, and `Promotions` are named in the same response but not
/// field-documented beyond their own name, and nothing in this task needs
/// them, so they are omitted rather than guessed at.
class Article {
  final String articleCode;
  final String articleName;
  final String eanCode;
  final String brandCode;
  final String brandName;
  final double price;
  final double vatRate;

  /// When set, this result was served from the local offline cache (see
  /// `openspec/changes/add-offline-article-cache/design.md`) rather than
  /// confirmed against the network just now, and [cachedAt] records when it
  /// was last confirmed. `null` for an ordinary, freshly-looked-up result.
  final DateTime? cachedAt;

  bool get isFromCache => cachedAt != null;

  const Article({
    required this.articleCode,
    required this.articleName,
    required this.eanCode,
    required this.brandCode,
    required this.brandName,
    required this.price,
    required this.vatRate,
    this.cachedAt,
  });
}
