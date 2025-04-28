import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final Map<String, double> categoryExpenses;
  final Map<DateTime, double> dailyBalances;
  final Map<String, Map<String, dynamic>> transactionTypeTotals;

  const ReportLoaded({
    required this.categoryExpenses,
    required this.dailyBalances,
    required this.transactionTypeTotals,
  });

  @override
  List<Object?> get props => [categoryExpenses, dailyBalances, transactionTypeTotals];
}

class ReportError extends ReportState {
  final String Function(BuildContext) message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}