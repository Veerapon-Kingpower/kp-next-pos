import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/exchange_change_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';

import '../../../auth/fake_auth_repository.dart';
import '../../fake_sale_repository.dart';

const testSession = UserSession(
  sessionKey: 'abc123',
  branchNo: '03',
  userCode: 'U001',
  userName: 'Test User',
  authorizedActions: [],
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
}) {
  final viewModel = SaleCartViewModel(
    restoreSession: RestoreSessionUseCase(
      FakeAuthRepository(currentSessionResult: session),
    ),
    lookupArticle: LookupArticleByBarcodeUseCase(sale),
    addItemToCart: AddItemToCartUseCase(sale),
    updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
    removeCartItem: RemoveCartItemUseCase(sale),
    listCurrencies: ListCurrenciesUseCase(sale),
    changeOrderCurrency: ChangeOrderCurrencyUseCase(sale),
    exchangeChange: ExchangeChangeUseCase(sale),
  );
  viewModel.cart = cart;
  return viewModel;
}
