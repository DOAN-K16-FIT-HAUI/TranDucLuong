import 'package:flutter/services.dart';

class Formatter {
  // Currency Input Formatter (chỉ cho phép nhập số)
  static final TextInputFormatter currencyInputFormatter =
      _CurrencyInputFormatter();

  // Helper method to get raw integer value from formatted text
  static int getRawCurrencyValue(String formattedText) {
    // Loại bỏ tất cả ký tự không phải số
    String rawText = formattedText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(rawText) ?? 0;
  }
}

// Private currency formatter class
class _CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Loại bỏ tất cả ký tự không phải là số
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Nếu nhập rỗng, trả về trường rỗng
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Format lại số với dấu phân cách ngàn nhưng không có ký hiệu tiền tệ
    String formattedNumber = _formatCurrency(newText);

    // Cập nhật vị trí con trỏ để nó nằm ở cuối
    int selectionIndex = formattedNumber.length;

    return newValue.copyWith(
      text: formattedNumber,
      selection: TextSelection.collapsed(offset: selectionIndex),
    );
  }

  // Hàm format lại số với dấu phân cách ngàn
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
