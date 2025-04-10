import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Formatter {
  // Currency Input Formatter (chỉ cho phép nhập số)
  static final TextInputFormatter currencyInputFormatter =
  _CurrencyInputFormatter();

  // Helper method to get raw integer value from formatted currency text
  static int getRawCurrencyValue(String formattedText) {
    String rawText = formattedText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(rawText) ?? 0;
  }

  // Format số nguyên sang chuỗi có dấu phân cách ngàn
  static String formatCurrency(double value) {
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  // Format DateTime sang chuỗi ngày (EEEE, dd/MM/yyyy)
  static String formatDay(DateTime day) {
    final formatter = DateFormat('EEEE, dd/MM/yyyy');
    return formatter.format(day);
  }

  // Format DateTime sang chuỗi tháng (MMMM, yyyy)
  static String formatMonth(DateTime month) {
    final formatter = DateFormat('MMMM, yyyy');
    return formatter.format(month);
  }

  // Format DateTime sang chuỗi năm (yyyy)
  static String formatYear(DateTime year) {
    final formatter = DateFormat('yyyy');
    return formatter.format(year);
  }

  // Format DateTime sang chuỗi ngày tháng năm (dd/MM/yyyy)
  static String formatDate(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(date);
  }

  // Format DateTime sang chuỗi giờ phút (HH:mm)
  static String formatTime(DateTime date) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }

  // Format DateTime đầy đủ: dd/MM/yyyy HH:mm
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(date);
  }

  // Parse từ chuỗi "dd/MM/yyyy" về DateTime (nullable)
  static DateTime? parseDate(String input) {
    try {
      return DateFormat('dd/MM/yyyy').parseStrict(input);
    } catch (_) {
      return null;
    }
  }

  // Parse từ chuỗi "HH:mm" về DateTime (nullable, mặc định ngày là hôm nay)
  static DateTime? parseTime(String input) {
    try {
      final now = DateTime.now();
      final time = DateFormat('HH:mm').parseStrict(input);
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (_) {
      return null;
    }
  }
}

// Private currency formatter class
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String formattedNumber = _formatCurrency(newText);
    int selectionIndex = formattedNumber.length;

    return newValue.copyWith(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  String _formatCurrency(String rawText) {
    final buffer = StringBuffer();
    for (int i = 0; i < rawText.length; i++) {
      if (i > 0 && (rawText.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(rawText[i]);
    }
    return buffer.toString();
  }
}
