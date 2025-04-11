import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Constants {
  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'Tiền mặt', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Thẻ tín dụng', 'icon': Icons.credit_card_outlined},
    {'name': 'Tiết kiệm', 'icon': Icons.savings_outlined},
    {'name': 'Đầu tư', 'icon': Icons.trending_up_outlined},
    {'name': 'Bitcoin', 'icon': Icons.currency_bitcoin_outlined},
  ];

  static List<String> getTransactionTypes(AppLocalizations l10n) {
    return [
      l10n.transactionTypeExpense,
      l10n.transactionTypeIncome,
      l10n.transactionTypeTransfer,
      l10n.transactionTypeBorrow,
      l10n.transactionTypeLend,
      l10n.transactionTypeAdjustment,
    ];
  }

  // Hàm lấy danh sách availableCategories từ l10n (nếu muốn dịch danh mục)
  static List<String> getAvailableCategories(AppLocalizations l10n) {
    return [
      'food',
      'living',
      'transport',
      'health',
      'shopping',
      'entertainment',
      'education',
      'bills',
      'gift',
      'other',
    ];
  }
}
