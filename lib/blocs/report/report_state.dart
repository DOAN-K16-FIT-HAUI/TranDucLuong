import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:finance_app/data/models/report.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final List<CategoryDataPoint> categoryData;
  final List<BalanceDataPoint> balanceData;
  final List<TypeDataPoint> typeData;
  final List<WalletDataPoint> walletData; // Added wallet breakdown data
  final double totalIncome;
  final double totalExpenses;

  const ReportLoaded({
    required this.categoryData,
    required this.balanceData,
    required this.typeData,
    required this.walletData, // Added this parameter
    required this.totalIncome,
    required this.totalExpenses,
  });

  @override
  List<Object?> get props => [
    categoryData,
    balanceData,
    typeData,
    walletData, // Added to props
    totalIncome,
    totalExpenses,
  ];
}

class ReportError extends ReportState {
  final String Function(BuildContext) message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportExportInProgress extends ReportState {}

class ReportExportSuccess extends ReportState {
  final String filePath;

  const ReportExportSuccess(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class ReportExportFailure extends ReportState {
  final String Function(BuildContext) message;

  const ReportExportFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// New states for import functionality
class ReportImportInProgress extends ReportState {}

class ReportImportSuccess extends ReportState {
  final int transactionCount;

  const ReportImportSuccess(this.transactionCount);

  @override
  List<Object?> get props => [transactionCount];
}

class ReportImportFailure extends ReportState {
  final String Function(BuildContext) message;

  const ReportImportFailure(this.message);

  @override
  List<Object?> get props => [message];
}
