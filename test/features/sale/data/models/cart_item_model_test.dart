import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/data/models/cart_item_model.dart';

void main() {
  test('fromJson maps the mock OrderDetails field names', () {
    final item = CartItemModel.fromJson({
      'Row': '1',
      'ItemCode': 'ART001',
      'ItemName': 'Test Article',
      'Qty': 2,
      'Price': 50,
      'Amount': 100,
    });

    expect(item.row, '1');
    expect(item.articleCode, 'ART001');
    expect(item.articleName, 'Test Article');
    expect(item.quantity, 2);
    expect(item.unitPrice, 50);
    expect(item.lineTotal, 100);
  });

  test(
    'fromJson computes lineTotal from unitPrice * quantity when Amount is absent',
    () {
      final item = CartItemModel.fromJson({
        'Row': '1',
        'ItemCode': 'ART001',
        'ItemName': 'Test Article',
        'Qty': 3,
        'Price': 20,
      });

      expect(item.lineTotal, 60);
    },
  );

  test('fromJson defaults quantity to 1 when Qty is absent', () {
    final item = CartItemModel.fromJson({
      'Row': '1',
      'ItemCode': 'ART001',
      'ItemName': 'Test Article',
    });

    expect(item.quantity, 1);
  });
}
