import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Validators {
  static String? validateEmail(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.enterEmailHint;
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return l10n.invalidEmail;
    return null;
  }

  static String? validatePassword(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.enterPasswordHint;
    if (value.length < 6) return l10n.passwordMinLength;
    return null;
  }

  static String? validateBalance(String? value, {required double currentBalance, AppLocalizations? l10n}) { // Thêm l10n tùy chọn
    if (value == null || value.isEmpty) return l10n?.pleaseEnterBalance; // Key mới

    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return l10n?.invalidBalance; // Key mới

    final balance = double.tryParse(cleanValue);
    if (balance == null) return l10n?.invalidBalance; // Key mới

    if (balance < 0) return l10n?.balanceCannotBeNegative; // Key mới

    return null;
  }

  static String? validateTransactionAmount({
    required String? value,
    required String transactionType,
    required double walletBalance,
    required AppLocalizations l10n,
  }) {
    if (value == null || value.isEmpty) return l10n.enterAmountHint;

    final cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isEmpty) return l10n.invalidAmount;

    final amount = double.tryParse(cleanValue);
    if (amount == null) return l10n.invalidAmount;
    if (amount <= 0) return l10n.amountMustBePositive;

    // !! So sánh type gốc !!
    if (transactionType == 'expense' || transactionType == 'transfer' || transactionType == 'lend') {
      if (amount > walletBalance) {
        final locale = Intl.getCurrentLocale();
        final formattedBalance = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0).format(walletBalance);
        return l10n.insufficientBalanceShortError(formattedBalance);
      }
    }
    return null;
  }

  static String? validateCategory(String? value, {AppLocalizations? l10n}) { // Thêm l10n tùy chọn
    if (value == null || value.isEmpty) return l10n?.pleaseSelectCategory; // Key mới
    return null;
  }

  static String? validateDate(DateTime? date, {AppLocalizations? l10n}) { // Thêm l10n tùy chọn
    if (date == null) return l10n?.pleaseSelectDate;
    // Bỏ kiểm tra ngày tương lai nếu bạn cho phép
    // if (date.isAfter(DateTime.now())) return l10n.dateCannotBeInFuture;
    return null;
  }

  static String? validateString(String? value, {AppLocalizations? l10n}) { // Thêm l10n tùy chọn
    if (value == null || value.isEmpty) return l10n?.pleaseEnterValue; // Key mới
    return null;
  }

  static String? validateRepaymentDate(DateTime? repaymentDate, DateTime transactionDate, {AppLocalizations? l10n}) {
    if (repaymentDate != null) {
      final transactionDayStart = DateTime(transactionDate.year, transactionDate.month, transactionDate.day);
      final repaymentDayStart = DateTime(repaymentDate.year, repaymentDate.month, repaymentDate.day);
      if (repaymentDayStart.isBefore(transactionDayStart)){
        return l10n?.repaymentDateCannotBeBeforeTransactionDate;
      }
    }
    return null;
  }

  static String? validateBalanceAfterAdjustment(String? value, {AppLocalizations? l10n}) {
    if (value == null || value.isEmpty) return l10n?.pleaseEnterActualBalance;
    final amountString = value.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(amountString);
    if (amount == null) return l10n?.invalidBalance;
    return null;
  }

  static String? validateDescription(String? value, {AppLocalizations? l10n}) { // Thêm l10n tùy chọn
    if (value == null || value.trim().isEmpty) return l10n?.pleaseEnterDescription; // Key mới
    if (value.length > 100) return l10n?.descriptionTooLong; // Key mới
    return null;
  }

  static String? validateWallet(String? value, {required String fieldName, String? checkAgainst, AppLocalizations? l10n}) {
    if (value == null || value.isEmpty) return l10n?.pleaseSelectField(fieldName);
    if (checkAgainst != null && value == checkAgainst) return l10n?.fieldCannotBeSameAsSource(fieldName);
    return null;
  }

  static String? validateNotEmpty(String? value, {required String fieldName, AppLocalizations? l10n}) {
    if (value == null || value.trim().isEmpty) return l10n?.fieldCannotBeEmpty(fieldName);
    return null;
  }
}