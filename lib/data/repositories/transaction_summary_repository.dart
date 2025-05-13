import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/transaction_summary.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class TransactionSummaryRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  TransactionSummaryRepository(this.firestoreService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  String _userSummariesPath(String userId) {
    return 'users/$userId/summaries';
  }

  // Get summary for a specific year and month
  Future<TransactionSummary?> getSummary(String year, String month) async {
    final userId = _getUserId();
    if (userId == null) return null;

    final summaryId = '$year-$month';

    try {
      final doc =
          await firestoreService.firestore
              .collection(_userSummariesPath(userId))
              .doc(summaryId)
              .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return TransactionSummary.fromJson(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      debugPrint("Error getting summary for $year-$month: $e");
      return null;
    }
  }

  // Update summary after transaction changes
  Future<void> updateSummaryForTransaction(
    TransactionModel transaction, {
    bool isDelete = false,
  }) async {
    final userId = _getUserId();
    if (userId == null) return;

    // Extract year and month from transaction date
    final year = transaction.date.year.toString();
    final month = transaction.date.month.toString().padLeft(2, '0');
    final summaryId = '$year-$month';

    final summaryRef = firestoreService.firestore
        .collection(_userSummariesPath(userId))
        .doc(summaryId);

    try {
      await firestoreService.firestore.runTransaction((txn) async {
        final summaryDoc = await txn.get(summaryRef);

        // Default summary or existing one
        final Map<String, dynamic>? data =
            summaryDoc.exists ? summaryDoc.data() : null;

        final summary =
            data != null
                ? TransactionSummary.fromJson(data, summaryId)
                : TransactionSummary(
                  id: summaryId,
                  userId: userId,
                  year: year,
                  month: month,
                  categoryExpenses: {},
                  walletChanges: {},
                );

        // Update summary based on transaction type
        final factor = isDelete ? -1 : 1; // Negate values if deleting

        // Create copies of maps to modify
        final categoryExpenses = Map<String, double>.from(
          summary.categoryExpenses,
        );
        final walletChanges = Map<String, double>.from(summary.walletChanges);

        // Variables for the new summary values
        double newTotalIncome = summary.totalIncome;
        double newTotalExpense = summary.totalExpense;
        double newTotalTransfer = summary.totalTransfer;
        double newTotalBorrow = summary.totalBorrow;
        double newTotalLend = summary.totalLend;

        switch (transaction.typeKey) {
          case 'income':
            newTotalIncome += transaction.amount * factor;

            // Update wallet changes
            if (transaction.wallet != null) {
              final currentChange = walletChanges[transaction.wallet] ?? 0.0;
              walletChanges[transaction.wallet!] =
                  currentChange + (transaction.amount * factor);
            }
            break;

          case 'expense':
            newTotalExpense += transaction.amount * factor;

            // Update category expenses
            if (transaction.categoryKey.isNotEmpty) {
              final currentExpense =
                  categoryExpenses[transaction.categoryKey] ?? 0.0;
              categoryExpenses[transaction.categoryKey] =
                  currentExpense + (transaction.amount * factor);
            }

            // Update wallet changes
            if (transaction.wallet != null) {
              final currentChange = walletChanges[transaction.wallet] ?? 0.0;
              walletChanges[transaction.wallet!] =
                  currentChange - (transaction.amount * factor);
            }
            break;

          case 'transfer':
            newTotalTransfer += transaction.amount * factor;

            // Update from wallet
            if (transaction.fromWallet != null) {
              final currentChange =
                  walletChanges[transaction.fromWallet] ?? 0.0;
              walletChanges[transaction.fromWallet!] =
                  currentChange - (transaction.amount * factor);
            }

            // Update to wallet
            if (transaction.toWallet != null) {
              final currentChange = walletChanges[transaction.toWallet] ?? 0.0;
              walletChanges[transaction.toWallet!] =
                  currentChange + (transaction.amount * factor);
            }
            break;

          case 'borrow':
            newTotalBorrow += transaction.amount * factor;

            if (transaction.wallet != null) {
              final currentChange = walletChanges[transaction.wallet] ?? 0.0;
              walletChanges[transaction.wallet!] =
                  currentChange + (transaction.amount * factor);
            }
            break;

          case 'lend':
            newTotalLend += transaction.amount * factor;

            if (transaction.wallet != null) {
              final currentChange = walletChanges[transaction.wallet] ?? 0.0;
              walletChanges[transaction.wallet!] =
                  currentChange - (transaction.amount * factor);
            }
            break;

          default:
            debugPrint(
              "Unknown transaction type for summary update: ${transaction.typeKey}",
            );
        }

        // Create updated summary
        final updatedSummary = TransactionSummary(
          id: summaryId,
          userId: userId,
          year: year,
          month: month,
          totalIncome: newTotalIncome,
          totalExpense: newTotalExpense,
          totalTransfer: newTotalTransfer,
          totalBorrow: newTotalBorrow,
          totalLend: newTotalLend,
          categoryExpenses: categoryExpenses,
          walletChanges: walletChanges,
        );

        // Update the summary document
        txn.set(summaryRef, updatedSummary.toJson(), SetOptions(merge: true));
      });

      debugPrint("Transaction summary updated for $summaryId");
    } catch (e) {
      debugPrint("Error updating transaction summary: $e");
    }
  }
}
