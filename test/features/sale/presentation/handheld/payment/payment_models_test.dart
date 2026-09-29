import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/features/sale/presentation/handheld/payment/payment_models.dart';

void main() {
  group('detectWalletProvider', () {
    final cases = {
      '281234567890124417': WalletProvider.alipay, // 18 digits, 28 prefix
      '25123456789012345': WalletProvider.alipay, // 17 digits
      '301234567890123456789012': WalletProvider.alipay, // 24 digits
      '134567890123456789': WalletProvider.wechatPay, // 18 digits, 13 prefix
      '101234567890123456': WalletProvider.wechatPay,
      '15 1234 5678 9012 3456': WalletProvider.wechatPay, // spaces ignored
      '8850012345678': WalletProvider.unknown, // EAN-13, not a wallet code
      '1312345678': WalletProvider.unknown, // too short
      '': WalletProvider.unknown,
      'ABC': WalletProvider.unknown,
    };
    for (final entry in cases.entries) {
      test('"${entry.key}" -> ${entry.value.name}', () {
        expect(detectWalletProvider(entry.key), entry.value);
      });
    }
  });

  test('maskPaymentCode keeps the first 2 and last 4 digits', () {
    expect(maskPaymentCode('281234567890124417'), '28 •••• 4417');
    expect(maskPaymentCode('123'), '123');
  });

  test('Tender.isSettled only for approved tenders', () {
    const pending = Tender(
      method: TenderMethod.card,
      title: 'Card · entry 2',
      amount: 100,
      status: TenderStatus.pending,
    );
    expect(pending.isSettled, isFalse);
    expect(
      const Tender(
        method: TenderMethod.wallet,
        title: 'Alipay',
        amount: 100,
        status: TenderStatus.approved,
      ).isSettled,
      isTrue,
    );
  });

  test('tenderedTotal sums approved tenders only', () {
    const tenders = [
      Tender(
        method: TenderMethod.card,
        title: 'Visa',
        amount: 40000,
        status: TenderStatus.approved,
      ),
      Tender(
        method: TenderMethod.card,
        title: 'Card',
        amount: 27370,
        status: TenderStatus.pending,
      ),
      Tender(
        method: TenderMethod.wallet,
        title: 'Alipay',
        amount: 20000,
        status: TenderStatus.approved,
      ),
    ];
    expect(tenderedTotal(tenders), 60000);
  });
}
