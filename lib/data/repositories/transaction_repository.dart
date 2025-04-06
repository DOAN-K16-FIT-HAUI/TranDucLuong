import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/services/firestore_service.dart';

class TransactionRepository {
  final FirestoreService firestoreService;
  static const String transactionCollectionPath = 'transactions';
  static const String walletCollectionPath = 'wallets';

  TransactionRepository(this.firestoreService);

  // Add a new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    try {
      await firestoreService.addDocument(transactionCollectionPath, transaction.toJson());
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  // Update an existing transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await firestoreService.updateDocument(
        transactionCollectionPath,
        transaction.id,
        transaction.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update transaction: $e');
    }
  }

  // Delete a transaction
  Future<void> deleteTransaction(String transactionId) async {
    try {
      await firestoreService.deleteDocument(transactionCollectionPath, transactionId);
    } catch (e) {
      throw Exception('Failed to delete transaction: $e');
    }
  }

  // Get a transaction by ID
  Future<TransactionModel> getTransaction(String transactionId) async {
    try {
      final doc = await firestoreService.getDocument(transactionCollectionPath, transactionId);
      if (!doc.exists) {
        throw Exception('TransactionModel not found');
      }
      return TransactionModel.fromJson(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }

  // Get a stream of transactions for a user
  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    try {
      return firestoreService
          .getCollectionStream(transactionCollectionPath)
          .map((snapshot) {
        return snapshot.docs
            .where((doc) => doc['userId'] == userId)
            .map((doc) => TransactionModel.fromJson(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get transactions: $e');
    }
  }

  // Get a stream of wallets for a user
  Stream<Map<String, double>> getUserWallets(String userId) {
    try {
      return firestoreService
          .getCollectionStream(walletCollectionPath)
          .map((snapshot) {
        final wallets = snapshot.docs
            .where((doc) => doc['userId'] == userId)
            .map((doc) => Wallet.fromSnapshot(doc))
            .toList();
        return Map.fromEntries(
          wallets.map((wallet) => MapEntry(wallet.name, wallet.balance.toDouble())),
        );
      });
    } catch (e) {
      throw Exception('Failed to get wallets: $e');
    }
  }
}