import 'package:flutter/services.dart';

/// Upper-cases whatever is typed or pasted.
class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Input restrictions and format checks shared by the customer forms
/// (Register, Flight & passport). Formatters stop bad characters at the
/// keyboard; the validators catch values that arrive another way (e.g.
/// prefilled from an existing customer).
abstract class FormInputs {
  /// English name: A–Z, space and hyphen (legacy `validateRegister()`'s
  /// name rule), upper case.
  static final englishName = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z \-]')),
    const UpperCaseTextFormatter(),
  ];

  /// Passport no.: A–Z and 0–9 only, upper case.
  static final passport = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
    const UpperCaseTextFormatter(),
  ];

  /// Phone: digits, a leading `+`, spaces and hyphens.
  static final phone = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
  ];

  /// Email: no whitespace, upper case.
  static final email = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'\s')),
    const UpperCaseTextFormatter(),
  ];

  /// WeChat ID: A–Z, 0–9, `_` and `-` only (no Thai or other scripts),
  /// upper case.
  static final weChat = <TextInputFormatter>[
    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_\-]')),
    const UpperCaseTextFormatter(),
  ];

  /// No Thai characters (U+0E00–U+0E7F) — typed or pasted; everything else
  /// passes as typed. Used by the sign-in username / password.
  static final noThai = <TextInputFormatter>[
    FilteringTextInputFormatter.deny(RegExp(r'[฀-๿]')),
  ];

  /// Free text or a lookup query: upper case.
  static const upperCase = <TextInputFormatter>[UpperCaseTextFormatter()];

  static final _englishName = RegExp(r'^[A-Za-z \-]*$');
  static final _passport = RegExp(r'^[A-Za-z0-9]+$');
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?\d{8,15}$');

  static bool isEnglishName(String value) => _englishName.hasMatch(value);

  static bool isPassport(String value) => _passport.hasMatch(value);

  static bool isEmail(String value) => _email.hasMatch(value);

  /// 8–15 digits (the E.164 maximum), an optional leading `+`; spaces and
  /// hyphens are ignored.
  static bool isPhone(String value) =>
      _phone.hasMatch(value.replaceAll(RegExp(r'[\s\-]'), ''));
}
