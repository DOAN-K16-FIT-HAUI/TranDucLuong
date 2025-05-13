/// Data point for category expenses chart
class CategoryDataPoint {
  final String category;
  final double amount;

  CategoryDataPoint(this.category, this.amount);

  @override
  String toString() =>
      'CategoryDataPoint{category: $category, amount: $amount}';
}

/// Data point for balance over time chart
class BalanceDataPoint {
  final DateTime date;
  final double balance;

  BalanceDataPoint(this.date, this.balance);

  @override
  String toString() => 'BalanceDataPoint{date: $date, balance: $balance}';
}

/// Data point for transaction type chart
class TypeDataPoint {
  final String type;
  final double amount;

  TypeDataPoint(this.type, this.amount);

  @override
  String toString() => 'TypeDataPoint{type: $type, amount: $amount}';
}

/// Data point for wallet expense breakdown
class WalletDataPoint {
  final String wallet;
  final double amount;

  WalletDataPoint(this.wallet, this.amount);

  @override
  String toString() => 'WalletDataPoint{wallet: $wallet, amount: $amount}';
}
