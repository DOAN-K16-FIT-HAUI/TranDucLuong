import 'package:finance_app/utils/formatter.dart';

class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập email';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
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

  static String? validateBalance(String? value){
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập số dư';
    }
    int rawValue = Formatter.getRawCurrencyValue(value);
    if (rawValue < 0) {
      return 'Số dư không được âm';
    }
    return null;
  }

  static String? validateWalletName(String? value){
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập tên ví';
    }
    return null;
  }
}
