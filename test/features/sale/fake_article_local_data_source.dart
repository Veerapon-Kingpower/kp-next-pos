import 'package:kp_pos/features/sale/data/local/article_local_data_source.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';

/// Shared in-memory test double for [ArticleLocalDataSource] — no real
/// Realm involved, used wherever a test needs to control what the local
/// cache does/doesn't have without touching the filesystem.
class FakeArticleLocalDataSource implements ArticleLocalDataSource {
  final Map<String, Article> _cache = {};

  @override
  Article? getByBarcode(String barcode) => _cache[barcode];

  @override
  void upsert({required String barcode, required Article article}) {
    _cache[barcode] = Article(
      articleCode: article.articleCode,
      articleName: article.articleName,
      eanCode: article.eanCode,
      brandCode: article.brandCode,
      brandName: article.brandName,
      price: article.price,
      vatRate: article.vatRate,
      cachedAt: DateTime.now().toUtc(),
    );
  }
}
