import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/currency.dart';
import 'package:kp_pos/features/sale/domain/entities/exchange_quote.dart';
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
  final ExchangeQuote Function(String code, double amount, double change)?
  exchangeQuote;
  final List<({String code, double amount, double change, bool button})>
  exchangeCalls = [];

  /// The order the sale engine returns after a cash tender of `amount`.
  final Cart Function(double amount)? paymentCartResult;
  final List<
    ({
      String orderGuid,
      String currency,
      double rate,
      double amount,
      double base,
    })
  >
  cashPayments = [];
  final List<({String currency, double amount})> changeExchanges = [];

  FakeSaleRepository({
    this.paymentCartResult,
    this.exchangeQuote,
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
  Future<Cart> addCashPayment({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double currencyRate,
    required double amount,
    required double baseAmount,
  }) async {
    cashPayments.add((
      orderGuid: orderGuid,
      currency: currencyCode,
      rate: currencyRate,
      amount: amount,
      base: baseAmount,
    ));
    if (mutationError != null) throw mutationError!;
    return paymentCartResult?.call(amount) ?? cartResult;
  }

  @override
  Future<Cart> saveChangeExchange({
    required String sessionKey,
    required String orderGuid,
    required String currencyCode,
    required double amount,
  }) async {
    changeExchanges.add((currency: currencyCode, amount: amount));
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  @override
  Future<ExchangeQuote> exchangeChange({
    required String currencyCode,
    required double currencyAmount,
    required double changeInBaht,
    required bool isChangeButton,
  }) async {
    exchangeCalls.add((
      code: currencyCode,
      amount: currencyAmount,
      change: changeInBaht,
      button: isChangeButton,
    ));
    if (currenciesError != null) throw currenciesError!;
    final quote = exchangeQuote;
    if (quote != null) return quote(currencyCode, currencyAmount, changeInBaht);
    return ExchangeQuote(
      currencyCode: currencyCode,
      rate: 1,
      currencyAmount: currencyAmount,
      currencyAmountInBaht: currencyAmount,
      localChange: changeInBaht - currencyAmount,
    );
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
