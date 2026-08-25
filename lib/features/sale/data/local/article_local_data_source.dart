import 'package:realm/realm.dart';

import '../../domain/entities/article.dart';
import 'cached_article.dart';

/// Local, read-through cache for article/barcode lookups — see
/// `openspec/changes/add-offline-article-cache/design.md`. Written to only
/// from a successful network lookup (see `SaleRepositoryImpl`); never
/// written back to the server. Abstracted so most tests use a fake rather
/// than a real Realm, mirroring this codebase's existing `ApiClient`
/// pattern.
abstract class ArticleLocalDataSource {
  /// Returns the cached article for [barcode], with [Article.cachedAt] set
  /// to when it was cached, or `null` if nothing is cached for it.
  Article? getByBarcode(String barcode);

  /// Inserts or replaces the cached entry for [barcode] with [article]'s
  /// current data, timestamped now.
  void upsert({required String barcode, required Article article});
}

class RealmArticleLocalDataSource implements ArticleLocalDataSource {
  final Realm _realm;

  RealmArticleLocalDataSource({Realm? realm})
    : _realm = realm ?? Realm(Configuration.local([CachedArticle.schema]));

  @override
  Article? getByBarcode(String barcode) {
    final cached = _realm.find<CachedArticle>(barcode);
    if (cached == null) return null;
    return Article(
      articleCode: cached.articleCode,
      articleName: cached.articleName,
      eanCode: barcode,
      brandCode: cached.brandCode,
      brandName: cached.brandName,
      price: cached.price,
      vatRate: cached.vatRate,
      cachedAt: cached.cachedAt,
    );
  }

  @override
  void upsert({required String barcode, required Article article}) {
    _realm.write(() {
      _realm.add(
        CachedArticle(
          barcode,
          article.articleCode,
          article.articleName,
          article.brandCode,
          article.brandName,
          article.price,
          article.vatRate,
          DateTime.now().toUtc(),
        ),
        update: true,
      );
    });
  }
}
