import 'dart:ui';

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
  static String formatCurrency(double value, {required Locale locale}) {
    final formatter = NumberFormat('#,###', locale.toString());
    return formatter.format(value);
  }

  // Format DateTime sang chuỗi ngày (ví dụ: "Thứ Tư, 10 tháng Tư 2025" hoặc "Wednesday, April 10, 2025")
  static String formatDay(DateTime day, {required Locale locale}) {
    final formatter = DateFormat.yMMMMEEEEd(locale.toString());
    return formatter.format(day);
  }

  // Format DateTime sang chuỗi tháng (ví dụ: "Tháng Tư 2025" hoặc "April 2025")
  static String formatMonth(DateTime month, {required Locale locale}) {
    final formatter = DateFormat.yMMMM(locale.toString());
    return formatter.format(month);
  }

  // Format DateTime sang chuỗi năm (ví dụ: "2025")
  static String formatYear(DateTime year, {required Locale locale}) {
    final formatter = DateFormat.y(locale.toString());
    return formatter.format(year);
  }

  // Format DateTime sang chuỗi ngày tháng năm (ví dụ: "10 tháng Tư 2025" hoặc "April 10, 2025")
  static String formatDate(DateTime date, {required Locale locale}) {
    final formatter = DateFormat.yMMMMd(locale.toString());
    return formatter.format(date);
  }

  // Format DateTime sang chuỗi giờ phút (ví dụ: "14:30")
  static String formatTime(DateTime date, {required Locale locale}) {
    final formatter = DateFormat.Hm(locale.toString());
    return formatter.format(date);
  }

  // Format DateTime đầy đủ: ngày tháng năm giờ phút (ví dụ: "10 tháng Tư 2025 14:30" hoặc "April 10, 2025 2:30 PM")
  static String formatDateTime(DateTime date, {required Locale locale}) {
    final formatter = DateFormat.yMMMMd(locale.toString()).add_Hm();
    return formatter.format(date);
  }

  // Parse từ chuỗi ngày tháng về DateTime (nullable, dùng định dạng linh hoạt theo locale)
  static DateTime? parseDate(String input, {required Locale locale}) {
    try {
      return DateFormat.yMMMMd(locale.toString()).parseStrict(input);
    } catch (_) {
      // Thử định dạng khác nếu thất bại
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(input); // Định dạng mặc định
      } catch (_) {
        return null;
      }
    }
  }

  // Parse từ chuỗi giờ phút về DateTime (nullable, mặc định ngày là hôm nay)
  static DateTime? parseTime(String input, {required Locale locale}) {
    try {
      final now = DateTime.now();
      final time = DateFormat.Hm(locale.toString()).parseStrict(input);
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (_) {
      try {
        final time = DateFormat('HH:mm').parseStrict(input); // Định dạng mặc định
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, time.hour, time.minute);
      } catch (_) {
        return null;
      }
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