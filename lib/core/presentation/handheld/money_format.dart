/// Money formatting for the handheld screens — `95,550.00` style, two
/// decimals, comma thousands, a true minus sign (−) for negatives as in the
/// mockup. Kept dependency-free (no `intl`) since THB is the only display
/// currency today.
String formatAmount(double value) {
  final negative = value < 0;
  final cents = (value.abs() * 100).round();
  final whole = (cents ~/ 100).toString();
  final fraction = (cents % 100).toString().padLeft(2, '0');

  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  return '${negative ? '−' : ''}$grouped.$fraction';
}

/// [formatAmount] with the baht sign: `฿87,370.00`, `−฿255.00`.
String formatBaht(double value) =>
    value < 0 ? '−฿${formatAmount(-value)}' : '฿${formatAmount(value)}';

/// A member's Carat balance — `1,475.00`; "—" when there's no Carat wallet.
String formatCarat(double? value) => value == null ? '—' : formatAmount(value);

/// A member's e-Purse (cash wallet) balance — `฿0.00`; "—" when there's no
/// cash wallet.
String formatEPurse(double? value) => value == null ? '—' : formatBaht(value);

/// Carat nearly expiring — `1,475.00 expiring 31/12/2029`; the date in
/// legacy's `d/MM/yyyy` form.
String formatCaratExpiring(double amount, DateTime at) =>
    '${formatAmount(amount)} expiring '
    '${at.day}/${at.month.toString().padLeft(2, '0')}/${at.year}';

/// An amount in [currencyCode]: baht keeps the `฿` form ([formatBaht]),
/// any other currency is prefixed with its code — `USD 166.20`, as legacy
/// shows an order that was switched to another currency.
String formatMoney(double value, String currencyCode) {
  if (currencyCode.isEmpty || currencyCode == 'THB') return formatBaht(value);
  return value < 0
      ? '−$currencyCode ${formatAmount(-value)}'
      : '$currencyCode ${formatAmount(value)}';
}
