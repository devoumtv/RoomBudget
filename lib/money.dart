double roundMoney(double value) {
  return (value * 100).roundToDouble() / 100;
}

double? parsePrice(String raw) {
  final text = raw.trim().replaceAll(' ', '').replaceAll(',', '.');
  if (text.isEmpty || '.'.allMatches(text).length > 1) {
    return null;
  }
  final value = double.tryParse(text);
  if (value == null || value < 0 || value > 99999999) {
    return null;
  }
  return roundMoney(value);
}

String formatMoney(double value) {
  final negative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}€$buffer.${parts[1]}';
}

String? validateName(String? raw) {
  final name = raw?.trim() ?? '';
  if (name.isEmpty) {
    return 'Enter a name';
  }
  if (name.length > 40) {
    return 'Use 40 characters or fewer';
  }
  return null;
}
