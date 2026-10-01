import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
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

import '../../../auth/fake_auth_repository.dart';
import '../../fake_sale_repository.dart';

const testSession = UserSession(
  sessionKey: 'abc123',
  branchNo: '03',
  userCode: 'U001',
  userName: 'Test User',
  // The Discount page's permissions (legacy actBahtDisc / actPerDisc /
  // actPerDiscAll).
  authorizedActions: [
    AuthorizedAction(moduleCode: 'SALE', authCode: 'actBahtDisc', action: ''),
    AuthorizedAction(moduleCode: 'SALE', authCode: 'actPerDisc', action: ''),
    AuthorizedAction(moduleCode: 'SALE', authCode: 'actPerDiscAll', action: ''),
  ],
);

const chanel = CartItem(
  row: '1',
  articleCode: '3145891255607',
  articleName: 'CHANEL N°5 EAU DE PARFUM 100ML',
  quantity: 1,
  unitPrice: 5900,
  lineTotal: 5900,
);

const johnnie = CartItem(
  row: '2',
  articleCode: '5000267116419',
  articleName: 'JOHNNIE WALKER BLUE LABEL 1L',
  quantity: 2,
  unitPrice: 7800,
  lineTotal: 15600,
);

const sampleCart = Cart(
  guid: 'order-1',
  isCheckOut: false,
  items: [chanel, johnnie],
);

SaleCartViewModel buildSaleViewModel(
  FakeSaleRepository sale, {
  Cart? cart,
  UserSession session = testSession,
  // Sale always runs against a customer's shopping card.
  String shoppingCard = 'CPX0001',
}) {
  final viewModel = SaleCartViewModel(
    restoreSession: RestoreSessionUseCase(
      FakeAuthRepository(currentSessionResult: session),
    ),
    getCart: GetCartUseCase(sale),
    updateOrderStatus: UpdateOrderStatusUseCase(sale),
    saveOrder: SaveOrderUseCase(sale),
    reverseVirtualStock: ReverseVirtualStockUseCase(sale),
    listPromotions: ListPromotionsUseCase(sale),
    findPromotion: FindPromotionUseCase(sale),
    actOnLines: ActOnLinesUseCase(sale),
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
  viewModel
    ..cart = cart
    ..shoppingCard = shoppingCard;
  return viewModel;
}

/// A saved order's lines (legacy `IsBasket`) next to one being bought.
const savedTake = CartItem(
  row: 'b1',
  articleCode: '8850001',
  articleName: 'SAVED PERFUME',
  quantity: 1,
  unitPrice: 3000,
  lineTotal: 3000,
  isBasket: true,
  lineNo: 1,
  collectStatus: 'T',
);

const savedCancelled = CartItem(
  row: 'b2',
  articleCode: '8850002',
  articleName: 'SAVED WATCH',
  quantity: 1,
  unitPrice: 9000,
  lineTotal: 9000,
  isBasket: true,
  lineNo: 2,
  collectStatus: 'C',
  isCancel: true,
  isFreeze: true,
  isLockDiscount: true,
);

const mixedCart = Cart(
  guid: 'order-1',
  isCheckOut: false,
  items: [savedTake, savedCancelled, chanel],
);
