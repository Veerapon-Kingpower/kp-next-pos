import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/entities/order_status.dart';
import 'package:kp_pos/features/sale/domain/entities/sale_order_context.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/get_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/leave_sale_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/line_discount_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_order_status_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/cash_payment_usecases.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/exchange_change_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/edit_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../auth/fake_auth_repository.dart';
import '../fake_sale_repository.dart';

void main() {
  const session = UserSession(
    sessionKey: 'abc123',
    branchNo: '03',
    userCode: 'U001',
    userName: 'Test User',
    authorizedActions: [],
  );

  SaleCartViewModel buildViewModel({
    FakeSaleRepository? saleRepository,
    UserSession? currentSessionResult = session,
  }) {
    final sale = saleRepository ?? FakeSaleRepository();
    final auth = FakeAuthRepository(currentSessionResult: currentSessionResult);
    return SaleCartViewModel(
      restoreSession: RestoreSessionUseCase(auth),
      getCart: GetCartUseCase(sale),
      updateOrderStatus: UpdateOrderStatusUseCase(sale),
      saveOrder: SaveOrderUseCase(sale),
      reverseVirtualStock: ReverseVirtualStockUseCase(sale),
      listPromotions: ListPromotionsUseCase(sale),
      findPromotion: FindPromotionUseCase(sale),
      actOnLines: ActOnLinesUseCase(sale),
      actOnOrder: ActOnOrderUseCase(sale),
      addItemToCart: AddItemToCartUseCase(sale),
      updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
      editCartItem: EditCartItemUseCase(sale),
      lookupSerial: LookupSerialUseCase(sale),
      removeCartItem: RemoveCartItemUseCase(sale),
      listCurrencies: ListCurrenciesUseCase(sale),
      changeOrderCurrency: ChangeOrderCurrencyUseCase(sale),
      exchangeChange: ExchangeChangeUseCase(sale),
      addCashPayment: AddCashPaymentUseCase(sale),
      saveChangeExchange: SaveChangeExchangeUseCase(sale),
    );
  }

  test('an empty scan does nothing', () async {
    final sale = FakeSaleRepository();
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.scan('   ');

    expect(viewModel.scanError, isNull);
    expect(viewModel.cart, isNull);
    expect(sale.lastAddedItemCode, isNull);
  });

  test('a scan adds the typed text as-is, as legacy onSubmit does', () async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [
          CartItem(
            row: '1',
            articleCode: 'ART001',
            articleName: 'Test Article',
            quantity: 3,
            unitPrice: 100,
            lineTotal: 300,
          ),
        ],
      ),
    );
    final viewModel = buildViewModel(saleRepository: sale)
      ..attachShoppingCard('CPX0001');

    await viewModel.scan(' 3*8850012345678 ', selectedRows: ['guid-1']);

    expect(sale.lastLookupBarcode, isNull, reason: 'no article lookup');
    expect(sale.lastAddedItemCode, '3*8850012345678');
    expect(sale.lastAddedRows, ['guid-1']);
    expect(viewModel.cart?.guid, 'order-1');
    expect(viewModel.scanError, isNull);
  });

  test('an add failure surfaces the server message as scanError', () async {
    final sale = FakeSaleRepository(
      mutationError: const ApiException(messageDesc: 'Item not found'),
    );
    final viewModel = buildViewModel(saleRepository: sale)
      ..attachShoppingCard('CPX0001');

    await viewModel.scan('8850000000000');

    expect(viewModel.scanError, 'Item not found');
    expect(viewModel.cart, isNull);
  });

  test(
    'scan without an active session sets scanError and skips the add',
    () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(
        saleRepository: sale,
        currentSessionResult: null,
      )..attachShoppingCard('CPX0001');

      await viewModel.scan('8850012345678');

      expect(viewModel.scanError, isNotNull);
      expect(sale.lastAddedItemCode, isNull);
    },
  );

  test(
    'updateQuantity with a positive quantity calls the repository',
    () async {
      final sale = FakeSaleRepository(
        cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
      );
      final viewModel = buildViewModel(saleRepository: sale);

      await viewModel.updateQuantity(row: '1', quantity: 2);

      expect(sale.lastUpdatedRow, '1');
      expect(sale.lastUpdatedQuantity, 2);
      expect(viewModel.cart?.guid, 'order-1');
    },
  );

  test('updateQuantity with quantity 0 removes the item instead', () async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
    );
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.updateQuantity(row: '1', quantity: 0);

    expect(sale.lastRemovedRow, '1');
    expect(sale.lastUpdatedRow, isNull);
  });

  test('removeItem calls the repository and updates the cart', () async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
    );
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.removeItem('1');

    expect(sale.lastRemovedRow, '1');
    expect(viewModel.cart?.guid, 'order-1');
  });

  group('privilege (legacy Sale Privilege Selection)', () {
    const gold = Privilege(
      name: 'Gold 10%',
      discount: 10,
      typeCode: 'VIP',
      promoCode: 'GOLD10',
      raw: {'Name': 'Gold 10%', 'PromoCode': 'GOLD10'},
    );
    const elite = Privilege(
      name: 'Elite 15%',
      discount: 15,
      typeCode: 'VIP',
      promoCode: 'ELITE15',
      raw: {'Name': 'Elite 15%', 'PromoCode': 'ELITE15'},
    );
    const member = SaleOrderContext(shoppingCard: 'SC1', memberId: 'M1');

    test('openOrder sends a member\'s privilege as GetOrder tier', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        member,
        privilege: gold,
        privileges: const [gold, elite],
      );
      expect(sale.lastOrderContext!.tier, gold.raw);
      expect(viewModel.selectedPrivilege, gold);
      expect(viewModel.privileges, [gold, elite]);
    });

    test('a non-member gets no privilege or list', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'SC1'),
        privilege: gold,
        privileges: const [gold],
      );
      expect(sale.lastOrderContext!.tier, isNull);
      expect(viewModel.selectedPrivilege, isNull);
      expect(viewModel.privileges, isEmpty);
    });

    test('changePrivilege re-sends GetOrder with the new tier', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(member, privilege: gold);

      expect(await viewModel.changePrivilege(elite), isNull);
      expect(sale.lastOrderContext!.tier, elite.raw);
      expect(sale.lastOrderContext!.shoppingCard, 'SC1');
      expect(viewModel.selectedPrivilege, elite);

      expect(await viewModel.changePrivilege(null), isNull);
      expect(sale.lastOrderContext!.tier, isNull, reason: 'No Privilege');
      expect(viewModel.selectedPrivilege, isNull);
    });

    test('a failed change keeps the previous privilege', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(member, privilege: gold);
      sale.mutationError = const ApiException(
        messageDesc: 'Privilege expired',
        messageCode: 'P01',
      );

      expect(await viewModel.changePrivilege(elite), 'P01: Privilege expired');
      expect(viewModel.selectedPrivilege, gold);

      sale.mutationError = null;
      await viewModel.changePrivilege(null);
      expect(
        sale.lastOrderContext!.tier,
        isNull,
        reason: 'the failed tier was not kept',
      );
    });

    test('releasing the order forgets its privilege', () async {
      final viewModel = buildViewModel();
      await viewModel.openOrder(member, privilege: gold, privileges: [gold]);
      await viewModel.releaseOrder();
      expect(viewModel.selectedPrivilege, isNull);
      expect(viewModel.privileges, isEmpty);
    });
  });

  group('change currency (legacy CurrencyPickerPage)', () {
    const permitted = UserSession(
      sessionKey: 'abc123',
      branchNo: '03',
      userCode: 'U001',
      userName: 'Test User',
      authorizedActions: [
        AuthorizedAction(
          moduleCode: 'SALE',
          authCode: 'actCurrency',
          action: 'Currency',
        ),
      ],
    );
    const usdCart = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [],
      billing: CartBilling(
        currencyCode: 'USD',
        currencyDescription: 'US Dollar',
        currencyRate: 35.5,
        total: 100,
        grand: 100,
        discount: 0,
        cashD: 0,
        netPay: 100,
        netPayBase: 3550,
      ),
    );

    test('needs the actCurrency permission', () async {
      final sale = FakeSaleRepository(currencyCartResult: usdCart);
      final viewModel = buildViewModel(saleRepository: sale)
        ..attachShoppingCard('CPX0001');

      expect(await viewModel.canChangeCurrency(), isFalse);
      expect(await viewModel.changeCurrency('USD'), isFalse);
      expect(viewModel.currencyError, "Sorry, you don't have permission.");
      expect(sale.lastCurrencyCode, isNull);
    });

    test('needs an attached shopping card', () async {
      final sale = FakeSaleRepository(currencyCartResult: usdCart);
      final viewModel = buildViewModel(
        saleRepository: sale,
        currentSessionResult: permitted,
      );

      expect(await viewModel.changeCurrency('USD'), isFalse);
      expect(viewModel.currencyError, contains('Attach a customer'));
      expect(sale.lastCurrencyCode, isNull);
    });

    test(
      'sends the shopping card and code, and takes the repriced order',
      () async {
        final sale = FakeSaleRepository(currencyCartResult: usdCart);
        final viewModel = buildViewModel(
          saleRepository: sale,
          currentSessionResult: permitted,
        )..attachShoppingCard('CPX0001');

        expect(await viewModel.canChangeCurrency(), isTrue);
        expect(await viewModel.changeCurrency('USD'), isTrue);
        expect(sale.lastCurrencyShoppingCard, 'CPX0001');
        expect(sale.lastCurrencyCode, 'USD');
        expect(viewModel.cart?.billing?.currencyCode, 'USD');
        expect(viewModel.currencyError, isNull);
      },
    );

    test('exchangeChange asks the sale engine for a change quote', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);

      final quote = await viewModel.exchangeChange(
        currencyCode: 'USD',
        currencyAmount: 10,
        changeInBaht: 500,
        isChangeButton: true,
      );

      expect(sale.exchangeCalls.single, (
        code: 'USD',
        amount: 10.0,
        change: 500.0,
        button: true,
      ));
      expect(quote.currencyCode, 'USD');
    });

    test('payCash records baht cash against the order', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale)
        ..cart = const Cart(guid: 'order-1', isCheckOut: false, items: []);

      expect(await viewModel.payCash(1000), isTrue);
      expect(sale.cashPayments.single, (
        orderGuid: 'order-1',
        currency: 'THB',
        rate: 1.0,
        amount: 1000.0,
        base: 1000.0,
      ));
    });

    test('payCash in a USD order converts the base amount at the order '
        'rate', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale)..cart = usdCart;

      await viewModel.payCash(10);

      expect(sale.cashPayments.single.currency, 'USD');
      expect(sale.cashPayments.single.base, 355);
    });

    test('payCash needs an order and an amount', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);

      expect(await viewModel.payCash(100), isFalse);
      expect(viewModel.paymentError, 'There is no order to pay.');
      viewModel.cart = const Cart(guid: 'o', isCheckOut: false, items: []);
      expect(await viewModel.payCash(0), isFalse);
      expect(viewModel.paymentError, 'Enter the cash received.');
      expect(sale.cashPayments, isEmpty);
    });

    test('saveChangeExchange saves edit_exchange for the order', () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale)
        ..cart = const Cart(guid: 'order-1', isCheckOut: false, items: []);

      expect(
        await viewModel.saveChangeExchange(currencyCode: 'USD', amount: 2),
        isTrue,
      );
      expect(sale.changeExchanges.single, (currency: 'USD', amount: 2.0));
    });

    test('a sale engine refusal is shown', () async {
      final sale = FakeSaleRepository(
        mutationError: const ApiException(messageDesc: 'Rate not found.'),
      );
      final viewModel = buildViewModel(
        saleRepository: sale,
        currentSessionResult: permitted,
      )..attachShoppingCard('CPX0001');

      expect(await viewModel.changeCurrency('USD'), isFalse);
      expect(viewModel.currencyError, 'Rate not found.');
      expect(viewModel.isBusy, isFalse);
    });
  });

  test('openOrder opens the customer order with GetOrder', () async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
    );
    final viewModel = buildViewModel(saleRepository: sale);
    const context = SaleOrderContext(shoppingCard: 'CPX0001', memberId: 'M1');

    await viewModel.openOrder(context);

    expect(sale.lastOrderContext!.shoppingCard, 'CPX0001');
    expect(sale.lastOrderContext!.memberId, 'M1');
    expect(viewModel.shoppingCard, 'CPX0001');
    expect(viewModel.cart?.guid, 'order-1');
    expect(viewModel.scanError, isNull);
  });

  test('scanning without a customer asks for one and skips the add', () async {
    final sale = FakeSaleRepository();
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.scan('8850012345678');

    expect(viewModel.scanError, SaleCartViewModel.noCustomer);
    expect(sale.lastAddedItemCode, isNull);
  });

  group('order lock', () {
    const locked = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [],
      orderNo: '42',
    );

    test('openOrder locks the opened order, once per card', () async {
      final sale = FakeSaleRepository(cartResult: locked);
      final viewModel = buildViewModel(saleRepository: sale);
      const context = SaleOrderContext(shoppingCard: 'CPX0001');

      await viewModel.openOrder(context);
      await viewModel.openOrder(context);

      expect(sale.orderStatuses, [
        (card: 'CPX0001', orderNo: '42', status: OrderStatus.lock),
      ]);
    });

    test('opening another card unlocks the held one first', () async {
      final sale = FakeSaleRepository(cartResult: locked);
      final viewModel = buildViewModel(saleRepository: sale);

      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0002'),
      );

      expect(sale.orderStatuses, [
        (card: 'CPX0001', orderNo: '42', status: OrderStatus.lock),
        (card: 'CPX0001', orderNo: '42', status: OrderStatus.unlock),
        (card: 'CPX0002', orderNo: '42', status: OrderStatus.lock),
      ]);
    });

    test('releaseOrder unlocks and detaches the customer', () async {
      final sale = FakeSaleRepository(cartResult: locked);
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );

      await viewModel.releaseOrder();

      expect(sale.orderStatuses.last.status, OrderStatus.unlock);
      expect(viewModel.shoppingCard, isEmpty);
      expect(viewModel.cart, isNull);
    });

    test(
      'an unlock that cannot reach the server keeps the card held',
      () async {
        final sale = FakeSaleRepository(cartResult: locked);
        final viewModel = buildViewModel(saleRepository: sale);
        await viewModel.openOrder(
          const SaleOrderContext(shoppingCard: 'CPX0001'),
        );
        sale.orderStatusError = const ApiException(
          messageDesc: 'No network connection.',
        );

        expect(await viewModel.releaseOrder(), isFalse);
        expect(viewModel.shoppingCard, 'CPX0001');
        expect(viewModel.cart, isNotNull);
      },
    );

    test('an unlock the server rejects still leaves, as legacy', () async {
      final sale = FakeSaleRepository(cartResult: locked);
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      sale.orderStatusError = const ApiException(messageDesc: 'Not locked');

      expect(await viewModel.releaseOrder(), isTrue);
      expect(viewModel.shoppingCard, isEmpty);
    });

    test('a lock failure is shown', () async {
      final sale = FakeSaleRepository(cartResult: locked)
        ..orderStatusError = const ApiException(
          messageDesc: 'Shopping card is locked',
        );
      final viewModel = buildViewModel(saleRepository: sale);

      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );

      expect(viewModel.scanError, 'Shopping card is locked');
    });
  });

  group('line selection (legacy isSelected)', () {
    const cart = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [
        CartItem(
          row: 'a',
          articleCode: '1',
          articleName: 'A',
          quantity: 1,
          unitPrice: 1,
          lineTotal: 1,
        ),
        CartItem(
          row: 'b',
          articleCode: '2',
          articleName: 'B',
          quantity: 1,
          unitPrice: 1,
          lineTotal: 1,
        ),
        CartItem(
          row: 'c',
          articleCode: '3',
          articleName: 'C',
          quantity: 1,
          unitPrice: 1,
          lineTotal: 1,
          isBasket: true,
        ),
      ],
    );

    test('toggle and Select All work per tab', () {
      final viewModel = buildViewModel()..cart = cart;
      viewModel.toggleSelected('b');
      expect(viewModel.selectedLines(basket: false).map((l) => l.row), ['b']);

      viewModel.toggleSelectAll(basket: false);
      expect(viewModel.isAllSelected(basket: false), isTrue);
      expect(viewModel.selectedLines(basket: true), isEmpty);

      viewModel.toggleSelectAll(basket: false);
      expect(viewModel.selectedLines(basket: false), isEmpty);
    });

    test('a new order from the sale engine clears the selection', () {
      final viewModel = buildViewModel()..cart = cart;
      viewModel.toggleSelected('a');
      viewModel.cart = cart;
      expect(viewModel.isSelected('a'), isFalse);
    });

    test('a scan sends the selected Buying lines as Rows', () async {
      final sale = FakeSaleRepository(cartResult: cart);
      final viewModel = buildViewModel(saleRepository: sale)
        ..attachShoppingCard('CPX0001')
        ..cart = cart;
      viewModel
        ..toggleSelected('a')
        ..toggleSelected('c');

      await viewModel.scan('8850012345678');

      expect(sale.lastAddedRows, ['a'], reason: 'c is a Basket line');
    });
  });

  group('canSaveOrder (legacy canSave)', () {
    const basketLine = CartItem(
      row: 'b1',
      articleCode: '1',
      articleName: 'Basket bag',
      quantity: 1,
      unitPrice: 0,
      lineTotal: 0,
      isBasket: true,
    );
    const basketOnly = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [basketLine],
    );

    test('an unchanged basket-only order has nothing to save', () async {
      final sale = FakeSaleRepository(cartResult: basketOnly);
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      expect(viewModel.canSaveOrder, isFalse);
    });

    test('a basket line cancelled since opening can be saved', () async {
      final sale = FakeSaleRepository(cartResult: basketOnly);
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      viewModel.cart = const Cart(
        guid: 'order-1',
        isCheckOut: false,
        items: [
          CartItem(
            row: 'b1',
            articleCode: '1',
            articleName: 'Basket bag',
            quantity: 1,
            unitPrice: 0,
            lineTotal: 0,
            isBasket: true,
            isCancel: true,
          ),
        ],
      );
      expect(viewModel.canSaveOrder, isTrue);
    });

    test('Buying lines can be saved', () async {
      final sale = FakeSaleRepository(
        cartResult: const Cart(
          guid: 'order-1',
          isCheckOut: false,
          items: [
            CartItem(
              row: 'x',
              articleCode: '2',
              articleName: 'Wallet',
              quantity: 1,
              unitPrice: 0,
              lineTotal: 0,
            ),
          ],
        ),
      );
      final viewModel = buildViewModel(saleRepository: sale);
      await viewModel.openOrder(
        const SaleOrderContext(shoppingCard: 'CPX0001'),
      );
      expect(viewModel.canSaveOrder, isTrue);
    });
  });

  group('Basket (the saved order, legacy IsBasket)', () {
    const buying = CartItem(
      row: 'x',
      articleCode: '1',
      articleName: 'Wallet',
      quantity: 1,
      unitPrice: 1,
      lineTotal: 1,
    );
    const saved = CartItem(
      row: 'b',
      articleCode: '2',
      articleName: 'Bag',
      quantity: 1,
      unitPrice: 1,
      lineTotal: 1,
      isBasket: true,
    );
    const savedToo = CartItem(
      row: 'c',
      articleCode: '3',
      articleName: 'Belt',
      quantity: 1,
      unitPrice: 1,
      lineTotal: 1,
      isBasket: true,
      isCancel: true,
    );
    const cart = Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [buying, saved, savedToo],
    );

    test('lines split by tab', () {
      final viewModel = buildViewModel()..cart = cart;
      expect(viewModel.linesFor(basket: false).map((l) => l.row), ['x']);
      expect(viewModel.linesFor(basket: true).map((l) => l.row), ['b', 'c']);
    });

    test('switching tab clears the other tab\'s selection', () {
      final viewModel = buildViewModel()..cart = cart;
      viewModel
        ..toggleSelected('x')
        ..toggleSelected('b');
      viewModel.clearSelection(basket: false);
      expect(viewModel.isSelected('x'), isFalse);
      expect(viewModel.isSelected('b'), isTrue);
    });

    test('cancel sends the selected Basket lines with this one; a '
        'cancelled line is un-cancelled', () async {
      final sale = FakeSaleRepository(cartResult: cart);
      final viewModel = buildViewModel(saleRepository: sale)..cart = cart;
      viewModel.toggleSelected('b');

      await viewModel.cancelBasketLine(savedToo);

      final action = sale.lineActions.single;
      expect(action.action, 'cancel');
      expect(action.value, '0');
      expect(action.rows, ['b', 'c']);
    });
  });
}
