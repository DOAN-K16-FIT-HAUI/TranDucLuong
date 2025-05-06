import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:permission_handler/permission_handler.dart';

class ReportRepository {
  final FirestoreService _firestoreService;

  ReportRepository(this._firestoreService);

  Future<List<TransactionModel>> getTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final querySnapshot =
          await _firestoreService.firestore
              .collection('transactions')
              .where('userId', isEqualTo: userId)
              .where('date', isGreaterThanOrEqualTo: startDate)
              .where(
                'date',
                isLessThanOrEqualTo: endDate.add(const Duration(days: 1)),
              )
              .orderBy('date')
              .get();

      return querySnapshot.docs
          .map((doc) => TransactionModel.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Failed to fetch transactions: $e');
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<ReportData> getReportData(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final transactions = await getTransactions(userId, startDate, endDate);

      // Calculate category expenses
      final categoryExpenses = <String, double>{};
      for (var t in transactions.where((t) => t.typeKey == 'expense')) {
        final category = t.categoryKey.isNotEmpty ? t.categoryKey : 'other';
        categoryExpenses[category] =
            (categoryExpenses[category] ?? 0) + t.amount;
      }

      // Calculate daily balances
      final dailyBalances = <DateTime, double>{};
      double runningBalance = 0;

      // Sort transactions by date
      transactions.sort((a, b) => a.date.compareTo(b.date));

      for (
        var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final normalizedDate = DateTime(date.year, date.month, date.day);

        for (var t in transactions.where(
          (t) =>
              t.date.year == date.year &&
              t.date.month == date.month &&
              t.date.day == date.day,
        )) {
          if (t.typeKey == 'income') {
            runningBalance += t.amount;
          } else if (t.typeKey == 'expense') {
            runningBalance -= t.amount;
          } else if (t.typeKey == 'transfer') {
            // For transfers, balance doesn't change in total
          } else if (t.typeKey == 'borrow') {
            runningBalance += t.amount;
          } else if (t.typeKey == 'lend') {
            runningBalance -= t.amount;
          } else if (t.typeKey == 'adjustment' && t.balanceAfter != null) {
            runningBalance = t.balanceAfter!;
          }
        }

        dailyBalances[normalizedDate] = runningBalance;
      }

      // Calculate transaction type totals
      final transactionTypeTotals = <String, double>{};
      for (var t in transactions) {
        if (t.typeKey != 'transfer' && t.typeKey != 'adjustment') {
          transactionTypeTotals[t.typeKey] =
              (transactionTypeTotals[t.typeKey] ?? 0) + t.amount;
        }
      }

      return ReportData(
        categoryExpenses: categoryExpenses,
        dailyBalances: dailyBalances,
        transactionTypeTotals: transactionTypeTotals,
      );
    } catch (e) {
      debugPrint('Failed to get report data: $e');
      throw Exception('Failed to get report data: $e');
    }
  }

  Future<String> exportReportToCsv(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Request storage permission
      if (!kIsWeb) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      final transactions = await getTransactions(userId, startDate, endDate);

      // Sort transactions by date
      transactions.sort((a, b) => a.date.compareTo(b.date));

      // Create CSV data
      List<List<dynamic>> csvData = [
        // Header row
        ['Date', 'Time', 'Type', 'Category', 'Description', 'Amount', 'Wallet'],
      ];

      // Add transaction rows
      final dateFormatter = DateFormat('yyyy-MM-dd');
      final timeFormatter = DateFormat('HH:mm');

      for (var t in transactions) {
        csvData.add([
          dateFormatter.format(t.date),
          timeFormatter.format(t.date),
          t.typeKey,
          t.categoryKey,
          t.description,
          t.amount,
          t.wallet ??
              (t.fromWallet != null ? '${t.fromWallet} -> ${t.toWallet}' : ''),
        ]);
      }

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Save to file
      final directory =
          await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final fileName =
          'finance_report_${dateFormatter.format(startDate)}_to_${dateFormatter.format(endDate)}.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csv);

      return filePath;
    } catch (e) {
      debugPrint('Failed to export report: $e');
      throw Exception('Failed to export report: $e');
    }
  }
}

class ReportData {
  final Map<String, double> categoryExpenses;
  final Map<DateTime, double> dailyBalances;
  final Map<String, double> transactionTypeTotals;

  ReportData({
    required this.categoryExpenses,
    required this.dailyBalances,
    required this.transactionTypeTotals,
  });
}
