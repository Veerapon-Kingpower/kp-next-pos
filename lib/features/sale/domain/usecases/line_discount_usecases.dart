import '../entities/cart.dart';
import '../entities/promotion.dart';
import '../repositories/sale_repository.dart';

/// Legacy `ActionToOrderCommand` values the Discount page sends.
abstract final class LineDiscountAction {
  static const add = 'add_item_discount';
  static const update = 'update_item_discount';
  static const remove = 'clear_item_discount';
  static const clearAll = 'clear_discount_all';
  static const addByQrCode = 'add_item_discount_by_qrcode';
}

/// Legacy `ActionToOrderCommand` values the Checkout → Discount page
/// (`SpecialDiscountPage`) sends for the bill (special) discount.
abstract final class BillDiscountAction {
  static const add = 'add_special_discount';
  static const update = 'update_special_discount';
  static const remove = 'clear_special_discount';
  static const clearAll = 'clear_all_special_discount';
  static const addByQrCode = 'add_special_discount_by_qrcode';
}

class ListPromotionsUseCase {
  final SaleRepository _repository;

  const ListPromotionsUseCase(this._repository);

  Future<List<Promotion>> call({
    required String query,
    required bool excludeMember,
  }) => _repository.listPromotions(query: query, excludeMember: excludeMember);
}

class FindPromotionUseCase {
  final SaleRepository _repository;

  const FindPromotionUseCase(this._repository);

  Future<Promotion?> call({
    required String sessionKey,
    required String code,
    required bool excludeMember,
  }) => _repository.findPromotion(
    sessionKey: sessionKey,
    code: code,
    excludeMember: excludeMember,
  );
}

class ActOnLinesUseCase {
  final SaleRepository _repository;

  const ActOnLinesUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required List<String> rows,
    required String action,
    required String value,
  }) => _repository.actOnLines(
    sessionKey: sessionKey,
    rows: rows,
    action: action,
    value: value,
  );
}

class ActOnOrderUseCase {
  final SaleRepository _repository;

  const ActOnOrderUseCase(this._repository);

  Future<Cart> call({
    required String sessionKey,
    required String action,
    required String value,
    String? orderGuid,
  }) => _repository.actOnOrder(
    sessionKey: sessionKey,
    action: action,
    value: value,
    orderGuid: orderGuid,
  );
}
