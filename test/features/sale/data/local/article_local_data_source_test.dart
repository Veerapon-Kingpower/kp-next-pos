import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/data/local/article_local_data_source.dart';
import 'package:kp_pos/features/sale/data/local/cached_article.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:realm/realm.dart';

void main() {
  late Realm realm;
  late RealmArticleLocalDataSource dataSource;

  setUp(() {
    // A fresh, uniquely-identified in-memory realm per test — no file I/O,
    // and no state leaks between tests.
    realm = Realm(
      Configuration.inMemory(
        [CachedArticle.schema],
        path: 'test-${DateTime.now().microsecondsSinceEpoch}.realm',
      ),
    );
    dataSource = RealmArticleLocalDataSource(realm: realm);
  });

  tearDown(() {
    realm.close();
  });

  test('getByBarcode returns null when nothing is cached', () {
    expect(dataSource.getByBarcode('8850012345678'), isNull);
  });

  test('upsert then getByBarcode returns the cached article, flagged as from cache', () {
    dataSource.upsert(
      barcode: '8850012345678',
      article: const Article(
        articleCode: 'ART001',
        articleName: 'Test Article',
        eanCode: '8850012345678',
        brandCode: 'B1',
        brandName: 'Brand One',
        price: 100,
        vatRate: 7,
      ),
    );

    final cached = dataSource.getByBarcode('8850012345678');

    expect(cached, isNotNull);
    expect(cached!.articleCode, 'ART001');
    expect(cached.brandName, 'Brand One');
    expect(cached.price, 100);
    expect(cached.isFromCache, isTrue);
  });

  test('upsert replaces an existing entry for the same barcode', () {
    dataSource.upsert(
      barcode: '8850012345678',
      article: const Article(
        articleCode: 'ART001',
        articleName: 'Old Name',
        eanCode: '8850012345678',
        brandCode: 'B1',
        brandName: 'Brand One',
        price: 100,
        vatRate: 7,
      ),
    );
    dataSource.upsert(
      barcode: '8850012345678',
      article: const Article(
        articleCode: 'ART001',
        articleName: 'New Name',
        eanCode: '8850012345678',
        brandCode: 'B1',
        brandName: 'Brand One',
        price: 120,
        vatRate: 7,
      ),
    );

    final cached = dataSource.getByBarcode('8850012345678');

    expect(cached!.articleName, 'New Name');
    expect(cached.price, 120);
  });
}
