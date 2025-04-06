import 'package:finance_app/data/models/transaction.dart';

abstract class TransactionEvent {}

class AddTransaction extends TransactionEvent {
  final TransactionModel transaction;

  AddTransaction(this.transaction);
}

class UpdateTransaction extends TransactionEvent {
  final TransactionModel transaction;

  UpdateTransaction(this.transaction);
}

class DeleteTransaction extends TransactionEvent {
  final String transactionId;

  DeleteTransaction(this.transactionId);
}

class LoadTransactions extends TransactionEvent {
  final String userId;

  LoadTransactions(this.userId);
}