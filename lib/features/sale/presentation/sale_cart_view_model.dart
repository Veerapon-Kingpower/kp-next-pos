import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../../auth/domain/usecases/restore_session_usecase.dart';
import '../../customer/domain/entities/privilege.dart';
import '../domain/barcode_scan_input.dart';
import '../domain/entities/cart.dart';
import '../domain/entities/currency.dart';
import '../domain/entities/exchange_quote.dart';
import '../domain/usecases/add_item_to_cart_usecase.dart';
import '../domain/usecases/cash_payment_usecases.dart';
import '../domain/usecases/change_order_currency_usecase.dart';
import '../domain/usecases/exchange_change_usecase.dart';
import '../domain/usecases/list_currencies_usecase.dart';
import '../domain/usecases/lookup_article_by_barcode_usecase.dart';
import '../domain/usecases/remove_cart_item_usecase.dart';
import '../domain/usecases/update_cart_item_quantity_usecase.dart';

/// Sale cart state: scan-to-add (with `qty*barcode` parsing and format
/// validation), quantity adjustment, and removal. Sale creation, full
/// totals, currency, and change calculation are task 4.4's scope, not this
/// controller's.
class SaleCartViewModel extends GetxController {
  final RestoreSessionUseCase _restoreSession;
  final LookupArticleByBarcodeUseCase _lookupArticle;
  final AddItemToCartUseCase _addItemToCart;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantity;
  final RemoveCartItemUseCase _removeCartItem;

  final ListCurrenciesUseCase _listCurrencies;
  final ChangeOrderCurrencyUseCase _changeOrderCurrency;
  final ExchangeChangeUseCase _exchangeChange;
  final AddCashPaymentUseCase _addCashPayment;
  final SaveChangeExchangeUseCase _saveChangeExchange;

  SaleCartViewModel({
    required RestoreSessionUseCase restoreSession,
    required LookupArticleByBarcodeUseCase lookupArticle,
    required AddItemToCartUseCase addItemToCart,
    required UpdateCartItemQuantityUseCase updateCartItemQuantity,
    required RemoveCartItemUseCase removeCartItem,
    required ListCurrenciesUseCase listCurrencies,
    required ChangeOrderCurrencyUseCase changeOrderCurrency,
    required ExchangeChangeUseCase exchangeChange,
    required AddCashPaymentUseCase addCashPayment,
    required SaveChangeExchangeUseCase saveChangeExchange,
  }) : _restoreSession = restoreSession,
       _lookupArticle = lookupArticle,
       _addItemToCart = addItemToCart,
       _updateCartItemQuantity = updateCartItemQuantity,
       _removeCartItem = removeCartItem,
       _listCurrencies = listCurrencies,
       _changeOrderCurrency = changeOrderCurrency,
       _exchangeChange = exchangeChange,
       _addCashPayment = addCashPayment,
       _saveChangeExchange = saveChangeExchange;

  /// Why the last cash tender or change save failed, if it did.
  String? paymentError;

  /// Records [amount] of cash (in the order's currency) on the order —
  /// legacy `PaymentFormPage` Save for cash. The returned order carries the
  /// tender, the remaining balance and any change due.
  Future<bool> payCash(double amount) async {
    paymentError = null;
    final order = cart;
    if (order == null || order.guid.isEmpty) {
      paymentError = 'There is no order to pay.';
      update();
      return false;
    }
    if (amount <= 0) {
      paymentError = 'Enter the cash received.';
      update();
      return false;
    }
    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      paymentError = 'No active session.';
      update();
      return false;
    }
    final billing = order.billing;
    final foreign =
        billing != null && !billing.isBaht && billing.currencyRate > 0;
    final rate = foreign ? billing.currencyRate : 1.0;
    isBusy = true;
    update();
    try {
      cart = await _addCashPayment(
        sessionKey: sessionKey,
        orderGuid: order.guid,
        currencyCode: foreign ? billing.currencyCode : 'THB',
        currencyRate: rate,
        amount: amount,
        baseAmount: amount * rate,
      );
    } on ApiException catch (e) {
      paymentError = e.messageDesc;
    }
    isBusy = false;
    update();
    return paymentError == null;
  }

  /// Legacy `ChangePage.onSave()`: [amount] of the order's change handed
  /// back in [currencyCode] (`edit_exchange`).
  Future<bool> saveChangeExchange({
    required String currencyCode,
    required double amount,
  }) async {
    paymentError = null;
    final order = cart;
    final sessionKey = await _sessionKey();
    if (order == null || order.guid.isEmpty || sessionKey == null) {
      paymentError = 'There is no order to save the change on.';
      update();
      return false;
    }
    isBusy = true;
    update();
    try {
      cart = await _saveChangeExchange(
        sessionKey: sessionKey,
        orderGuid: order.guid,
        currencyCode: currencyCode,
        amount: amount,
      );
    } on ApiException catch (e) {
      paymentError = e.messageDesc;
    }
    isBusy = false;
    update();
    return paymentError == null;
  }

  Cart? cart;
  bool isBusy = false;
  String? scanError;

  /// The attached customer's shopping card — legacy's Sale page always
  /// runs against one and sends it as `Row` on `change_currency`.
  String shoppingCard = '';

  void attachShoppingCard(String card) {
    shoppingCard = card;
    update();
  }

  /// Why the last currency change failed, if it did.
  String? currencyError;

  /// Legacy `AuthorizeCode.ChangeCurrency`.
  static const changeCurrencyAuthCode = 'actCurrency';
  static const noCurrencyPermission = "Sorry, you don't have permission.";

  /// The branch rate table for the currency picker.
  Future<List<Currency>> listCurrencies() => _listCurrencies();

  /// Legacy `ChangePage`: quotes [changeInBaht] of change in
  /// [currencyCode] (`SaleEngine/ExchangeCurrency`). Calculation only.
  Future<ExchangeQuote> exchangeChange({
    required String currencyCode,
    required double currencyAmount,
    required double changeInBaht,
    required bool isChangeButton,
  }) => _exchangeChange(
    currencyCode: currencyCode,
    currencyAmount: currencyAmount,
    changeInBaht: changeInBaht,
    isChangeButton: isChangeButton,
  );

  /// Legacy `SalePage.changeCurrency()`'s gate, checked before the picker
  /// opens.
  Future<bool> canChangeCurrency() async {
    final session = await _restoreSession();
    return session?.hasAuthCode(changeCurrencyAuthCode) ?? false;
  }

  /// Ports `CurrencyPickerPage.onChange()`: the sale engine recalculates
  /// the whole order in [currencyCode] and returns it.
  Future<bool> changeCurrency(String currencyCode) async {
    currencyError = null;
    final session = await _restoreSession();
    if (session == null) {
      currencyError = 'No active session.';
      update();
      return false;
    }
    if (!session.hasAuthCode(changeCurrencyAuthCode)) {
      currencyError = noCurrencyPermission;
      update();
      return false;
    }
    if (shoppingCard.isEmpty) {
      currencyError = 'Attach a customer before changing the currency.';
      update();
      return false;
    }
    isBusy = true;
    update();
    try {
      cart = await _changeOrderCurrency(
        sessionKey: session.sessionKey,
        shoppingCard: shoppingCard,
        currencyCode: currencyCode,
      );
    } on ApiException catch (e) {
      currencyError = e.messageDesc;
    }
    isBusy = false;
    update();
    return currencyError == null;
  }

  /// The privilege chosen on the Customers tab before switching here, if
  /// the customer has any (see `HomePage._goToSale`'s picker). Client-side
  /// only — there's no discount-calculation or backend privilege API wired
  /// into the cart yet, so this is purely informational for now.
  Privilege? selectedPrivilege;

  void selectPrivilege(Privilege? privilege) {
    selectedPrivilege = privilege;
    update();
  }

  /// Set when the most recent scan's article came from the offline cache
  /// (see openspec/changes/add-offline-article-cache) rather than a fresh
  /// network lookup, so the cashier knows the price may not be current.
  String? staleNotice;

  Future<void> scan(String rawInput) async {
    scanError = null;
    staleNotice = null;

    final ParsedBarcodeScan parsed;
    try {
      parsed = parseBarcodeScan(rawInput);
    } on BarcodeScanFormatException catch (e) {
      scanError = e.message;
      update();
      return;
    }

    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      scanError = 'No active session.';
      update();
      return;
    }

    isBusy = true;
    update();
    try {
      final article = await _lookupArticle(parsed.barcode);
      if (article.isFromCache) {
        staleNotice =
            'Price may be outdated — cached ${_formatCachedAt(article.cachedAt!)}';
      }
      cart = await _addItemToCart(
        sessionKey: sessionKey,
        articleCode: article.articleCode,
        quantity: parsed.quantity,
      );
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<void> updateQuantity({
    required String row,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      await removeItem(row);
      return;
    }
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return;

    isBusy = true;
    update();
    try {
      cart = await _updateCartItemQuantity(
        sessionKey: sessionKey,
        row: row,
        quantity: quantity,
      );
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<void> removeItem(String row) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return;

    isBusy = true;
    update();
    try {
      cart = await _removeCartItem(sessionKey: sessionKey, row: row);
    } on ApiException catch (e) {
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<String?> _sessionKey() async {
    final session = await _restoreSession();
    return session?.sessionKey;
  }

  static String _formatCachedAt(DateTime cachedAt) {
    final local = cachedAt.toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${pad(local.month)}-${pad(local.day)} '
        '${pad(local.hour)}:${pad(local.minute)}';
  }
}
