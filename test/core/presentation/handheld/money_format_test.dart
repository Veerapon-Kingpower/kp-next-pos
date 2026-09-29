import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/handheld/money_format.dart';

void main() {
  group('formatAmount', () {
    final cases = {
      0.0: '0.00',
      5.5: '5.50',
      999.999: '1,000.00',
      5900.0: '5,900.00',
      95550.0: '95,550.00',
      1234567.891: '1,234,567.89',
      -780.0: '−780.00',
    };
    for (final entry in cases.entries) {
      test('${entry.key} -> ${entry.value}', () {
        expect(formatAmount(entry.key), entry.value);
      });
    }
  });

  test('formatBaht prefixes the baht sign', () {
    expect(formatBaht(87370), '฿87,370.00');
    expect(formatBaht(-255), '−฿255.00');
  });

  test('formatCaratExpiring reads amount and d/MM/yyyy date', () {
    expect(
      formatCaratExpiring(1475, DateTime.utc(2029, 12, 31)),
      '1,475.00 expiring 31/12/2029',
    );
    expect(
      formatCaratExpiring(20, DateTime.utc(2027, 3, 5)),
      '20.00 expiring 5/03/2027',
    );
  });
}
