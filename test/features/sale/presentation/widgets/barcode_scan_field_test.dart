import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:kp_pos/features/sale/presentation/widgets/barcode_scan_field.dart';

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

  testWidgets('a successful scan clears the field and shows the cart count', (
    tester,
  ) async {
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
            quantity: 1,
            unitPrice: 100,
            lineTotal: 100,
          ),
          CartItem(
            row: '2',
            articleCode: 'ART001',
            articleName: 'Test Article',
            quantity: 1,
            unitPrice: 100,
            lineTotal: 100,
          ),
        ],
      ),
    );
    final viewModel = buildViewModel(sale);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BarcodeScanField(viewModel: viewModel)),
      ),
    );

    await tester.enterText(find.byType(TextField), '2*8850012345678');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('2 item(s) in cart'), findsOneWidget);
    expect(find.text('2*8850012345678'), findsNothing);
  });

  testWidgets(
    'a scan served from the offline cache shows a "may be outdated" notice',
    (tester) async {
      final cachedAt = DateTime.utc(2026, 1, 2, 3, 4);
      final sale = FakeSaleRepository(
        lookupResult: Article(
          articleCode: 'ART001',
          articleName: 'Test Article',
          eanCode: '8850012345678',
          brandCode: 'B1',
          brandName: 'Brand One',
          price: 100,
          vatRate: 7,
          cachedAt: cachedAt,
        ),
        cartResult: const Cart(guid: 'order-1', isCheckOut: false, items: []),
      );
      final viewModel = buildViewModel(sale);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BarcodeScanField(viewModel: viewModel)),
        ),
      );

      await tester.enterText(find.byType(TextField), '8850012345678');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('may be outdated'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    },
  );

  testWidgets(
    'a malformed scan shows the format error and keeps the field text',
    (tester) async {
      final sale = FakeSaleRepository();
      final viewModel = buildViewModel(sale);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BarcodeScanField(viewModel: viewModel)),
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.text('Scan input is empty.'), findsOneWidget);
      expect(sale.lastLookupBarcode, isNull);
    },
  );
}
