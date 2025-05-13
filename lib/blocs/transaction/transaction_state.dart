import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:flutter/material.dart';

abstract class TransactionState {}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

// Filter criteria class to store filter parameters
class FilterCriteria {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? transactionType;
  final String? categoryKey;
  final String? walletId;

  FilterCriteria({
    this.startDate,
    this.endDate,
    this.transactionType,
    this.categoryKey,
    this.walletId,
  });
}

// Updated TransactionLoaded with pagination support
class TransactionLoaded extends TransactionState {
  final List<TransactionModel> transactions;
  final bool hasMoreTransactions;
  final DocumentSnapshot? lastDocument;
  final FilterCriteria? filterCriteria;

  TransactionLoaded(
    this.transactions, {
    this.hasMoreTransactions = false,
    this.lastDocument,
    this.filterCriteria,
  });
}

class TransactionSuccess extends TransactionState {
  final String Function(BuildContext) message;
  TransactionSuccess(this.message);
}

class TransactionError extends TransactionState {
  final String Function(BuildContext) message;
  TransactionError(this.message);
}
