import 'package:intl/intl.dart';

double? parseProgressValue(Object? value, {String locale = 'en'}) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final normalized = trimmed.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
  return null;
}

String formatProgressValue(double? value, String locale) {
  if (value == null) return '-';
  return NumberFormat.decimalPattern(locale).format(value);
}

String formatShortDate(DateTime date, String locale) {
  return DateFormat.yMMMd(locale).format(date);
}
