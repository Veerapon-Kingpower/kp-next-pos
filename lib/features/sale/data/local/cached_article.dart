import 'package:realm/realm.dart';

part 'cached_article.realm.dart';

/// Local, on-device cache of an article/barcode lookup result — see
/// `openspec/changes/add-offline-article-cache/design.md`. Keyed by
/// `barcode` (the scanned/EAN code), matching how a cashier actually has
/// the value in hand, not the backend's internal `articleCode`. Populated
/// only from successful network lookups; never written to from anywhere
/// else, and never written back to the server.
@RealmModel()
class _CachedArticle {
  @PrimaryKey()
  late String barcode;
  late String articleCode;
  late String articleName;
  late String brandCode;
  late String brandName;
  late double price;
  late double vatRate;
  late DateTime cachedAt;
}
