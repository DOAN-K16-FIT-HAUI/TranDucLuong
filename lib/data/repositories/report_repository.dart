import 'dart:io';

import 'package:csv/csv.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class ReportRepository {
  final FirestoreService _firestoreService;
  final FirebaseAuth _auth;

  ReportRepository(this._firestoreService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  // Verify if the user account is active
  Future<bool> _verifyAccountActive() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Force reload user to get latest account status
      await user.reload();

      // Get fresh user object after reload
      final freshUser = _auth.currentUser;
      if (freshUser == null) return false;

      try {
        // This will throw an error if account is disabled
        await freshUser.getIdToken(true);
        return true;
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'user-disabled') {
          return false;
        }
        rethrow;
      }
    } catch (e) {
      debugPrint("Error verifying account status: $e");
      return false;
    }
  }

  // Enhanced getUserId with account status check
  Future<String> _getVerifiedUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw SecurityException("User not logged in");
    }

    // Check if account is disabled
    if (!await _verifyAccountActive()) {
      throw SecurityException("Account is disabled");
    }

    return user.uid;
  }

  // Get cached userId for non-critical operations
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  // Get transactions collection path for a user
  String _userTransactionsPath(String userId) {
    return 'users/$userId/transactions';
  }

  Future<List<TransactionModel>> getTransactions(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // Verify account is active for this sensitive operation
      await _getVerifiedUserId();

      final querySnapshot =
          await _firestoreService.firestore
              .collection(_userTransactionsPath(userId))
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

      // Add wallet breakdown - expense by wallet
      final walletExpenses = <String, double>{};
      for (var t in transactions.where(
        (t) => t.typeKey == 'expense' && t.wallet != null,
      )) {
        // Extract wallet name from path or use path as key
        final walletKey = t.wallet!;
        final walletName = t.walletDisplayName ?? walletKey.split('/').last;
        walletExpenses[walletName] =
            (walletExpenses[walletName] ?? 0) + t.amount;
      }

      return ReportData(
        categoryExpenses: categoryExpenses,
        dailyBalances: dailyBalances,
        transactionTypeTotals: transactionTypeTotals,
        walletExpenses: walletExpenses,
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
      // Verify account is active for this operation
      await _getVerifiedUserId();

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
        // Header row with more detailed information
        [
          'Date',
          'Time',
          'Type',
          'Category',
          'Description',
          'Amount',
          'Wallet',
          'From Wallet',
          'To Wallet',
          'Balance Before',
          'Balance After',
        ],
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
          t.wallet != null ? t.walletDisplayName : '',
          t.fromWallet != null ? t.fromWalletDisplayName : '',
          t.toWallet != null ? t.toWalletDisplayName : '',
          t.balanceBefore,
          t.balanceAfter,
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
        directory ??= await getExternalStorageDirectory();

        // If external storage isn't available, fall back to app documents directory
        directory ??= await getApplicationDocumentsDirectory();

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

  Future<int> importTransactionsFromCsv(String userId, String filePath) async {
    try {
      // Verify account is active for this sensitive operation
      final verifiedUserId = await _getVerifiedUserId();

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

          // Extract wallet information and convert to proper paths
          if (row.length > 6) {
            final walletInfo = row[6].toString();
            if (walletInfo.isNotEmpty) {
              // Check if this is a wallet path already
              if (walletInfo.contains('/')) {
                wallet = walletInfo;
              } else {
                // Try to find wallet by name and get its path
                wallet =
                    'users/$verifiedUserId/wallets/${walletInfo}'; // Simplified path construction
              }
            }
          }

          // Handle from/to wallets for transfers
          if (row.length > 7 && row[7].toString().isNotEmpty) {
            final fromWalletInfo = row[7].toString();
            if (fromWalletInfo.contains('/')) {
              fromWallet = fromWalletInfo;
            } else {
              fromWallet = 'users/$verifiedUserId/wallets/${fromWalletInfo}';
            }
          }

          if (row.length > 8 && row[8].toString().isNotEmpty) {
            final toWalletInfo = row[8].toString();
            if (toWalletInfo.contains('/')) {
              toWallet = toWalletInfo;
            } else {
              toWallet = 'users/$verifiedUserId/wallets/${toWalletInfo}';
            }
          }

          // Parse balance information (if available)
          double? balanceBefore;
          double? balanceAfter;

          if (row.length > 9 && row[9].toString().isNotEmpty) {
            balanceBefore = double.tryParse(row[9].toString());
          }

          if (row.length > 10 && row[10].toString().isNotEmpty) {
            balanceAfter = double.tryParse(row[10].toString());
          }

          // Create transaction object
          final transaction = TransactionModel(
            id: const Uuid().v4(),
            userId: verifiedUserId,
            date: date,
            amount: amount,
            description: description,
            typeKey: typeKey,
            categoryKey: categoryKey,
            wallet: wallet,
            fromWallet: fromWallet,
            toWallet: toWallet,
            balanceBefore: balanceBefore,
            balanceAfter: balanceAfter,
          );

          // Save to Firestore in user's transactions subcollection
          await _firestoreService.firestore
              .collection(_userTransactionsPath(verifiedUserId))
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
  final Map<String, double> walletExpenses; // Added wallet breakdown

  ReportData({
    required this.categoryExpenses,
    required this.dailyBalances,
    required this.transactionTypeTotals,
    required this.walletExpenses,
  });
}

// Add custom exceptions for better error handling
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
