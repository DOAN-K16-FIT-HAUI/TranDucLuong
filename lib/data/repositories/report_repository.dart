import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';

class ReportRepository {
  final FirestoreService _firestoreService;

  ReportRepository(this._firestoreService);

  Future<List<TransactionModel>> getTransactions(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final querySnapshot = await _firestoreService.firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .orderBy('date')
          .get();

      return querySnapshot.docs.map((doc) {
        return TransactionModel.fromJson(
          doc.data(),
          doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<Map<String, double>> getCategoryExpenses(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactions(userId, startDate, endDate);
      final filtered = transactions
          .where((t) => t.typeKey == 'expense')
          .toList();

      final categoryTotals = <String, double>{};
      for (var transaction in filtered) {
        final category =
        transaction.categoryKey.isNotEmpty ? transaction.categoryKey : 'other';
        categoryTotals[category] =
            (categoryTotals[category] ?? 0.0) + transaction.amount;
      }
      return categoryTotals;
    } catch (e) {
      throw Exception('Failed to fetch category expenses: $e');
    }
  }

  Future<Map<DateTime, double>> getDailyBalances(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactions(userId, startDate, endDate);
      final filtered = transactions
        ..sort((a, b) => a.date.compareTo(b.date));

      final dailyBalances = <DateTime, double>{};
      double runningBalance = 0.0;

      for (var date = startDate;
      date.isBefore(endDate.add(const Duration(days: 1)));
      date = date.add(const Duration(days: 1))) {
        final dayTransactions = filtered.where((t) =>
        t.date.day == date.day &&
            t.date.month == date.month &&
            t.date.year == date.year).toList();
        for (var t in dayTransactions) {
          if (t.typeKey == 'income' || t.typeKey == 'borrow') {
            runningBalance += t.amount;
          } else if (t.typeKey == 'expense' || t.typeKey == 'lend') {
            runningBalance -= t.amount;
          } else if (t.typeKey == 'transfer') {
            continue;
          } else if (t.typeKey == 'adjustment' && t.balanceAfter != null) {
            runningBalance = t.balanceAfter!;
          }
        }
        dailyBalances[DateTime(date.year, date.month, date.day)] =
            runningBalance;
      }
      return dailyBalances;
    } catch (e) {
      throw Exception('Failed to fetch daily balances: $e');
    }
  }

  Future<Map<String, Map<String, dynamic>>> getTransactionTypeTotals(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await getTransactions(userId, startDate, endDate);
      final typeTotals = <String, Map<String, dynamic>>{
        'income': {'amount': 0.0, 'color': AppTheme.incomeColor},
        'expense': {'amount': 0.0, 'color': AppTheme.expenseColor},
        'transfer': {'amount': 0.0, 'color': AppTheme.transferColor},
        'borrow': {'amount': 0.0, 'color': AppTheme.borrowColor},
        'lend': {'amount': 0.0, 'color': AppTheme.lendColor},
        'adjustment': {'amount': 0.0, 'color': AppTheme.adjustmentColor},
      };

      for (var t in transactions) {
        if (typeTotals.containsKey(t.typeKey)) {
          typeTotals[t.typeKey]!['amount'] =
              (typeTotals[t.typeKey]!['amount'] as double) + t.amount;
        }
      }

      return Map.fromEntries(
          typeTotals.entries.where((entry) => entry.value['amount'] > 0));
    } catch (e) {
      throw Exception('Failed to fetch transaction type totals: $e');
    }
  }
}