/// Rupee amount with thousands grouping, e.g. `Rs. 1,000` or `Rs. 1,876.50`.
/// [decimals] defaults to 0 (whole rupees).
String formatCurrency(num value, {int decimals = 0}) =>
    'Rs. ${_grouped(value, decimals)}';

/// Coin amount with grouping + the coin glyph, e.g. `1,067 🪙`.
String formatCoins(num value, {int decimals = 0}) =>
    '${_grouped(value, decimals)} 🪙';

String formatPercent(double value) => '${(value * 100).round()}%';

String formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

/// Fixed-decimal number with commas every 3 digits in the integer part.
String _grouped(num value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
  final dot = fixed.indexOf('.');
  final intPart = dot == -1 ? fixed : fixed.substring(0, dot);
  final frac = dot == -1 ? '' : fixed.substring(dot);
  final neg = intPart.startsWith('-');
  final digits = neg ? intPart.substring(1) : intPart;

  final buf = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return '${neg ? '-' : ''}$buf$frac';
}

// ponytail: self-check the grouping/decimals — run `dart lib/formatters.dart`.
void main() {
  assert(formatCurrency(1000) == 'Rs. 1,000');
  assert(formatCurrency(1876) == 'Rs. 1,876');
  assert(formatCurrency(1876.5, decimals: 2) == 'Rs. 1,876.50');
  assert(formatCurrency(999) == 'Rs. 999');
  assert(formatCurrency(1000000) == 'Rs. 1,000,000');
  assert(formatCoins(1067) == '1,067 🪙');
  assert(formatPercent(0.8) == '80%');
  print('formatters self-check ok');
}
