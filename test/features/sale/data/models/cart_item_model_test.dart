import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/data/models/cart_item_model.dart';

void main() {
  test('fromJson maps legacy OrderDetail: Guid, BarCode, ItemDetail.Detail, '
      'BillingQuantity, BillingAmount', () {
    final item = CartItemModel.fromJson({
      'Guid': 'line-guid-1',
      'BarCode': '8850012345678',
      'ItemDetail': {'Detail': 'Chanel No.5 EDP 50ml', 'UnitPrice': 4200},
      'BillingQuantity': {'Quantity': 2, 'UOM': 1},
      'BillingAmount': {
        'TotalAmount': {'CurrAmt': 8400},
        'NetAmount': {'CurrAmt': 8000},
      },
    });

    expect(item.row, 'line-guid-1');
    expect(item.articleCode, '8850012345678');
    expect(item.articleName, 'Chanel No.5 EDP 50ml');
    expect(item.quantity, 2);
    expect(item.unitPrice, 4200);
    expect(item.lineTotal, 8000);
  });

  test('fromJson falls back to the earlier guessed field names', () {
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

  test('fromJson reads the line discounts (ValueAdjusts) and ceiling', () {
    final item = CartItemModel.fromJson({
      'Guid': 'line-1',
      'ItemDetail': {'Detail': 'Bag', 'MaxPercentDiscount': 20},
      'BillingAmount': {
        'DiscountAmount': {'CurrAmt': 620},
        'ValueAdjusts': [
          {
            'Guid': 'va-1',
            'VADetail': {'Code': 'PRIV10', 'Desc': 'Member 10%'},
            'Amount': {'CurrAmt': 0, 'CurrAmtForCal': 620},
            'Percent': 10,
            'IsPercent': true,
            'isAllowOverwrite': true,
            'typeDiscount': 'Privilege',
          },
        ],
      },
    });

    expect(item.maxPercentDiscount, 20);
    expect(item.discountAmount, 620);
    final discount = item.discounts.single;
    expect(discount.guid, 'va-1');
    expect(discount.code, 'PRIV10');
    expect(discount.isPercent, isTrue);
    expect(discount.percent, 10);
    expect(discount.calculatedAmount, 620);
    expect(discount.isEditable, isTrue);
    expect(discount.raw['typeDiscount'], 'Privilege');
  });
}
