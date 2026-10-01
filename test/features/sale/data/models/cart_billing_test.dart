import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/data/models/cart_item_model.dart';
import 'package:kp_pos/features/sale/data/models/cart_model.dart';
import 'package:kp_pos/features/sale/data/models/currency_model.dart';

Map<String, dynamic> _amount(double curr, {double? base}) => {
  'CurrCode': {'Code': 'USD', 'Desc': 'US Dollar'},
  'CurrRate': 35.5,
  'CurrAmt': curr,
  'BaseCurrCode': {'Code': 'THB', 'Desc': 'Thai Baht'},
  'BaseCurrRate': 1,
  'BaseCurrAmt': base ?? curr * 35.5,
};

void main() {
  test('CurrencyModel reads the GetCurrency row', () {
    final c = CurrencyModel.fromJson({
      'branch_no': '03',
      'curr_code': 'USD',
      'curr_desc': 'US Dollar',
      'curr_rate': 35.5,
      'curr_short': r'$',
    });
    expect(c.code, 'USD');
    expect(c.description, 'US Dollar');
    expect(c.rate, 35.5);
    expect(c.symbol, r'$');
  });

  test('CartModel reads the Checkout extras: bill discount, promotion, '
      'GWP, signature, DFA / promoter', () {
    final cart = CartModel.fromJson({
      'Guid': 'order-1',
      'BillingAmount': {'TotalAmount': _amount(100)},
      'TotalBillingAmount': {
        'PercentDiscountSpecial': 10,
        'DiscountSpecial': _amount(59),
        'CurrentValueAdjust': {
          'VADetail': {'Code': 'SP10', 'Desc': 'Special 10%'},
        },
        'ValueAdjusts': [
          {
            'Guid': 'va-1',
            'VADetail': {'Code': 'SP10', 'Desc': 'Special 10%'},
            'IsPercent': true,
            'Percent': 10,
            'isAllowOverwrite': true,
          },
        ],
      },
      'GWPDetails': [
        {'DetailTextShow': 'Free pouch', 'CanApplied': true},
      ],
      'isRequireSignature': true,
      'DFA': 'D01',
      'Promoter': 'PR9',
      'CreateDate': '2026-10-01T10:00:00',
    });

    expect(cart.billing!.percentDiscountSpecial, 10);
    expect(cart.billing!.discountSpecial, 59);
    expect(cart.billing!.promotionCode, 'SP10');
    expect(cart.billing!.promotionName, 'Special 10%');
    expect(cart.billDiscounts.single.guid, 'va-1');
    expect(cart.billDiscounts.single.allowOverwrite, isTrue);
    expect(cart.giftsWithPurchase.single.text, 'Free pouch');
    expect(cart.giftsWithPurchase.single.canApply, isTrue);
    expect(cart.requireSignature, isTrue);
    expect(cart.dfa, 'D01');
    expect(cart.promoter, 'PR9');
    expect(cart.createDate, '2026-10-01T10:00:00');
  });

  test('CartModel reads BillingAmount / TotalBillingAmount in the order '
      'currency (legacy OrderClass)', () {
    final cart = CartModel.fromJson({
      'Guid': 'g1',
      'isCheckOut': false,
      'OrderDetails': [],
      'BillingAmount': {'TotalAmount': _amount(200), 'NetAmount': _amount(190)},
      'TotalBillingAmount': {
        'NetAmount': _amount(180),
        'DiscountAmount': _amount(10),
        'TotalSubsidize': _amount(5),
        'TotalNetPay': _amount(175, base: 6212.5),
      },
    });

    final billing = cart.billing!;
    expect(billing.currencyCode, 'USD');
    expect(billing.currencyDescription, 'US Dollar');
    expect(billing.currencyRate, 35.5);
    expect(billing.total, 190);
    expect(billing.grand, 180);
    expect(billing.discount, 10);
    expect(billing.cashD, 5);
    expect(billing.netPay, 175);
    expect(billing.netPayBase, 6212.5);
    expect(billing.isBaht, isFalse);
  });

  test('CartModel has no billing when the order carries none', () {
    final cart = CartModel.fromJson({'Guid': 'g1', 'OrderDetails': []});
    expect(cart.billing, isNull);
  });

  test('a line with legacy BillingQuantity / BillingAmount takes its '
      'amounts from them', () {
    final item = CartItemModel.fromJson({
      'Row': '1',
      'ItemCode': 'A1',
      'ItemName': 'Item',
      'Price': 999, // guessed key; the billing amount wins
      'BillingQuantity': {'Quantity': 2, 'UOM': 1},
      'BillingAmount': {'TotalAmount': _amount(100), 'NetAmount': _amount(90)},
    });
    expect(item.quantity, 2);
    expect(item.unitPrice, 50);
    expect(item.lineTotal, 90);
  });

  test('a line reads legacy recordInfos (MessageType / Code / Desc)', () {
    final item = CartItemModel.fromJson({
      'Guid': 'r1',
      'recordInfos': [
        {
          'MessageType': 'Error',
          'MessageCode': 'REQUIRE_SN',
          'MessageDesc': 'Serial number is required.',
        },
        {'MessageType': 'Warning', 'MessageCode': 'W', 'MessageDesc': 'Low'},
      ],
    });
    expect(item.recordInfos, hasLength(2));
    expect(item.recordInfos.first.code, 'REQUIRE_SN');
    expect(item.recordInfos.first.desc, 'Serial number is required.');
    expect(item.hasRecordError, isTrue);
    expect(CartItemModel.fromJson({'Guid': 'r2'}).recordInfos, isEmpty);
  });

  test('CartModel reads order_no from HeaderAttributes, as a whole number', () {
    final cart = CartModel.fromJson({
      'Guid': 'o',
      'HeaderAttributes': [
        {'Code': 'ShipAddress', 'ValueOfString': ''},
        {'Code': 'order_no', 'ValueOfDecimal': 20260930001.0},
      ],
    });
    expect(cart.orderNo, '20260930001');
  });

  test('CartModel has no orderNo without an order_no attribute', () {
    expect(CartModel.fromJson({'Guid': 'o'}).orderNo, '');
  });
}
