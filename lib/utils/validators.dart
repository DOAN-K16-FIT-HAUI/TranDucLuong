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

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng chọn danh mục';
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

  static String? validateRepaymentDate(DateTime? repaymentDate, DateTime transactionDate) {
    if (repaymentDate != null) {
      // Ngày trả không được trước ngày giao dịch (cùng ngày thì OK)
      final transactionDayStart = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
      final repaymentDayStart = DateTime(repaymentDate.year, repaymentDate.month, repaymentDate.day);
      if (repaymentDayStart.isBefore(transactionDayStart)){
        return 'Ngày hẹn trả không được trước ngày giao dịch.';
      }
    }
    return null; // Hợp lệ nếu null hoặc không trước ngày giao dịch
  }

  static String? validateBalanceAfterAdjustment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số dư thực tế.';
    }
    final amountString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(amountString);
    if (amount == null) {
      return 'Số dư không hợp lệ.';
    }
    // Có thể cho phép số dư âm tùy theo logic kinh doanh
    // if (amount < 0) {
    //   return 'Số dư không được là số âm.';
    // }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập diễn giải.';
    }
    if (value.length > 100) { // Giới hạn độ dài ví dụ
      return 'Diễn giải quá dài (tối đa 100 ký tự).';
    }
    return null;
  }

  static String? validateWallet(String? value, {String fieldName = "Ví", String? checkAgainst}) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng chọn $fieldName.';
    }
    if (checkAgainst != null && value == checkAgainst) {
      return '$fieldName không được trùng với Ví nguồn.';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, {String fieldName = "Trường này"}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName không được để trống.';
    }
    return null;
  }
}