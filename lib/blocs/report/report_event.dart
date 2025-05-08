import 'package:equatable/equatable.dart';

abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportData extends ReportEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const LoadReportData({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

class FetchReportData extends ReportEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const FetchReportData({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

class ExportReportToCsv extends ReportEvent {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;

  const ExportReportToCsv({
    required this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

class ImportTransactionsFromCsv extends ReportEvent {
  final String userId;
  final String filePath;

  const ImportTransactionsFromCsv({
    required this.userId,
    required this.filePath,
  });

  @override
  List<Object?> get props => [userId, filePath];
}
