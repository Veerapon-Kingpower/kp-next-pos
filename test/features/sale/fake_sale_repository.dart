import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/currency.dart';
import 'package:kp_pos/features/sale/domain/repositories/sale_repository.dart';

/// Shared test double for [SaleRepository] — used wherever a test needs a
/// working article lookup/cart mutation flow without a real network call.
class FakeSaleRepository implements SaleRepository {
  final Article? lookupResult;
  final Object? lookupError;
  final Cart cartResult;
  final Object? mutationError;

  String? lastLookupBarcode;
  String? lastAddedArticleCode;
  int? lastAddedQuantity;
  String? lastUpdatedRow;
  int? lastUpdatedQuantity;
  String? lastRemovedRow;
  final List<Currency> currencies;
  final Object? currenciesError;
  final Cart? currencyCartResult;
  String? lastCurrencyShoppingCard;
  String? lastCurrencyCode;

  FakeSaleRepository({
    this.lookupResult,
    this.lookupError,
    this.cartResult = const Cart(guid: '', isCheckOut: false, items: []),
    this.mutationError,
    this.currencies = const [],
    this.currenciesError,
    this.currencyCartResult,
  });

  @override
  Future<Article> lookupArticleByBarcode(String barcode) async {
    lastLookupBarcode = barcode;
    if (lookupError != null) throw lookupError!;
    return lookupResult ??
        const Article(
          articleCode: 'ART001',
          articleName: 'Test Article',
          eanCode: '8850012345678',
          brandCode: 'B1',
          brandName: 'Brand One',
          price: 100,
          vatRate: 7,
        );
  }

  @override
  Future<Cart> addItemToCart({
    required String sessionKey,
    required String articleCode,
    required int quantity,
  }) async {
    lastAddedArticleCode = articleCode;
    lastAddedQuantity = quantity;
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  @override
  Future<Cart> updateCartItemQuantity({
    required String sessionKey,
    required String row,
    required int quantity,
  }) async {
    lastUpdatedRow = row;
    lastUpdatedQuantity = quantity;
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  @override
  Future<Cart> removeCartItem({
    required String sessionKey,
    required String row,
  }) async {
    lastRemovedRow = row;
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  @override
  Future<Cart> getCart({
    required String sessionKey,
    required String shoppingCard,
  }) async {
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  @override
  Future<List<Currency>> listCurrencies() async {
    if (currenciesError != null) throw currenciesError!;
    return currencies;
  }

  @override
  Future<Cart> changeOrderCurrency({
    required String sessionKey,
    required String shoppingCard,
    required String currencyCode,
  }) async {
    lastCurrencyShoppingCard = shoppingCard;
    lastCurrencyCode = currencyCode;
    if (mutationError != null) throw mutationError!;
    return currencyCartResult ?? cartResult;
  }
}
