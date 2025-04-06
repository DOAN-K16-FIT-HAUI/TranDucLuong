import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? validateBalance(String? value, {required double currentBalance}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số dư';
    }

    // Remove any non-numeric characters (e.g., commas from currency formatting)
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) {
      return 'Số dư không hợp lệ';
    }

    final balance = double.tryParse(cleanValue);
    if (balance == null) {
      return 'Số dư phải là một số hợp lệ';
    }

    if (balance < 0) {
      return 'Số dư không thể âm';
    }

    return null;
  }

  static String? validateTransactionAmount({
    required String? value,
    required String transactionType,
    required double walletBalance,
  }) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số tiền';
    }

    // Remove any non-numeric characters (e.g., commas from currency formatting)
    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) {
      return 'Số tiền không hợp lệ';
    }

    final amount = double.tryParse(cleanValue);
    if (amount == null) {
      return 'Số tiền phải là một số hợp lệ';
    }

    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    // Validate against wallet balance for outflow transactions
    if (transactionType == 'Chi tiêu' || transactionType == 'Chuyển khoản' || transactionType == 'Cho vay') {
      if (amount > walletBalance) {
        return 'Số tiền vượt quá số dư ví (${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(walletBalance)})';
      }
    }

    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mô tả';
    }
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng chọn danh mục';
    }
    return null;
  }

  static String? validateWallet(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng chọn ví';
    }
    return null;
  }

  static String? validateNotEmpty(String? value) {
    if (value == null || value.isEmpty) {
      return 'Trường này không được để trống';
    }
    return null;
  }

  static String? validateDate(DateTime? date) {
    if (date == null) {
      return 'Vui lòng chọn ngày';
    }
    if (date.isAfter(DateTime.now())) {
      return 'Ngày không được trong tương lai';
    }
    return null;
  }

  static String? validateString(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập giá trị';
    }
    return null;
  }
}