// lib/core/number_formatting.dart
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String decimalSeparatorOf(BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.decimalPattern(locale).symbols.DECIMAL_SEP;
}

// Cantidades (hasta 8 decimales, sin ceros forzados)
String formatQuantity(num value, BuildContext context, {int minDecimals = 0, int maxDecimals = 8}) {
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.decimalPattern(locale)
    ..minimumFractionDigits = minDecimals
    ..maximumFractionDigits = maxDecimals;
  return f.format(value);
}

// Porcentajes (solo número; añade "%" fuera si lo necesitas)
String formatPercent(num value, BuildContext context, {int decimals = 2}) {
  final locale = Localizations.localeOf(context).toString();
  final pattern = '0.${'0' * decimals}';
  return NumberFormat(pattern, locale).format(value);
}

String formatPercentLabel(num percentValue, BuildContext context, {int decimals = 2}) {
  final locale = Localizations.localeOf(context).toString();
  final f = NumberFormat.percentPattern(locale)
    ..minimumFractionDigits = decimals
    ..maximumFractionDigits = decimals;
  // percentValue llega como 12.34 para 12,34 % → dividir entre 100
  return f.format(percentValue / 100.0);
}

// Moneda dinámica con código ISO (Frankfurter) y locale activa
String formatMoney(double amount, String currencyCode, BuildContext context) {
  final locale = Localizations.localeOf(context).toString();
  return NumberFormat.simpleCurrency(locale: locale, name: currencyCode).format(amount);
}
