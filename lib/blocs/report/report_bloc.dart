import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/data/repositories/report_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  ReportBloc(this._reportRepository) : super(ReportInitial()) {
    on<LoadReportData>(_onLoadReportData);
    on<ExportReportData>(_onExportReportData);
  }

  Future<void> _onLoadReportData(LoadReportData event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final categoryExpenses = await _reportRepository.getCategoryExpenses(
        event.userId,
        event.startDate,
        event.endDate,
      );
      final dailyBalances = await _reportRepository.getDailyBalances(
        event.userId,
        event.startDate,
        event.endDate,
      );
      final transactionTypeTotals = await _reportRepository.getTransactionTypeTotals(
        event.userId,
        event.startDate,
        event.endDate,
      );

      emit(ReportLoaded(
        categoryExpenses: categoryExpenses,
        dailyBalances: dailyBalances,
        transactionTypeTotals: transactionTypeTotals,
      ));
    } catch (e) {
      emit(ReportError((context) => AppLocalizations.of(context)!.errorLoadingReportData));
    }
  }

  Future<void> _onExportReportData(ExportReportData event, Emitter<ReportState> emit) async {
    emit(ReportLoading());
    try {
      final transactions = await _reportRepository.getTransactions(
        event.userId,
        event.startDate,
        event.endDate,
      );
      emit(ReportExportSuccess(transactions));
    } catch (e) {
      emit(ReportExportFailure('Failed to export report'));
    }
  }
}