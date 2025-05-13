import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/data/models/report.dart';
import 'package:finance_app/data/repositories/report_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final ReportRepository _reportRepository;

  // Keep track of the last loaded report data
  String? _lastUserId;
  DateTime? _lastStartDate;
  DateTime? _lastEndDate;
  ReportLoaded? _lastLoadedState;

  ReportBloc(this._reportRepository) : super(ReportInitial()) {
    on<FetchReportData>(_onFetchReportData);
    on<ExportReportToCsv>(_onExportReportToCsv);
    on<ImportTransactionsFromCsv>(_onImportTransactionsFromCsv);
  }

  Future<void> _onFetchReportData(
    FetchReportData event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      // Store the parameters for potential reload later
      _lastUserId = event.userId;
      _lastStartDate = event.startDate;
      _lastEndDate = event.endDate;

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

      // Add wallet data
      final walletData =
          result.walletExpenses.entries
              .map((entry) => WalletDataPoint(entry.key, entry.value))
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

      // Create and store the loaded state
      _lastLoadedState = ReportLoaded(
        categoryData: categoryData,
        balanceData: balanceData,
        typeData: typeData,
        walletData: walletData,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
      );

      emit(_lastLoadedState!);
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
    // Store current state to restore it after export
    final currentState = state;

    emit(ReportExportInProgress());
    try {
      final filePath = await _reportRepository.exportReportToCsv(
        event.userId,
        event.startDate,
        event.endDate,
      );

      // Emit success state with the file path
      emit(ReportExportSuccess(filePath));

      // After showing export success, reload the report data to restore the chart
      if (_lastUserId != null &&
          _lastStartDate != null &&
          _lastEndDate != null) {
        // If we have last loaded parameters, restore report state
        add(
          FetchReportData(
            userId: _lastUserId!,
            startDate: _lastStartDate!,
            endDate: _lastEndDate!,
          ),
        );
      } else if (currentState is ReportLoaded) {
        // If we can't reload, at least restore the previous state
        emit(currentState);
      }
    } catch (e) {
      emit(
        ReportExportFailure(
          (context) => AppLocalizations.of(context)!.exportFailure,
        ),
      );

      // Restore previous state on failure
      if (currentState is ReportLoaded) {
        emit(currentState);
      }
    }
  }

  Future<void> _onImportTransactionsFromCsv(
    ImportTransactionsFromCsv event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportImportInProgress());
    try {
      final transactionCount = await _reportRepository
          .importTransactionsFromCsv(event.userId, event.filePath);

      emit(ReportImportSuccess(transactionCount));

      // Reload report data after successful import if we have last parameters
      if (_lastUserId != null &&
          _lastStartDate != null &&
          _lastEndDate != null) {
        add(
          FetchReportData(
            userId: _lastUserId!,
            startDate: _lastStartDate!,
            endDate: _lastEndDate!,
          ),
        );
      }
    } catch (e) {
      emit(
        ReportImportFailure(
          (context) =>
              AppLocalizations.of(context)!.importFailure(e.toString()),
        ),
      );
    }
  }
}
