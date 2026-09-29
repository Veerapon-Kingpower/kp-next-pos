import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/customer/domain/entities/customer.dart';

CustomerPerson _person(List<Map<String, dynamic>> wallets) => CustomerPerson(
  englishName: '',
  passportNo: '',
  nationality: '',
  contacts: const [],
  privileges: const [],
  walletMembers: wallets,
);

void main() {
  group('caratNearlyExpired', () {
    test('reads the Carat wallet, dated in Bangkok time', () {
      final expiring = _person(const [
        {
          'PaymentCode': 'CASHW',
          'NearlyExpiredAmount': 9.0,
          'NearlyExpiredAt': '2027-01-01T00:00:00Z',
        },
        {
          'PaymentCode': 'CARAT',
          'Balance': 1475.0,
          'NearlyExpiredAmount': 1475.0,
          'NearlyExpiredAt': '2029-12-31T16:59:59.999Z',
        },
      ]).caratNearlyExpired;

      expect(expiring?.amount, 1475.0);
      // 16:59:59Z is 23:59:59 on the same day at UTC+7.
      expect(
        [expiring?.at.year, expiring?.at.month, expiring?.at.day],
        [2029, 12, 31],
      );
    });

    test('null when nothing is due, the date is missing, or no Carat', () {
      expect(
        _person(const [
          {
            'PaymentCode': 'CARAT',
            'NearlyExpiredAmount': 0,
            'NearlyExpiredAt': '2029-12-31T16:59:59.999Z',
          },
        ]).caratNearlyExpired,
        isNull,
      );
      expect(
        _person(const [
          {'PaymentCode': 'CARAT', 'NearlyExpiredAmount': 5.0},
        ]).caratNearlyExpired,
        isNull,
      );
      expect(_person(const []).caratNearlyExpired, isNull);
    });
  });
}
