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
