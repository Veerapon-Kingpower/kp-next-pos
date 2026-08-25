import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/error/app_exception.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/sale/domain/entities/article.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
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
}
