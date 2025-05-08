import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/data/models/report.dart';
import 'package:finance_app/data/repositories/report_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  ReportBloc(this._reportRepository) : super(ReportInitial()) {
    on<FetchReportData>(_onFetchReportData);
    on<ExportReportToCsv>(_onExportReportToCsv);
  }

  Future<void> _onFetchReportData(
    FetchReportData event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final result = await _reportRepository.getReportData(
        event.userId,
        event.startDate,
        event.endDate,
      );

      // Transform the report data for the charts
      final categoryData =
          result.categoryExpenses.entries
              .map((entry) => CategoryDataPoint(entry.key, entry.value))
              .toList();

      final balanceData =
          result.dailyBalances.entries
              .map((entry) => BalanceDataPoint(entry.key, entry.value))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

      final typeData =
          result.transactionTypeTotals.entries
              .map((entry) => TypeDataPoint(entry.key, entry.value))
              .toList();

      // Calculate income and expense totals
      final incomeEntry = result.transactionTypeTotals.entries.firstWhere(
        (entry) => entry.key == 'income',
        orElse: () => MapEntry('income', 0.0),
      );
      final totalIncome = incomeEntry.value;

      // Get total expenses from category data
      double totalExpenses = categoryData.fold(
        0,
        (sum, item) => sum + item.amount,
      );

      emit(
        ReportLoaded(
          categoryData: categoryData,
          balanceData: balanceData,
          typeData: typeData,
          totalIncome: totalIncome,
          totalExpenses: totalExpenses,
        ),
      );
    } catch (e) {
      emit(
        ReportError(
          (context) => AppLocalizations.of(context)!.errorLoadingReportData,
        ),
      );
    }
  }

  Future<void> _onExportReportToCsv(
    ExportReportToCsv event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportExportInProgress());
    try {
      final filePath = await _reportRepository.exportReportToCsv(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(ReportExportSuccess(filePath));
    } catch (e) {
      emit(
        ReportExportFailure(
          (context) => AppLocalizations.of(context)!.exportFailure,
        ),
      );
    }
  }
}
