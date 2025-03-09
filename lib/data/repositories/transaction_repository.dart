import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  TransactionRepository({required this.userId});

  CollectionReference get _transactions =>
      _firestore.collection('users').doc(userId).collection('transactions');

  // Generate a unique ID for a new transaction
  String _generateTransactionId() {
    return _transactions.doc().id;
  }

  // Add a transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final transactionId = _generateTransactionId();
    transaction = transaction.copyWith(id: transactionId);
    await _transactions.doc(transactionId).set(transaction.toMap());
  }

  // Update a transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactions.doc(transaction.id).update(transaction.toMap());
  }

  // Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await _transactions.doc(id).delete();
  }

  // Get a list of transactions (Stream for real-time updates)
  Stream<List<TransactionModel>> getTransactions() {
    return _transactions.orderBy('date', descending: true).snapshots().map(
            (snapshot) => snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList());
  }
}