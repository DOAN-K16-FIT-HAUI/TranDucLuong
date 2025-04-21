import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';

class ReportRepository {
  final FirestoreService _firestoreService;

  ReportRepository(this._firestoreService);

  // Hàm lấy danh sách giao dịch
  Future<List<TransactionModel>> _fetchTransactions(String userId) async {
    try {
      // Truy vấn từ collection cấp cao "transactions"
      final querySnapshot = await _firestoreService.firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId) // Lọc giao dịch của người dùng hiện tại
          .orderBy('date') // Sắp xếp theo trường 'date'
          .get();

      return querySnapshot.docs.map((doc) {
        // Ánh xạ dữ liệu từ Firestore thành TransactionModel
        return TransactionModel.fromJson(
          doc.data(),
          doc.id, // Truyền document ID vào fromJson
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Hàm lấy danh sách chi phí theo danh mục
  Future<Map<String, double>> getCategoryExpenses(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _fetchTransactions(userId);
      final filtered = transactions
          .where((t) =>
      t.typeKey == 'expense' &&
          t.date.isAfter(startDate) &&
          t.date.isBefore(endDate))
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

  // Hàm lấy số dư hàng ngày
  Future<Map<DateTime, double>> getDailyBalances(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _fetchTransactions(userId);
      final filtered = transactions
          .where((t) => t.date.isAfter(startDate) && t.date.isBefore(endDate))
          .toList()
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
            // Chuyển khoản không ảnh hưởng đến tổng số dư
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

  // Hàm lấy tổng theo loại giao dịch với thông tin màu sắc từ AppTheme
  Future<Map<String, Map<String, dynamic>>> getTransactionTypeTotals(
      String userId, DateTime startDate, DateTime endDate) async {
    try {
      final transactions = await _fetchTransactions(userId);
      final filtered = transactions
          .where((t) => t.date.isAfter(startDate) && t.date.isBefore(endDate))
          .toList();

      final typeTotals = <String, Map<String, dynamic>>{
        'income': {'amount': 0.0, 'color': AppTheme.incomeColor},
        'expense': {'amount': 0.0, 'color': AppTheme.expenseColor},
        'transfer': {'amount': 0.0, 'color': AppTheme.transferColor},
        'borrow': {'amount': 0.0, 'color': AppTheme.borrowColor},
        'lend': {'amount': 0.0, 'color': AppTheme.lendColor},
        'adjustment': {'amount': 0.0, 'color': AppTheme.adjustmentColor},
      };

      for (var t in filtered) {
        if (typeTotals.containsKey(t.typeKey)) {
          typeTotals[t.typeKey]!['amount'] =
              (typeTotals[t.typeKey]!['amount'] as double) + t.amount;
        }
      }

      // Loại bỏ các loại giao dịch có amount = 0
      return Map.fromEntries(
          typeTotals.entries.where((entry) => entry.value['amount'] > 0));
    } catch (e) {
      throw Exception('Failed to fetch transaction type totals: $e');
    }
  }
}