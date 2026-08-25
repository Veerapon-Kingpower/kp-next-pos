import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/auth/domain/entities/user_session.dart';
import 'package:kp_pos/features/auth/domain/usecases/restore_session_usecase.dart';
import 'package:kp_pos/features/sale/domain/entities/cart.dart';
import 'package:kp_pos/features/sale/domain/entities/cart_item.dart';
import 'package:kp_pos/features/sale/domain/usecases/add_item_to_cart_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/lookup_article_by_barcode_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/remove_cart_item_usecase.dart';
import 'package:kp_pos/features/sale/domain/usecases/update_cart_item_quantity_usecase.dart';
import 'package:kp_pos/features/sale/presentation/sale_cart_view_model.dart';
import 'package:kp_pos/features/sale/presentation/widgets/cart_list.dart';

import '../../../auth/fake_auth_repository.dart';
import '../../fake_sale_repository.dart';

void main() {
  const session = UserSession(
    sessionKey: 'abc123',
    branchNo: '03',
    userCode: 'U001',
    userName: 'Test User',
    authorizedActions: [],
  );

  SaleCartViewModel buildViewModel(FakeSaleRepository sale) {
    return SaleCartViewModel(
      restoreSession: RestoreSessionUseCase(
        FakeAuthRepository(currentSessionResult: session),
      ),
      lookupArticle: LookupArticleByBarcodeUseCase(sale),
      addItemToCart: AddItemToCartUseCase(sale),
      updateCartItemQuantity: UpdateCartItemQuantityUseCase(sale),
      removeCartItem: RemoveCartItemUseCase(sale),
    );
  }

  testWidgets('shows an empty state when the cart has no items', (
    tester,
  ) async {
    final viewModel = buildViewModel(FakeSaleRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartList(viewModel: viewModel)),
      ),
    );

    expect(find.text('Cart is empty. Scan an item to add it.'), findsOneWidget);
  });

  testWidgets('renders a tile per cart item with name, quantity, and total', (
    tester,
  ) async {
    final sale = FakeSaleRepository();
    final viewModel = buildViewModel(sale);
    viewModel.cart = const Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [
        CartItem(
          row: '1',
          articleCode: 'ART001',
          articleName: 'Test Article',
          quantity: 2,
          unitPrice: 50,
          lineTotal: 100,
        ),
      ],
    );
    viewModel.update();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartList(viewModel: viewModel)),
      ),
    );

    expect(find.text('Test Article'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('฿100.00'), findsOneWidget);
  });

  testWidgets('tapping the trash icon removes the row', (tester) async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
    );
    final viewModel = buildViewModel(sale);
    viewModel.cart = const Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [
        CartItem(
          row: '1',
          articleCode: 'ART001',
          articleName: 'Test Article',
          quantity: 1,
          unitPrice: 50,
          lineTotal: 50,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartList(viewModel: viewModel)),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(sale.lastRemovedRow, '1');
  });

  testWidgets('tapping + increases the quantity for that row', (tester) async {
    final sale = FakeSaleRepository(
      cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
    );
    final viewModel = buildViewModel(sale);
    viewModel.cart = const Cart(
      guid: 'order-1',
      isCheckOut: false,
      items: [
        CartItem(
          row: '1',
          articleCode: 'ART001',
          articleName: 'Test Article',
          quantity: 1,
          unitPrice: 50,
          lineTotal: 50,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: CartList(viewModel: viewModel)),
      ),
    );

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    expect(sale.lastUpdatedRow, '1');
    expect(sale.lastUpdatedQuantity, 2);
  });
}
