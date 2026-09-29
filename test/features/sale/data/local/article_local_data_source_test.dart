import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/data/local/article_local_data_source.dart';
import 'package:kp_pos/features/sale/data/local/cached_article.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:realm/realm.dart';

void main() {
  late Directory dir;
  late Realm realm;
  late RealmArticleLocalDataSource dataSource;

  setUp(() {
    // A fresh in-memory realm per test, so no state leaks between tests.
    // Realm still writes a `.lock` (and `.note`) file beside the path even
    // for in-memory realms, so the path lives in a temp directory that is
    // deleted afterwards rather than in the project root.
    dir = Directory.systemTemp.createTempSync('kp_pos_realm_test_');
    realm = Realm(
      Configuration.inMemory([
        CachedArticle.schema,
      ], path: '${dir.path}${Platform.pathSeparator}test.realm'),
    );
    dataSource = RealmArticleLocalDataSource(realm: realm);
  });

  tearDown(() {
    realm.close();
    dir.deleteSync(recursive: true);
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
