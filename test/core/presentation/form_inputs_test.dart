import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kp_pos/core/presentation/form_inputs.dart';

String apply(List<TextInputFormatter> formatters, String typed) {
  var value = TextEditingValue(text: typed);
  for (final f in formatters) {
    value = f.formatEditUpdate(TextEditingValue.empty, value);
  }
  return value.text;
}

void main() {
  group('formatters', () {
    test('English name keeps A–Z, space and hyphen, upper-cased', () {
      expect(apply(FormInputs.englishName, 'Jane-Doe 1ö!'), 'JANE-DOE ');
    });

    test('passport keeps A–Z and 0–9, upper-cased', () {
      expect(apply(FormInputs.passport, 'ab-12 3/x'), 'AB123X');
    });

    test('phone keeps digits, +, space and hyphen', () {
      expect(
        apply(FormInputs.phone, '+66 (81) 234-5678 ext'),
        '+66 81 234-5678 ',
      );
    });

    test('email drops whitespace, upper-cased', () {
      expect(apply(FormInputs.email, 'jane @ mail.com'), 'JANE@MAIL.COM');
    });

    test('WeChat keeps A–Z, 0–9, _ and -, upper-cased; no Thai', () {
      expect(apply(FormInputs.weChat, 'jane_wc-01 สวัสดี!'), 'JANE_WC-01');
    });

    test('upperCase upper-cases free text', () {
      expect(apply(FormInputs.upperCase, 'tg916 bkk'), 'TG916 BKK');
    });
  });

  group('validators', () {
    test('isEmail', () {
      expect(FormInputs.isEmail('jane@mail.com'), isTrue);
      expect(FormInputs.isEmail('jane@mail'), isFalse);
      expect(FormInputs.isEmail('jane.mail.com'), isFalse);
    });

    test('isPhone: 8–15 digits, optional +, spaces / hyphens ignored', () {
      expect(FormInputs.isPhone('0812345678'), isTrue);
      expect(FormInputs.isPhone('+66 81-234-5678'), isTrue);
      expect(FormInputs.isPhone('1234567'), isFalse);
      expect(FormInputs.isPhone('1234567890123456'), isFalse);
      expect(FormInputs.isPhone('08+12345678'), isFalse);
    });

    test('isPassport / isEnglishName', () {
      expect(FormInputs.isPassport('CB912447'), isTrue);
      expect(FormInputs.isPassport('CB-912447'), isFalse);
      expect(FormInputs.isEnglishName('SOFIA ALMEIDA'), isTrue);
      expect(FormInputs.isEnglishName('โซเฟีย'), isFalse);
    });
  });
}
