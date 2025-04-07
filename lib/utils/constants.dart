import 'package:flutter/material.dart';

class Constants {
  static const List<Map<String, dynamic>> availableIcons = [
    {'name': 'Tiền mặt', 'icon': Icons.account_balance_wallet_outlined},
    {'name': 'Thẻ tín dụng', 'icon': Icons.credit_card_outlined},
    {'name': 'Tiết kiệm', 'icon': Icons.savings_outlined},
    {'name': 'Đầu tư', 'icon': Icons.trending_up_outlined},
    {'name': 'Bitcoin', 'icon': Icons.currency_bitcoin_outlined},
  ];

  static const List<String> transactionTypes = [
    'Chi tiêu',
    'Thu nhập',
    'Chuyển khoản',
    'Đi vay',
    'Cho vay',
    'Điều chỉnh số dư',
  ];

  static const List<String> availableCategories = [
    'Ẩn uống',
    'Sinh hoạt',
    'Đi lại',
    'Sức khỏe',
    'Mua sắm',
    'Giải trí',
    'Giáo dục',
    'Hóa đơn',
    'Quà tặng',
    'Khác',
  ];
}
