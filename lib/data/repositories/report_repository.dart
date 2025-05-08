import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

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
      // Request storage permission with improved handling
      if (!kIsWeb) {
        Map<Permission, PermissionStatus> statuses =
            await [
              Permission.storage,
              Permission.manageExternalStorage,
            ].request();

        if (statuses[Permission.storage] != PermissionStatus.granted &&
            statuses[Permission.manageExternalStorage] !=
                PermissionStatus.granted) {
          throw Exception('Storage permission required to export CSV');
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

      // Generate filename with timestamp to ensure uniqueness
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName =
          'finance_report_${dateFormatter.format(startDate)}_to_${dateFormatter.format(endDate)}_$timestamp.csv';

      // Save to a reliable location - Downloads directory
      Directory? directory;

      try {
        // Try to use the downloads directory first (most accessible to users)
        if (!kIsWeb && Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');

          // Make sure the directory exists
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        }

        // If that fails, use external storage directory
        if (directory == null) {
          directory = await getExternalStorageDirectory();
        }

        // If external storage isn't available, fall back to app documents directory
        if (directory == null) {
          directory = await getApplicationDocumentsDirectory();
        }

        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsString(csv);

        debugPrint('File saved at: $filePath');
        return filePath;
      } catch (e) {
        debugPrint('Error saving to primary location: $e');

        // Fallback to app documents directory as a last resort
        directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsString(csv);

        debugPrint('File saved at fallback location: $filePath');
        return filePath;
      }
    } catch (e) {
      debugPrint('Failed to export report: $e');
      throw Exception('Failed to export report: $e');
    }
  }

  /// Save to default app location when user cancels picker or on error
  Future<String> _saveToDefaultLocation(String csvData, String fileName) async {
    Directory? directory;

    try {
      // Try app documents directory
      directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    } catch (e) {
      // Try temporary directory as last resort
      directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    }
  }

  Future<int> importTransactionsFromCsv(String userId, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final csvData = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvData);

      if (rows.isEmpty || rows.length < 2) {
        throw Exception('CSV file is empty or has invalid format');
      }

      // Verify header row
      final headers = rows.first;
      if (headers.length < 6) {
        throw Exception(
          'CSV file format is invalid. Missing required columns.',
        );
      }

      // Process data rows
      int importedCount = 0;
      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm');

      for (int i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          if (row.length < 6) continue; // Skip invalid rows

          // Parse date and time
          final dateStr = row[0].toString();
          final timeStr = row[1].toString();

          DateTime date;
          try {
            final datePart = dateFormat.parse(dateStr);
            final timePart = timeFormat.parse(timeStr);
            date = DateTime(
              datePart.year,
              datePart.month,
              datePart.day,
              timePart.hour,
              timePart.minute,
            );
          } catch (e) {
            debugPrint('Invalid date/time format: $dateStr $timeStr');
            continue; // Skip this row
          }

          // Parse transaction data
          final typeKey = row[2].toString();
          final categoryKey = row[3].toString();
          final description = row[4].toString();
          final amount = double.tryParse(row[5].toString()) ?? 0.0;

          String? wallet;
          String? fromWallet;
          String? toWallet;

          // Handle wallet field
          if (row.length > 6) {
            final walletInfo = row[6].toString();
            if (walletInfo.contains('->')) {
              // This is a transfer
              final parts = walletInfo.split('->');
              fromWallet = parts[0].trim();
              toWallet = parts[1].trim();
            } else {
              wallet = walletInfo;
            }
          }

          // Create transaction object
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            userId: userId,
            date: date,
            amount: amount,
            description: description,
            typeKey: typeKey,
            categoryKey: categoryKey,
            wallet: wallet,
            fromWallet: fromWallet,
            toWallet: toWallet,
          );

          // Save to Firestore
          await _firestoreService.firestore
              .collection('transactions')
              .doc(transaction.id)
              .set(transaction.toJson());

          importedCount++;
        } catch (e) {
          debugPrint('Error processing row $i: $e');
          // Continue processing other rows
        }
      }

      return importedCount;
    } catch (e) {
      debugPrint('Failed to import CSV: $e');
      throw Exception('Failed to import CSV: $e');
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
