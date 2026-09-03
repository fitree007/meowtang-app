import 'package:intl/intl.dart';

class CurrencyFormat {
  static final NumberFormat _numberFormat = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _intFormat = NumberFormat('#,##0', 'en_US');

  /// Formats numbers with comma separators, e.g., 1000 -> "1,000", 12500.5 -> "12,500.50"
  static String format(double amount, {bool trimZero = false}) {
    if (amount.isNaN || amount.isInfinite) return '0.00';
    if (trimZero && amount.truncateToDouble() == amount) {
      return _intFormat.format(amount);
    }
    return _numberFormat.format(amount);
  }

  /// Formats numbers with currency symbol (Default ฿)
  static String formatWithUnit(double amount, {String unit = '฿', bool space = true, bool trimZero = false}) {
    final str = format(amount, trimZero: trimZero);
    return space ? '$str $unit' : '$str$unit';
  }
}

class FormatUtils {
  static String formatMoney(double amount, {bool trimZero = false}) {
    return CurrencyFormat.format(amount, trimZero: trimZero);
  }

  static String formatCurrency(double amount, {bool trimZero = false}) {
    return CurrencyFormat.format(amount, trimZero: trimZero);
  }

  static String formatDateThai(DateTime date) {
    const thaiMonths = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.'
    ];
    final thaiYear = date.year > 2500 ? date.year : date.year + 543;
    return '${date.day} ${thaiMonths[date.month - 1]} $thaiYear';
  }
}
