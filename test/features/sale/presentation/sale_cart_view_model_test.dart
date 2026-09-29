import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/domain/entities/authorized_action.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/customer/domain/entities/privilege.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/change_order_currency_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/list_currencies_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
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
      lookupArticle: LookupArticleByBarcodeUseCase(sale),
      addItemToCart: AddItemToCartUseCase(sale),
      updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
      removeCartItem: RemoveCartItemUseCase(sale),
      listCurrencies: ListCurrenciesUseCase(sale),
      changeOrderCurrency: ChangeOrderCurrencyUseCase(sale),
    );
  }

  test(
    'a malformed scan sets scanError without calling the repository',
    () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(saleRepository: sale);

      await viewModel.scan('not*a*valid*scan');

      expect(viewModel.scanError, isNotNull);
      expect(viewModel.cart, isNull);
      expect(sale.lastLookupBarcode, isNull);
    },
  );

  test('a valid scan looks up the article and adds it to the cart', () async {
    final sale = FakeSaleRepository(
      lookupResult: const Article(
        articleCode: 'ART001',
        articleName: 'Test Article',
        eanCode: '8850012345678',
        brandCode: 'B1',
        brandName: 'Brand One',
        price: 100,
        vatRate: 7,
      ),
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
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.scan('3*8850012345678');

    expect(sale.lastLookupBarcode, '8850012345678');
    expect(sale.lastAddedArticleCode, 'ART001');
    expect(sale.lastAddedQuantity, 3);
    expect(viewModel.cart?.guid, 'order-1');
    expect(viewModel.scanError, isNull);
  });

  test('a lookup failure surfaces the server message as scanError', () async {
    final sale = FakeSaleRepository(
      lookupError: const ApiException(messageDesc: 'Item not found'),
    );
    final viewModel = buildViewModel(saleRepository: sale);

    await viewModel.scan('8850000000000');

    expect(viewModel.scanError, 'Item not found');
    expect(viewModel.cart, isNull);
  });

  test(
    'scan without an active session sets scanError and skips the lookup',
    () async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(
        saleRepository: sale,
        currentSessionResult: null,
      );

      await viewModel.scan('8850012345678');

      expect(viewModel.scanError, isNotNull);
      expect(sale.lastLookupBarcode, isNull);
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

  test('selectPrivilege stores the chosen privilege', () {
    final viewModel = buildViewModel();
    const privilege = Privilege(name: 'Gold Member', discount: 10);

    viewModel.selectPrivilege(privilege);

    expect(viewModel.selectedPrivilege, privilege);
  });

  test('selectPrivilege(null) clears a previously chosen privilege', () {
    final viewModel = buildViewModel();
    viewModel.selectPrivilege(
      const Privilege(name: 'Gold Member', discount: 10),
    );

    viewModel.selectPrivilege(null);

    expect(viewModel.selectedPrivilege, isNull);
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
}
