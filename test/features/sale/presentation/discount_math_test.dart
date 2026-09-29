import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/presentation/discount_math.dart';

void main() {
  group('previewLineDiscount', () {
    test('percent', () {
      final p = previewLineDiscount(
        unitPrice: 62000,
        quantity: 1,
        kind: DiscountKind.percent,
        value: 10,
      );
      expect(p.gross, 62000);
      expect(p.discount, 6200);
      expect(p.net, 55800);
      expect(p.percent, 10);
    });

    test('percent across quantity', () {
      final p = previewLineDiscount(
        unitPrice: 7800,
        quantity: 2,
        kind: DiscountKind.percent,
        value: 5,
      );
      expect(p.discount, 780);
      expect(p.net, 14820);
    });

    test('amount', () {
      final p = previewLineDiscount(
        unitPrice: 62000,
        quantity: 1,
        kind: DiscountKind.amount,
        value: 6200,
      );
      expect(p.net, 55800);
      expect(p.percent, 10);
    });

    test('new unit price', () {
      final p = previewLineDiscount(
        unitPrice: 7800,
        quantity: 2,
        kind: DiscountKind.newPrice,
        value: 7410,
      );
      expect(p.net, 14820);
      expect(p.discount, 780);
      expect(p.percent, 5);
    });

    test('values are clamped: no negative net, no mark-ups', () {
      expect(
        previewLineDiscount(
          unitPrice: 100,
          quantity: 1,
          kind: DiscountKind.percent,
          value: 150,
        ).net,
        0,
      );
      expect(
        previewLineDiscount(
          unitPrice: 100,
          quantity: 1,
          kind: DiscountKind.amount,
          value: 500,
        ).net,
        0,
      );
      expect(
        previewLineDiscount(
          unitPrice: 100,
          quantity: 1,
          kind: DiscountKind.newPrice,
          value: 250,
        ).discount,
        0,
      );
      expect(
        previewLineDiscount(
          unitPrice: 100,
          quantity: 1,
          kind: DiscountKind.percent,
          value: -5,
        ).discount,
        0,
      );
    });

    test('rounds to satang', () {
      final p = previewLineDiscount(
        unitPrice: 99.99,
        quantity: 3,
        kind: DiscountKind.percent,
        value: 7,
      );
      expect(p.discount, 21);
      expect(p.net, 278.97);
    });

    test('zero-priced line has 0% and no discount', () {
      final p = previewLineDiscount(
        unitPrice: 0,
        quantity: 1,
        kind: DiscountKind.amount,
        value: 10,
      );
      expect(p.discount, 0);
      expect(p.percent, 0);
    });
  });
}
