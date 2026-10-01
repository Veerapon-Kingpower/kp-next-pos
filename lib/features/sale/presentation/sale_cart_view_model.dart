import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/usecases/restore_session_usecase.dart';
import '../../auth/domain/entities/user_session.dart';
import '../../customer/domain/entities/customer.dart';
import '../../customer/domain/entities/privilege.dart';
import '../domain/entities/cart.dart';
import '../domain/entities/cart_item.dart';
import '../domain/entities/currency.dart';
import '../domain/entities/exchange_quote.dart';
import '../domain/entities/line_discount.dart';
import '../domain/entities/line_edit.dart';
import '../domain/entities/order_status.dart';
import '../domain/entities/promotion.dart';
import '../domain/entities/sale_order_context.dart';
import '../domain/usecases/add_item_to_cart_usecase.dart';
import '../domain/usecases/cash_payment_usecases.dart';
import '../domain/usecases/change_order_currency_usecase.dart';
import '../domain/usecases/edit_cart_item_usecase.dart';
import '../domain/usecases/exchange_change_usecase.dart';
import '../domain/usecases/get_cart_usecase.dart';
import '../domain/usecases/leave_sale_usecases.dart';
import '../domain/usecases/line_discount_usecases.dart';
import '../domain/usecases/list_currencies_usecase.dart';
import '../domain/usecases/remove_cart_item_usecase.dart';
import '../domain/usecases/update_cart_item_quantity_usecase.dart';
import '../domain/usecases/update_order_status_usecase.dart';
import '../domain/entities/finish_payment.dart';
import '../domain/usecases/finish_payment_usecase.dart';
import 'handheld/payment/signature_page.dart'
    show SignatureCapture, SignatureStrokes, signatureToDataUrl;
import 'sale_currency.dart' show orderNetPay;

/// What legacy `goCheckout()` finds before Checkout: no signed-in user
/// ("Something went wrong"), a Sale-only machine or no `actCashier` ("you
/// don't have permission"), a member without a privilege (asks to
/// continue), or ready.
enum CheckoutGate { noSession, noPermission, noPrivilege, ready }

/// Sale cart state: opening the customer's order, scan-to-add, quantity
/// adjustment, removal, currency and cash payment.
class SaleCartViewModel extends GetxController {
  final RestoreSessionUseCase _restoreSession;
  final GetCartUseCase _getCart;
  final UpdateOrderStatusUseCase _updateOrderStatus;
  final SaveOrderUseCase _saveOrder;
  final ReverseVirtualStockUseCase _reverseVirtualStock;
  final ListPromotionsUseCase _listPromotions;
  final FindPromotionUseCase _findPromotion;
  final ActOnLinesUseCase _actOnLines;
  final ActOnOrderUseCase _actOnOrder;
  final AddItemToCartUseCase _addItemToCart;
  final UpdateCartItemQuantityUseCase _updateCartItemQuantity;
  final EditCartItemUseCase _editCartItem;
  final LookupSerialUseCase _lookupSerial;
  final RemoveCartItemUseCase _removeCartItem;

  final ListCurrenciesUseCase _listCurrencies;
  final ChangeOrderCurrencyUseCase _changeOrderCurrency;
  final ExchangeChangeUseCase _exchangeChange;
  final AddCashPaymentUseCase _addCashPayment;
  final SaveChangeExchangeUseCase _saveChangeExchange;
  final FinishPaymentUseCase _finishPayment;

  /// Turns a pad into the PNG data URL `FinishPaymentOrder` takes —
  /// replaceable in tests, where real image encoding can't run.
  Future<String> Function(SignatureStrokes strokes) encodeSignature =
      signatureToDataUrl;

  SaleCartViewModel({
    required RestoreSessionUseCase restoreSession,
    required GetCartUseCase getCart,
    required UpdateOrderStatusUseCase updateOrderStatus,
    required SaveOrderUseCase saveOrder,
    required ReverseVirtualStockUseCase reverseVirtualStock,
    required ListPromotionsUseCase listPromotions,
    required FindPromotionUseCase findPromotion,
    required ActOnLinesUseCase actOnLines,
    required ActOnOrderUseCase actOnOrder,
    required AddItemToCartUseCase addItemToCart,
    required UpdateCartItemQuantityUseCase updateCartItemQuantity,
    required EditCartItemUseCase editCartItem,
    required LookupSerialUseCase lookupSerial,
    required RemoveCartItemUseCase removeCartItem,
    required ListCurrenciesUseCase listCurrencies,
    required ChangeOrderCurrencyUseCase changeOrderCurrency,
    required ExchangeChangeUseCase exchangeChange,
    required AddCashPaymentUseCase addCashPayment,
    required SaveChangeExchangeUseCase saveChangeExchange,
    required FinishPaymentUseCase finishPayment,
  }) : _restoreSession = restoreSession,
       _getCart = getCart,
       _updateOrderStatus = updateOrderStatus,
       _saveOrder = saveOrder,
       _reverseVirtualStock = reverseVirtualStock,
       _listPromotions = listPromotions,
       _findPromotion = findPromotion,
       _actOnLines = actOnLines,
       _actOnOrder = actOnOrder,
       _addItemToCart = addItemToCart,
       _updateCartItemQuantity = updateCartItemQuantity,
       _editCartItem = editCartItem,
       _lookupSerial = lookupSerial,
       _removeCartItem = removeCartItem,
       _listCurrencies = listCurrencies,
       _changeOrderCurrency = changeOrderCurrency,
       _exchangeChange = exchangeChange,
       _addCashPayment = addCashPayment,
       _saveChangeExchange = saveChangeExchange,
       _finishPayment = finishPayment;

  /// Legacy `validateGWP()`'s call. Null when the sale engine can't be
  /// reached (no network / timeout); a server error comes back as an
  /// incomplete answer carrying its message.
  Future<SaleEngineAnswer?> validateGwp() => _finishCall(
    (sessionKey, guid) =>
        _finishPayment.validateGwp(sessionKey: sessionKey, orderGuid: guid),
  );

  /// Legacy `finishOrder()`: `FinishPaymentOrder` with the signatures as
  /// PNG data URLs — the customer's (`1`) and, when drawn, the paid-by
  /// (`2`) — for an order that requires them, else null. Null when the
  /// sale engine can't be reached.
  Future<SaleEngineAnswer?> finishPaymentOrder() async {
    List<OrderSignatureEntry>? signatures;
    final capture = signature;
    if ((cart?.requireSignature ?? false) && capture != null) {
      signatures = [
        OrderSignatureEntry(
          code: OrderSignatureEntry.customerCode,
          value: await encodeSignature(capture.customer),
        ),
        if (capture.paidBy.isNotEmpty)
          OrderSignatureEntry(
            code: OrderSignatureEntry.paidByCode,
            value: await encodeSignature(capture.paidBy),
          ),
      ];
    }
    return _finishCall(
      (sessionKey, guid) => _finishPayment.finish(
        sessionKey: sessionKey,
        orderGuid: guid,
        signatures: signatures,
      ),
    );
  }

  Future<SaleEngineAnswer?> _finishCall(
    Future<SaleEngineAnswer> Function(String sessionKey, String orderGuid) call,
  ) async {
    final sessionKey = await _sessionKey();
    final guid = cart?.guid ?? '';
    if (sessionKey == null || guid.isEmpty) {
      return const SaleEngineAnswer(
        completed: false,
        messages: [
          SaleEngineMessage(type: 'Error', code: '', desc: 'No active order.'),
        ],
      );
    }
    isBusy = true;
    update();
    SaleEngineAnswer? answer;
    try {
      answer = await call(sessionKey, guid);
    } on ApiException catch (e) {
      // Complete sale handles SESSION_EXPIRE itself (legacy savePaymentV2).
      final failure = mapExceptionToFailure(e);
      answer = failure is NetworkFailure || failure is TimeoutFailure
          ? null
          : SaleEngineAnswer(
              completed: false,
              messages: [
                SaleEngineMessage(
                  type: 'Error',
                  code: e.messageCode ?? '',
                  desc: e.messageDesc,
                ),
              ],
            );
    }
    isBusy = false;
    update();
    return answer;
  }

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
      _noteExpiry(e);
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
      _noteExpiry(e);
      paymentError = e.messageDesc;
    }
    isBusy = false;
    update();
    return paymentError == null;
  }

  /// The order as the sale engine last returned it. Replacing it drops the
  /// line selection, as legacy's re-rendered `OrderDetails` do.
  Cart? get cart => _cart;
  set cart(Cart? value) {
    _cart = value;
    _selected.clear();
  }

  Cart? _cart;

  // Legacy `OrderDetail.isSelected`, by line Guid.
  final Set<String> _selected = {};

  bool isSelected(String row) => _selected.contains(row);

  /// The selected lines, in order — legacy filters them by the tab shown
  /// (`IsBasket`).
  List<CartItem> selectedLines({required bool basket}) => [
    for (final line in _cart?.items ?? const <CartItem>[])
      if (line.isBasket == basket && _selected.contains(line.row)) line,
  ];

  /// Legacy's two tabs: Buying (`IsBasket == false`) and Basket — the
  /// lines of the saved order (`IsBasket == true`).
  List<CartItem> linesFor({required bool basket}) => [
    for (final line in _cart?.items ?? const <CartItem>[])
      if (line.isBasket == basket) line,
  ];

  /// Legacy `changeTab()`: the tab left behind loses its selection.
  void clearSelection({required bool basket}) {
    _selected.removeAll([for (final l in linesFor(basket: basket)) l.row]);
    update();
  }

  /// Legacy `doCancelItem()`: cancels (or un-cancels) a Basket line — with
  /// the other selected Basket lines, as legacy selects it and sends them
  /// all (`ActionListItemToOrder` `cancel`, `1` / `0`). Returns the error
  /// to show, or null.
  Future<String?> cancelBasketLine(CartItem line) {
    final rows = [
      for (final l in selectedLines(basket: true))
        if (l.row != line.row) l.row,
      line.row,
    ];
    return _lineAction(rows, 'cancel', line.isCancel ? '0' : '1');
  }

  /// Legacy `tapToSelect()`.
  void toggleSelected(String row) {
    if (!_selected.remove(row)) _selected.add(row);
    update();
  }

  /// Legacy `checkAllItems()`: selects every line of the tab, or clears
  /// them when all are already selected.
  void toggleSelectAll({required bool basket}) {
    final rows = [
      for (final line in _cart?.items ?? const <CartItem>[])
        if (line.isBasket == basket) line.row,
    ];
    if (rows.isEmpty) return;
    if (rows.every(_selected.contains)) {
      _selected.removeAll(rows);
    } else {
      _selected.addAll(rows);
    }
    update();
  }

  bool isAllSelected({required bool basket}) {
    final rows = [
      for (final line in _cart?.items ?? const <CartItem>[])
        if (line.isBasket == basket) line.row,
    ];
    return rows.isNotEmpty && rows.every(_selected.contains);
  }

  bool isBusy = false;
  String? scanError;

  /// The attached customer's shopping card — legacy's Sale page always
  /// runs against one and sends it as `Row` on `change_currency`.
  String shoppingCard = '';

  /// Legacy only opens Sale from a customer: without a shopping card
  /// there is no order to add to.
  bool get hasCustomer => shoppingCard.isNotEmpty;

  void attachShoppingCard(String card) {
    shoppingCard = card;
    update();
  }

  /// Ports legacy `sale.ts`'s `getOrder()`, run when the Sale page is
  /// entered: `GetOrder` opens [context]'s shopping-card order in the
  /// session. Items can't be added before it (the sale engine answers "not
  /// found session").
  ///
  /// A member's chosen [privilege] goes as `member` / `tier` (legacy
  /// `navParams.tier`) and the sale engine prices the lines with it;
  /// [privileges] is the customer's list the Sale page can switch between
  /// (legacy `masterTierList`). Both only count for a member.
  ///
  /// Then, as legacy does while the order is still unlocked, locks it
  /// (`UpdateOrderStatus` `a`) so the card is held by this Sale. Another
  /// card still locked here is released first.
  Future<void> openOrder(
    SaleOrderContext context, {
    Privilege? privilege,
    List<Privilege> privileges = const [],
    Customer? customer,
  }) async {
    if (_locked != null && _locked!.card != context.shoppingCard) {
      await releaseOrder();
    }
    this.customer = customer;
    signature = null;
    sessionExpired = false;
    sessionExpiryHandled = false;
    session = await _restoreSession();
    isMember = context.isMember;
    selectedPrivilege = isMember ? privilege : null;
    this.privileges = isMember ? privileges : const [];
    context = _orderContext = context.withTier(selectedPrivilege?.raw);
    shoppingCard = context.shoppingCard;
    scanError = null;
    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      scanError = 'No active session.';
      update();
      return;
    }
    isBusy = true;
    update();
    try {
      final order = cart = await _getCart(
        sessionKey: sessionKey,
        context: context,
      );
      _basketAtOpen = _basketState(order);
      if (_locked == null && order.orderNo.isNotEmpty) {
        await _updateOrderStatus(
          sessionKey: sessionKey,
          shoppingCard: context.shoppingCard,
          orderNo: order.orderNo,
          status: OrderStatus.lock,
        );
        _locked = (card: context.shoppingCard, orderNo: order.orderNo);
      }
    } on ApiException catch (e) {
      _noteExpiry(e);
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  // The shopping card whose order this Sale has locked, if any.
  ({String card, String orderNo})? _locked;

  /// The customer Sale was opened for (Home's lookup) — legacy Checkout's
  /// Customer profile; null when not passed.
  Customer? customer;

  /// The signed-in cashier and machine — the profile's "Sale" block.
  UserSession? session;

  /// Legacy `MessageErrorMode.SESSION_EXPIRE`: the sale engine said the
  /// cashier's session is gone. Checkout and Payment then log out to the
  /// login page ([SessionExpiryGuard]).
  bool sessionExpired = false;

  /// Set by the first [SessionExpiryGuard] that acts, so the Checkout and
  /// Payment pages stacked together log out once.
  bool sessionExpiryHandled = false;

  void _noteExpiry(ApiException e) {
    if (e.messageCode == FinishMessageCode.sessionExpire) {
      sessionExpired = true;
    }
  }

  /// Legacy Checkout's `signatureCustomerData` / `signaturePaidData`: the
  /// signature taken for this bill, kept across Checkout and Payment.
  SignatureCapture? signature;

  /// Legacy `remainingAmount`: the sale engine's `RemainingAmount`, or the
  /// whole net pay before it reports one.
  double get remainingToPay => cart?.remaining ?? orderNetPay(cart);

  /// Legacy Finish's check: the order requires a signature
  /// (`isRequireSignature`) and none was taken yet.
  bool get signatureMissing =>
      (cart?.requireSignature ?? false) && signature == null;

  /// Legacy `SpecialDiscountPage.onSave()`: `add_special_discount` (or
  /// `update_special_discount` when editing) with the `ValueAdjust` JSON.
  /// No permission check, as legacy. Returns the error to show, or null.
  Future<String?> saveBillDiscount(LineDiscountDraft draft) => _orderAction(
    draft.editing == null ? BillDiscountAction.add : BillDiscountAction.update,
    jsonEncode(draft.toValueAdjust()),
    orderGuid: draft.editing == null ? '' : cart?.guid,
  );

  /// Legacy `doRemoveItem()`: `clear_special_discount` with its Guid.
  Future<String?> removeBillDiscount(LineDiscount discount) => _orderAction(
    BillDiscountAction.remove,
    jsonEncode([discount.guid]),
    orderGuid: cart?.guid,
  );

  /// Legacy `clearAll()`: `clear_all_special_discount`.
  Future<String?> clearBillDiscounts() =>
      _orderAction(BillDiscountAction.clearAll, '');

  /// Legacy `onSubmit()`: a scanned promotion QR as a bill discount.
  Future<String?> addBillDiscountByQrCode(String code) =>
      _orderAction(BillDiscountAction.addByQrCode, code, orderGuid: '');

  Future<String?> _orderAction(
    String action,
    String value, {
    String? orderGuid,
  }) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return 'No active session.';
    isBusy = true;
    update();
    String? error;
    try {
      cart = await _actOnOrder(
        sessionKey: sessionKey,
        action: action,
        value: value,
        orderGuid: orderGuid,
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      error = e.messageCode == null || e.messageCode!.isEmpty
          ? e.messageDesc
          : '${e.messageCode}: ${e.messageDesc}';
    }
    isBusy = false;
    update();
    return error;
  }

  /// The attached customer is a member — legacy passes it to the
  /// promotion master as `excludeMember`.
  bool isMember = false;

  /// Legacy `AuthorizeCode`s for the Discount page.
  static const bahtDiscountAuthCode = 'actBahtDisc';
  static const percentDiscountAuthCode = 'actPerDisc';
  static const percentDiscountAllAuthCode = 'actPerDiscAll';

  /// Legacy `SalePage.editDiscount()`'s gate: any of the discount codes.
  Future<bool> canDiscount() async {
    final session = await _restoreSession();
    if (session == null) return false;
    return session.hasAuthCode(bahtDiscountAuthCode) ||
        session.hasAuthCode(percentDiscountAuthCode) ||
        session.hasAuthCode(percentDiscountAllAuthCode);
  }

  /// Legacy `PromotionPickerPage`: the branch's promotions matching [query].
  Future<List<Promotion>> searchPromotions(String query) =>
      _listPromotions(query: query, excludeMember: isMember);

  /// Legacy `DiscountPage.getPromotion()`: null when not found; a server
  /// failure throws its message.
  Future<Promotion?> findPromotion(String code) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      throw const ApiException(messageDesc: 'No active session.');
    }
    return _findPromotion(
      sessionKey: sessionKey,
      code: code,
      excludeMember: isMember,
    );
  }

  /// Legacy `DiscountPage.addToList()`: `add_item_discount` (or
  /// `update_item_discount` when editing) with the `ValueAdjust` JSON.
  /// One line: percent needs `actPerDisc`, baht `actBahtDisc`; several:
  /// percent needs `actPerDiscAll` (baht is not checked, as in legacy).
  /// Returns the error to show, or null once the cart is updated.
  Future<String?> saveLineDiscount(
    List<String> rows,
    LineDiscountDraft draft,
  ) async {
    final session = await _restoreSession();
    if (session == null) return 'No active session.';
    final authCode = rows.length == 1
        ? (draft.isPercent ? percentDiscountAuthCode : bahtDiscountAuthCode)
        : (draft.isPercent ? percentDiscountAllAuthCode : null);
    if (authCode != null && !session.hasAuthCode(authCode)) {
      return noCurrencyPermission;
    }
    return _lineAction(
      rows,
      draft.editing == null
          ? LineDiscountAction.add
          : LineDiscountAction.update,
      jsonEncode(draft.toValueAdjust()),
    );
  }

  /// Legacy `doRemoveItem()`: `clear_item_discount` with the discount's Guid.
  Future<String?> removeLineDiscount(String row, LineDiscount discount) =>
      _lineAction(
        [row],
        LineDiscountAction.remove,
        jsonEncode([discount.guid]),
      );

  /// Legacy `clearAll()`: `clear_discount_all` on the line.
  Future<String?> clearLineDiscounts(List<String> rows) =>
      _lineAction(rows, LineDiscountAction.clearAll, '');

  /// Legacy `saveDiscountByQrCode()`: a scanned promotion code.
  Future<String?> addLineDiscountByQrCode(List<String> rows, String code) =>
      _lineAction(rows, LineDiscountAction.addByQrCode, code);

  Future<String?> _lineAction(
    List<String> rows,
    String action,
    String value,
  ) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return 'No active session.';
    isBusy = true;
    update();
    String? error;
    try {
      cart = await _actOnLines(
        sessionKey: sessionKey,
        rows: rows,
        action: action,
        value: value,
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      error = e.messageCode == null
          ? e.messageDesc
          : '${e.messageCode}: ${e.messageDesc}';
    }
    isBusy = false;
    update();
    return error;
  }

  /// Legacy leave prompt: "Do you want to save order?" is asked only when
  /// the Buying list (lines not `IsBasket`) has something.
  bool get hasBuyingItems => cart?.items.any((line) => !line.isBasket) ?? false;

  // Legacy `listBasketGuid` / `shareData.listBasket`: the basket lines'
  // cancel state and discounts when Sale opened the order.
  String _basketAtOpen = '';

  static String _basketState(Cart? order) => [
    for (final line in order?.items ?? const <CartItem>[])
      if (line.isBasket)
        '${line.row}:${line.isCancel}:'
            '${line.discounts.map((d) => '${d.guid}/${d.percent}/${d.amount}').join(',')}',
  ].join(';');

  /// Legacy `canSave`: something to save — a net amount, Buying lines, or
  /// basket lines cancelled / re-discounted since the order was opened.
  bool get canSaveOrder {
    final order = cart;
    if (order == null || !hasCustomer) return false;
    if ((order.billing?.grand ?? 0) > 0) return true;
    return hasBuyingItems || _basketState(order) != _basketAtOpen;
  }

  /// Legacy `doSaveOrder()`: saves the order; false (with the server's
  /// message in [scanError]) keeps the cashier on Sale.
  Future<bool> saveOrder() async {
    scanError = null;
    final sessionKey = await _sessionKey();
    if (sessionKey == null || shoppingCard.isEmpty) return false;
    isBusy = true;
    update();
    try {
      cart = await _saveOrder(
        sessionKey: sessionKey,
        shoppingCard: shoppingCard,
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
    return scanError == null;
  }

  /// Legacy `reverseVirtualStock()`, for leaving without saving. Returns
  /// the server's message when it fails — legacy alerts it but leaves
  /// anyway.
  Future<String?> reverseVirtualStock() async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return null;
    try {
      await _reverseVirtualStock(sessionKey: sessionKey);
      return null;
    } on ApiException catch (e) {
      _noteExpiry(e);
      return e.messageDesc;
    }
  }

  /// Ports legacy `onlyUnlockShoppingCard()`, run whenever the Sale page is
  /// left: unlocks the held order (`UpdateOrderStatus` `A`) and detaches
  /// the customer, so Sale needs Go to Sale again.
  ///
  /// Legacy leaves whatever the sale engine answers, but when the call
  /// itself fails (no network / timeout) it does not leave — it alerts and
  /// logs out. That case returns false with the card still held here, for
  /// the caller to ask about logging out.
  Future<bool> releaseOrder() async {
    final locked = _locked;
    if (locked != null) {
      final sessionKey = await _sessionKey();
      if (sessionKey != null) {
        try {
          await _updateOrderStatus(
            sessionKey: sessionKey,
            shoppingCard: locked.card,
            orderNo: locked.orderNo,
            status: OrderStatus.unlock,
          );
        } on ApiException catch (e) {
          _noteExpiry(e);
          final failure = mapExceptionToFailure(e);
          if (failure is NetworkFailure || failure is TimeoutFailure) {
            return false;
          }
          // The sale engine answered: legacy leaves regardless.
        }
      }
    }
    _locked = null;
    shoppingCard = '';
    customer = null;
    signature = null;
    sessionExpired = false;
    sessionExpiryHandled = false;
    cart = null;
    scanError = null;
    isMember = false;
    selectedPrivilege = null;
    privileges = const [];
    _orderContext = null;
    update();
    return true;
  }

  /// Why the last currency change failed, if it did.
  String? currencyError;

  /// Legacy `AuthorizeCode.ChangeCurrency`.
  static const changeCurrencyAuthCode = 'actCurrency';
  static const noCurrencyPermission = "Sorry, you don't have permission.";
  static const noCustomer = 'Find a customer to start a sale.';

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
      _noteExpiry(e);
      currencyError = e.messageDesc;
    }
    isBusy = false;
    update();
    return currencyError == null;
  }

  /// The privilege the open order is priced with (legacy Sale's
  /// `selectPrivilege`): picked on Home / the customer profile or here.
  /// The sale engine gets it as `GetOrder`'s `member` / `tier` attribute
  /// and applies it to the lines itself.
  Privilege? selectedPrivilege;

  /// The member's privileges to switch between (legacy `masterTierList`);
  /// empty for a non-member.
  List<Privilege> privileges = const [];

  // What the open order was last fetched with.
  SaleOrderContext? _orderContext;

  /// Legacy compares privileges by `PromoCode` (the picker's active one).
  static bool samePrivilege(Privilege? a, Privilege? b) =>
      identical(a, b) ||
      (a != null &&
          b != null &&
          a.promoCode == b.promoCode &&
          a.name == b.name);

  /// Ports legacy Sale's "Privilege Selection": re-sends `GetOrder` with
  /// the new `tier` (null = No Privilege) so the sale engine reprices the
  /// order. Legacy keeps the previous privilege when that fails; the
  /// server's message is returned for an alert. Picking the current one
  /// does nothing.
  Future<String?> changePrivilege(Privilege? privilege) async {
    final context = _orderContext;
    if (context == null || !context.isMember || isBusy) return null;
    if (samePrivilege(privilege, selectedPrivilege)) return null;
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return 'No active session.';
    isBusy = true;
    update();
    String? error;
    try {
      final next = context.withTier(privilege?.raw);
      cart = await _getCart(sessionKey: sessionKey, context: next);
      _orderContext = next;
      selectedPrivilege = privilege;
    } on ApiException catch (e) {
      _noteExpiry(e);
      error = e.messageCode == null
          ? e.messageDesc
          : '${e.messageCode}: ${e.messageDesc}';
    }
    isBusy = false;
    update();
    return error;
  }

  /// Ports legacy `sale.ts`'s `onSubmit()`: the scanned / typed text goes
  /// to `AddItemToOrder` as `ItemCode` as-is (no article lookup first, no
  /// client-side quantity parsing), with the selected Buying lines' Guids as
  /// `Rows` ([selectedRows] overrides). Empty input does nothing, as in
  /// legacy.
  Future<void> scan(String rawInput, {List<String>? selectedRows}) async {
    scanError = null;
    final itemCode = rawInput.trim();
    _log('[SaleCartViewModel.scan] raw="$rawInput" itemCode="$itemCode"');
    if (itemCode.isEmpty) {
      _log('[SaleCartViewModel.scan] skipped: empty input');
      update();
      return;
    }
    // Legacy only reaches Sale with a customer's shopping card.
    if (shoppingCard.isEmpty) {
      _log('[SaleCartViewModel.scan] blocked: no shopping card attached');
      scanError = noCustomer;
      update();
      return;
    }

    final sessionKey = await _sessionKey();
    if (sessionKey == null) {
      _log('[SaleCartViewModel.scan] blocked: no session');
      scanError = 'No active session.';
      update();
      return;
    }

    final rows =
        selectedRows ??
        [for (final line in selectedLines(basket: false)) line.row];
    _log(
      '[SaleCartViewModel.scan] AddItemToOrder shoppingCard=$shoppingCard '
      'sessionKey=$sessionKey rows=$rows',
    );
    isBusy = true;
    update();
    try {
      final order = cart = await _addItemToCart(
        sessionKey: sessionKey,
        itemCode: itemCode,
        rows: rows,
      );
      _log(
        '[SaleCartViewModel.scan] ok order=${order.guid} '
        'lines=${order.items.length} '
        '[${order.items.map((l) => '${l.articleCode} x${l.quantity} '
            '= ${l.lineTotal}').join(', ')}]',
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      _log(
        '[SaleCartViewModel.scan] failed code=${e.messageCode} '
        'desc=${e.messageDesc}',
      );
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
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
      _noteExpiry(e);
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  /// Legacy `canCheckout`: the sale engine's `isCheckOut` — false while a
  /// line still misses a serial, CITES, VAS, … (see the lines'
  /// `recordInfos`).
  bool get canCheckout => cart?.isCheckOut ?? false;

  /// Legacy `AuthorizeCode.LoginCashier`, which `goCheckout()` checks.
  static const loginCashierAuthCode = 'actCashier';

  /// Legacy `goCheckout()`'s checks before Checkout, in its order.
  Future<CheckoutGate> checkoutGate() async {
    final session = await _restoreSession();
    if (session == null) return CheckoutGate.noSession;
    if (session.posType == UserSession.posTypeSale ||
        !session.hasAuthCode(loginCashierAuthCode)) {
      return CheckoutGate.noPermission;
    }
    if (isMember && selectedPrivilege == null) {
      return CheckoutGate.noPrivilege;
    }
    return CheckoutGate.ready;
  }

  /// Legacy `updateOrderStatusAndGotoCheckOutPage()`: `UpdateOrderStatus`
  /// `e`, then Checkout whatever the sale engine answers. False only when
  /// the call itself fails (no network / timeout) — legacy then alerts
  /// "Network not connection" and signs out.
  Future<bool> markCheckout() async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return true;
    try {
      await _updateOrderStatus(
        sessionKey: sessionKey,
        shoppingCard: shoppingCard,
        orderNo: cart?.orderNo ?? '',
        status: OrderStatus.checkout,
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      final failure = mapExceptionToFailure(e);
      if (failure is NetworkFailure || failure is TimeoutFailure) return false;
    }
    return true;
  }

  /// Legacy `ActionPaymentEnum.Abort`, sent as `ActionOrderPayment`'s
  /// `Action`.
  static const abortPaymentAction = '2';

  /// Leaving Checkout for Sale, after "Do you want to go back?". Legacy
  /// `sessionAbortPayment()`: `ActionOrderPayment` Abort for the order.
  /// Then — not in legacy, which leaves the order at `e` — the order goes
  /// back to the Sale lock (`UpdateOrderStatus` `a`), and is reloaded as
  /// legacy Sale's `ionViewWillEnter()` does. Returns the error to show
  /// (Checkout stays), or null once back.
  Future<String?> leaveCheckout() async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return 'No active session.';
    isBusy = true;
    update();
    String? error;
    try {
      await _actOnOrder(
        sessionKey: sessionKey,
        action: abortPaymentAction,
        value: '',
        orderGuid: cart?.guid,
      );
    } on ApiException catch (e) {
      _noteExpiry(e);
      final failure = mapExceptionToFailure(e);
      if (failure is NetworkFailure || failure is TimeoutFailure) {
        error = e.messageDesc;
      } else if (e.messageCode != null && e.messageCode!.isNotEmpty) {
        // Legacy: "Error <code>" with the description, and stays.
        error = '${e.messageCode}: ${e.messageDesc}';
      }
      // Anything else (an answer without the order) still counts as
      // aborted — legacy only looks at isCompleted.
    }
    if (error == null) {
      try {
        await _updateOrderStatus(
          sessionKey: sessionKey,
          shoppingCard: shoppingCard,
          orderNo: cart?.orderNo ?? '',
          status: OrderStatus.lock,
        );
      } on ApiException catch (e) {
        _noteExpiry(e);
        final failure = mapExceptionToFailure(e);
        if (failure is NetworkFailure || failure is TimeoutFailure) {
          error = e.messageDesc;
        }
      }
    }
    final context = _orderContext;
    if (error == null && context != null) {
      try {
        cart = await _getCart(sessionKey: sessionKey, context: context);
      } on ApiException catch (e) {
        _noteExpiry(e);
        scanError = e.messageDesc;
      }
    }
    isBusy = false;
    update();
    return error;
  }

  /// Legacy `AuthorizeCode.TakeOrUntake`, which `setPickupMode()` checks.
  static const takeOrUntakeAuthCode = 'actTake';

  /// Legacy `EditSalePage.setPickupMode()`'s gate.
  Future<bool> canTakeOrUntake() async {
    final session = await _restoreSession();
    return session?.hasAuthCode(takeOrUntakeAuthCode) ?? false;
  }

  /// Legacy `EditSalePage.onSubmit()`: a serial longer than 20 characters
  /// is a barcode, resolved to the article's `SerialNo`; a shorter one is
  /// kept as typed. Null when the lookup fails (legacy keeps the field).
  Future<String?> resolveSerial(String scanned) async {
    if (scanned.length <= 20) return scanned;
    final session = await _restoreSession();
    if (session == null) return null;
    isBusy = true;
    update();
    String? serial;
    try {
      serial = await _lookupSerial(site: session.site, barcode: scanned);
    } on ApiException catch (e) {
      _noteExpiry(e);
      _log('[Sale] serial lookup failed: ${e.messageDesc}');
    }
    isBusy = false;
    update();
    return serial;
  }

  /// Legacy `EditSalePage.saveItem()`: saves [edit] on [row]. Returns the
  /// sale engine's warning (the order is still updated, as legacy keeps the
  /// returned line) or error (`code: desc`; the cart is unchanged).
  Future<({String? warning, String? error})> editLine(
    String row,
    LineEdit edit,
  ) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return (warning: null, error: 'No active session.');
    isBusy = true;
    update();
    String? warning;
    String? error;
    try {
      final result = await _editCartItem(
        sessionKey: sessionKey,
        row: row,
        edit: edit,
      );
      cart = result.cart;
      warning = result.warning;
    } on ApiException catch (e) {
      _noteExpiry(e);
      error = e.messageCode == null || e.messageCode!.isEmpty
          ? e.messageDesc
          : '${e.messageCode}: ${e.messageDesc}';
    }
    isBusy = false;
    update();
    return (warning: warning, error: error);
  }

  Future<void> removeItem(String row) async {
    final sessionKey = await _sessionKey();
    if (sessionKey == null) return;

    isBusy = true;
    update();
    try {
      cart = await _removeCartItem(sessionKey: sessionKey, row: row);
    } on ApiException catch (e) {
      _noteExpiry(e);
      scanError = e.messageDesc;
    }
    isBusy = false;
    update();
  }

  Future<String?> _sessionKey() async {
    final session = await _restoreSession();
    return session?.sessionKey;
  }
}
