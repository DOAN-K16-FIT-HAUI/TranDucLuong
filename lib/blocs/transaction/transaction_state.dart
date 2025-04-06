import 'package:finance_app/data/models/transaction.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;

  TransactionLoaded(this.transactions);
}

class TransactionSuccess extends TransactionState {
  final String message;

  TransactionSuccess(this.message);
}

class TransactionError extends TransactionState {
  final String message;

  TransactionError(this.message);
}