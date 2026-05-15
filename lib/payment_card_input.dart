import 'package:flutter/services.dart';

class PaymentExpiry {
  final String month;
  final String year;

  const PaymentExpiry({required this.month, required this.year});
}

String paymentCardDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String formatPaymentExpiry(String? month, String? year) {
  final monthDigits = paymentCardDigits(month ?? '');
  final yearDigits = paymentCardDigits(year ?? '');
  if (monthDigits.isEmpty && yearDigits.isEmpty) return '';

  final paddedMonth = monthDigits.isEmpty
      ? ''
      : monthDigits.padLeft(2, '0').substring(0, 2);
  final shortYear = yearDigits.length >= 4
      ? yearDigits.substring(yearDigits.length - 2)
      : yearDigits;

  if (paddedMonth.isEmpty) return shortYear;
  if (shortYear.isEmpty) return paddedMonth;
  return '$paddedMonth/$shortYear';
}

PaymentExpiry? parsePaymentExpiry(String value, {DateTime? now}) {
  final parts = value.trim().split('/');
  final monthText = parts.isNotEmpty ? paymentCardDigits(parts.first) : '';
  final yearText = parts.length > 1 ? paymentCardDigits(parts[1]) : '';
  if (monthText.length != 2 || (yearText.length != 2 && yearText.length != 4)) {
    return null;
  }

  final month = int.tryParse(monthText);
  final year = int.tryParse(yearText.length == 2 ? '20$yearText' : yearText);
  if (month == null || year == null || month < 1 || month > 12) return null;

  final current = now ?? DateTime.now();
  if (year < current.year ||
      (year == current.year && month < current.month) ||
      year > 2100) {
    return null;
  }

  return PaymentExpiry(
    month: month.toString().padLeft(2, '0'),
    year: year.toString(),
  );
}

class CardNumberInputFormatter extends TextInputFormatter {
  static const int _maxDigits = 19;

  const CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = paymentCardDigits(newValue.text);
    final limited = digits.length > _maxDigits
        ? digits.substring(0, _maxDigits)
        : digits;
    final groups = <String>[];
    for (var i = 0; i < limited.length; i += 4) {
      final end = i + 4 > limited.length ? limited.length : i + 4;
      groups.add(limited.substring(i, end));
    }
    final text = groups.join(' ');
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  const ExpiryDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = paymentCardDigits(newValue.text);
    if (digits.length == 1 && int.tryParse(digits)! > 1) {
      digits = '0$digits';
    }
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }

    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
