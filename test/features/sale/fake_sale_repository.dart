import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/currency.dart';
import 'package:kp_pos/features/sale/domain/entities/exchange_quote.dart';
import 'package:kp_pos/features/sale/domain/entities/promotion.dart';
import 'package:kp_pos/features/sale/domain/entities/sale_order_context.dart';
import 'package:kp_pos/features/sale/domain/repositories/sale_repository.dart';

/// Shared test double for [SaleRepository] — used wherever a test needs a
/// working article lookup/cart mutation flow without a real network call.
class FakeSaleRepository implements SaleRepository {
  final Article? lookupResult;
  final Object? lookupError;
  final Cart cartResult;
  Object? mutationError;

  String? lastLookupBarcode;
  String? lastAddedItemCode;
  List<String>? lastAddedRows;
  String? lastUpdatedRow;
  int? lastUpdatedQuantity;
  String? lastRemovedRow;
  SaleOrderContext? lastOrderContext;
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
    required String itemCode,
    List<String> rows = const [],
  }) async {
    lastAddedItemCode = itemCode;
    lastAddedRows = rows;
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

  List<Promotion> promotions = const [];
  String? lastPromotionQuery;
  bool? lastExcludeMember;
  Object? promotionError;
  final List<({List<String> rows, String action, String value})> lineActions =
      [];

  @override
  Future<List<Promotion>> listPromotions({
    required String query,
    required bool excludeMember,
  }) async {
    lastPromotionQuery = query;
    lastExcludeMember = excludeMember;
    return promotions
        .where((p) => p.code.toUpperCase().contains(query.toUpperCase()))
        .toList();
  }

  @override
  Future<Promotion?> findPromotion({
    required String sessionKey,
    required String code,
    required bool excludeMember,
  }) async {
    if (promotionError != null) throw promotionError!;
    lastExcludeMember = excludeMember;
    for (final p in promotions) {
      if (p.code == code) return p;
    }
    return null;
  }

  @override
  Future<Cart> actOnLines({
    required String sessionKey,
    required List<String> rows,
    required String action,
    required String value,
  }) async {
    lineActions.add((rows: rows, action: action, value: value));
    if (mutationError != null) throw mutationError!;
    return cartResult;
  }

  final List<String> savedOrders = [];
  Object? saveOrderError;
  int reverseVirtualStockCalls = 0;

  @override
  Future<Cart> saveOrder({
    required String sessionKey,
    required String shoppingCard,
  }) async {
    if (saveOrderError != null) throw saveOrderError!;
    savedOrders.add(shoppingCard);
    return cartResult;
  }

  @override
  Future<void> reverseVirtualStock({required String sessionKey}) async {
    reverseVirtualStockCalls++;
  }

  final List<({String card, String orderNo, String status})> orderStatuses = [];
  Object? orderStatusError;

  @override
  Future<void> updateOrderStatus({
    required String sessionKey,
    required String shoppingCard,
    required String orderNo,
    required String status,
  }) async {
    if (orderStatusError != null) throw orderStatusError!;
    orderStatuses.add((card: shoppingCard, orderNo: orderNo, status: status));
  }

  @override
  Future<Cart> getCart({
    required String sessionKey,
    required SaleOrderContext context,
  }) async {
    lastOrderContext = context;
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
