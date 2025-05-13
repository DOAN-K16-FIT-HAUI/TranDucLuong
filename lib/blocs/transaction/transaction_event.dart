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

// New event for loading more transactions (pagination)
class LoadMoreTransactions extends TransactionEvent {
  LoadMoreTransactions();
}

// New event for filtering transactions
class FilterTransactions extends TransactionEvent {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? transactionType;
  final String? categoryKey;
  final String? walletId;

  FilterTransactions({
    this.startDate,
    this.endDate,
    this.transactionType,
    this.categoryKey,
    this.walletId,
  });
}
