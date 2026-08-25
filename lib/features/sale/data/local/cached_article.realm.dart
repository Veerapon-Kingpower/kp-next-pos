// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_article.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class CachedArticle extends _CachedArticle
    with RealmEntity, RealmObjectBase, RealmObject {
  CachedArticle(
    String barcode,
    String articleCode,
    String articleName,
    String brandCode,
    String brandName,
    double price,
    double vatRate,
    DateTime cachedAt,
  ) {
    RealmObjectBase.set(this, 'barcode', barcode);
    RealmObjectBase.set(this, 'articleCode', articleCode);
    RealmObjectBase.set(this, 'articleName', articleName);
    RealmObjectBase.set(this, 'brandCode', brandCode);
    RealmObjectBase.set(this, 'brandName', brandName);
    RealmObjectBase.set(this, 'price', price);
    RealmObjectBase.set(this, 'vatRate', vatRate);
    RealmObjectBase.set(this, 'cachedAt', cachedAt);
  }

  CachedArticle._();

  @override
  String get barcode => RealmObjectBase.get<String>(this, 'barcode') as String;
  @override
  set barcode(String value) => RealmObjectBase.set(this, 'barcode', value);

  @override
  String get articleCode =>
      RealmObjectBase.get<String>(this, 'articleCode') as String;
  @override
  set articleCode(String value) =>
      RealmObjectBase.set(this, 'articleCode', value);

  @override
  String get articleName =>
      RealmObjectBase.get<String>(this, 'articleName') as String;
  @override
  set articleName(String value) =>
      RealmObjectBase.set(this, 'articleName', value);

  @override
  String get brandCode =>
      RealmObjectBase.get<String>(this, 'brandCode') as String;
  @override
  set brandCode(String value) => RealmObjectBase.set(this, 'brandCode', value);

  @override
  String get brandName =>
      RealmObjectBase.get<String>(this, 'brandName') as String;
  @override
  set brandName(String value) => RealmObjectBase.set(this, 'brandName', value);

  @override
  double get price => RealmObjectBase.get<double>(this, 'price') as double;
  @override
  set price(double value) => RealmObjectBase.set(this, 'price', value);

  @override
  double get vatRate => RealmObjectBase.get<double>(this, 'vatRate') as double;
  @override
  set vatRate(double value) => RealmObjectBase.set(this, 'vatRate', value);

  @override
  DateTime get cachedAt =>
      RealmObjectBase.get<DateTime>(this, 'cachedAt') as DateTime;
  @override
  set cachedAt(DateTime value) => RealmObjectBase.set(this, 'cachedAt', value);

  @override
  Stream<RealmObjectChanges<CachedArticle>> get changes =>
      RealmObjectBase.getChanges<CachedArticle>(this);

  @override
  Stream<RealmObjectChanges<CachedArticle>> changesFor([
    List<String>? keyPaths,
  ]) => RealmObjectBase.getChangesFor<CachedArticle>(this, keyPaths);

  @override
  CachedArticle freeze() => RealmObjectBase.freezeObject<CachedArticle>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'barcode': barcode.toEJson(),
      'articleCode': articleCode.toEJson(),
      'articleName': articleName.toEJson(),
      'brandCode': brandCode.toEJson(),
      'brandName': brandName.toEJson(),
      'price': price.toEJson(),
      'vatRate': vatRate.toEJson(),
      'cachedAt': cachedAt.toEJson(),
    };
  }

  static EJsonValue _toEJson(CachedArticle value) => value.toEJson();
  static CachedArticle _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'barcode': EJsonValue barcode,
        'articleCode': EJsonValue articleCode,
        'articleName': EJsonValue articleName,
        'brandCode': EJsonValue brandCode,
        'brandName': EJsonValue brandName,
        'price': EJsonValue price,
        'vatRate': EJsonValue vatRate,
        'cachedAt': EJsonValue cachedAt,
      } =>
        CachedArticle(
          fromEJson(barcode),
          fromEJson(articleCode),
          fromEJson(articleName),
          fromEJson(brandCode),
          fromEJson(brandName),
          fromEJson(price),
          fromEJson(vatRate),
          fromEJson(cachedAt),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(CachedArticle._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(
      ObjectType.realmObject,
      CachedArticle,
      'CachedArticle',
      [
        SchemaProperty('barcode', RealmPropertyType.string, primaryKey: true),
        SchemaProperty('articleCode', RealmPropertyType.string),
        SchemaProperty('articleName', RealmPropertyType.string),
        SchemaProperty('brandCode', RealmPropertyType.string),
        SchemaProperty('brandName', RealmPropertyType.string),
        SchemaProperty('price', RealmPropertyType.double),
        SchemaProperty('vatRate', RealmPropertyType.double),
        SchemaProperty('cachedAt', RealmPropertyType.timestamp),
      ],
    );
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
