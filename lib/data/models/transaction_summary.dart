import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionSummary {
  final String id; // Usually yearMonth format (e.g., "2023-05")
  final String userId;
  final String year;
  final String month;
  final double totalIncome;
  final double totalExpense;
  final double totalTransfer;
  final double totalBorrow;
  final double totalLend;
  final Map<String, double> categoryExpenses; // Category key -> amount
  final Map<String, double> walletChanges; // Wallet path -> net change

  TransactionSummary({
    required this.id,
    required this.userId,
    required this.year,
    required this.month,
    this.totalIncome = 0.0,
    this.totalExpense = 0.0,
    this.totalTransfer = 0.0,
    this.totalBorrow = 0.0,
    this.totalLend = 0.0,
    required this.categoryExpenses,
    required this.walletChanges,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'year': year,
      'month': month,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalTransfer': totalTransfer,
      'totalBorrow': totalBorrow,
      'totalLend': totalLend,
      'categoryExpenses': categoryExpenses,
      'walletChanges': walletChanges,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  factory TransactionSummary.fromJson(Map<String, dynamic> json, String id) {
    // Helper function to parse map of doubles
    Map<String, double> parseDoubleMap(Map<String, dynamic>? map) {
      if (map == null) return {};

      return map.map((key, value) {
        final doubleValue =
            value is num
                ? value.toDouble()
                : double.tryParse(value.toString()) ?? 0.0;
        return MapEntry(key, doubleValue);
      });
    }

    return TransactionSummary(
      id: id,
      userId: json['userId'] as String? ?? '',
      year: json['year'] as String? ?? '',
      month: json['month'] as String? ?? '',
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0.0,
      totalTransfer: (json['totalTransfer'] as num?)?.toDouble() ?? 0.0,
      totalBorrow: (json['totalBorrow'] as num?)?.toDouble() ?? 0.0,
      totalLend: (json['totalLend'] as num?)?.toDouble() ?? 0.0,
      categoryExpenses: parseDoubleMap(
        json['categoryExpenses'] as Map<String, dynamic>?,
      ),
      walletChanges: parseDoubleMap(
        json['walletChanges'] as Map<String, dynamic>?,
      ),
    );
  }

  TransactionSummary copyWith({
    String? id,
    String? userId,
    String? year,
    String? month,
    double? totalIncome,
    double? totalExpense,
    double? totalTransfer,
    double? totalBorrow,
    double? totalLend,
    Map<String, double>? categoryExpenses,
    Map<String, double>? walletChanges,
  }) {
    return TransactionSummary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      year: year ?? this.year,
      month: month ?? this.month,
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      totalTransfer: totalTransfer ?? this.totalTransfer,
      totalBorrow: totalBorrow ?? this.totalBorrow,
      totalLend: totalLend ?? this.totalLend,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      walletChanges: walletChanges ?? this.walletChanges,
    );
  }
}
