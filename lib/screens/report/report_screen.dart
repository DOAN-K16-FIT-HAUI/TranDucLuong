import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/report/report_bloc.dart';
import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/report.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/permissions_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Set initial date range to the current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(
      now.year,
      now.month + 1,
      0,
    ); // Correct way to get last day of current month

    // Wait for the widget to be fully built before dispatching events
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadReportData();
      }
    });
  }

  void _loadReportData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated &&
        _startDate != null &&
        _endDate != null) {
      context.read<ReportBloc>().add(
        FetchReportData(
          userId: authState.user.id,
          startDate: _startDate!,
          endDate: _endDate!,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBarTabBar.buildAppBar(
            context: context,
            title: l10n.reportsTitle,
            showBackButton: false,
            backgroundColor: theme.colorScheme.primaryContainer,
            actions: [_buildExportImportMenu(context, authState)],
          ),
          body: Column(
            children: [
              const SizedBox(height: 16),
              _buildDateRangeSelector(context),
              const SizedBox(height: 12),
              AppBarTabBar.buildTabBar(
                context: context,
                tabTitles: [
                  l10n.categoryChart,
                  l10n.balanceChart,
                  l10n.typeChart,
                ],
                controller: _tabController,
                onTabChanged: (index) {
                  // No need to handle tab change here as we're using TabBarView
                },
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoryChart(context),
                    _buildBalanceChart(context),
                    _buildTransactionTypeChart(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExportImportMenu(BuildContext context, AuthState authState) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocListener<ReportBloc, ReportState>(
      listenWhen:
          (previous, current) =>
              current is ReportExportSuccess ||
              current is ReportExportFailure ||
              current is ReportImportSuccess ||
              current is ReportImportFailure,
      listener: (context, state) {
        if (state is ReportExportSuccess) {
          _showExportSuccessDialog(context, state.filePath);
        } else if (state is ReportExportFailure) {
          // Show more detailed error and option to fix permission issues
          _handleExportError(context, state.message(context));
        } else if (state is ReportImportSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.importSuccessMessage(state.transactionCount)),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        } else if (state is ReportImportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message(context)),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        itemBuilder:
            (context) => [
              PopupMenuItem<String>(
                value: 'export',
                child: Row(
                  children: [
                    Icon(
                      Icons.file_download,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.exportReportToCSV),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'import',
                child: Row(
                  children: [
                    Icon(
                      Icons.file_upload,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(l10n.importTransactionsFromCSV),
                  ],
                ),
              ),
            ],
        onSelected: (value) {
          if (value == 'export' &&
              authState is AuthAuthenticated &&
              _startDate != null &&
              _endDate != null) {
            context.read<ReportBloc>().add(
              ExportReportToCsv(
                userId: authState.user.id,
                startDate: _startDate!,
                endDate: _endDate!,
              ),
            );
          } else if (value == 'import' && authState is AuthAuthenticated) {
            _importCsvFile(context, authState.user.id);
          }
        },
      ),
    );
  }

  Future<void> _handleExportError(BuildContext context, String message) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Check if it's a permission error
    if (message.contains('permission') || message.contains('denied')) {
      final bool granted = await PermissionsHandler.requestStoragePermissions(
        context,
      );

      if (granted && mounted) {
        // If permission was granted, retry export
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated &&
            _startDate != null &&
            _endDate != null) {
          context.read<ReportBloc>().add(
            ExportReportToCsv(
              userId: authState.user.id,
              startDate: _startDate!,
              endDate: _endDate!,
            ),
          );
        }
        return;
      }
    }

    // For other errors, show regular snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _importCsvFile(BuildContext context, String userId) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          context.read<ReportBloc>().add(
            ImportTransactionsFromCsv(userId: userId, filePath: file.path!),
          );
        }
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.filePickerError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showExportSuccessDialog(BuildContext context, String filePath) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Get a more user-friendly file path representation
    final pathInfo = await PermissionsHandler.getReadableFilePath(filePath);

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing dialog by tapping outside
      builder:
          (context) => AlertDialog(
            title: Text(l10n.exportSuccessTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.exportSuccessMessage),
                const SizedBox(height: 8),
                Text(
                  l10n.fileStorageLocation(pathInfo['location']!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: theme.colorScheme.surfaceVariant,
                  ),
                  child: SelectableText(
                    pathInfo['displayPath']!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.fileLocationHelpText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // Pass context to the openFileLocation method
                  PermissionsHandler.openFileLocation(filePath, context);
                },
                child: Text(l10n.openLocation),
              ),
              TextButton(
                onPressed: () {
                  Share.shareXFiles([
                    XFile(filePath),
                  ], text: l10n.exportShareMessage);
                },
                child: Text(l10n.shareButton),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(l10n.okButton),
              ),
            ],
          ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dateRangeFilter,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, isStart: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _startDate != null
                                ? dateFormat.format(_startDate!)
                                : l10n.notSelected,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(
                  Icons.arrow_forward,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                  size: 16,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context, isStart: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _endDate != null
                                ? dateFormat.format(_endDate!)
                                : l10n.notSelected,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Buttons.buildSubmitButton(
            context,
            l10n.apply,
            (_startDate != null && _endDate != null)
                ? () {
                  if (_startDate!.isAfter(_endDate!)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.invalidDateRange),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    _loadReportData();
                  }
                }
                : () {},
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required bool isStart,
  }) async {
    final firstDate = DateTime(2020);
    final lastDate = DateTime.now();
    final initialDate =
        isStart
            ? (_startDate != null && _startDate!.isBefore(lastDate)
                ? _startDate!
                : lastDate)
            : (_endDate != null && _endDate!.isBefore(lastDate)
                ? _endDate!
                : lastDate);
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (selectedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  Widget _buildCategoryChart(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<ReportBloc, ReportState>(
      buildWhen:
          (previous, current) =>
              current is ReportLoading ||
              current is ReportError ||
              current is ReportLoaded,
      builder: (context, state) {
        if (state is ReportLoading) {
          return Center(
            child: UtilityWidgets.buildLoadingIndicator(context: context),
          );
        }

        if (state is ReportError) {
          return UtilityWidgets.buildErrorState(
            context: context,
            message: state.message,
            onRetry: _loadReportData,
          );
        }

        if (state is ReportLoaded && state.categoryData.isNotEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  position: LegendPosition.bottom,
                  overflowMode: LegendItemOverflowMode.wrap,
                ),
                series: <CircularSeries>[
                  PieSeries<CategoryDataPoint, String>(
                    dataSource: state.categoryData,
                    xValueMapper:
                        (CategoryDataPoint data, _) =>
                            ListsCards.getLocalizedCategory(
                              context,
                              data.category,
                            ),
                    yValueMapper: (CategoryDataPoint data, _) => data.amount,
                    dataLabelMapper:
                        (CategoryDataPoint data, _) =>
                            '${((data.amount / state.totalExpenses) * 100).toStringAsFixed(1)}%',
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      labelPosition: ChartDataLabelPosition.outside,
                      connectorLineSettings: const ConnectorLineSettings(
                        type: ConnectorType.curve,
                        length: '15%',
                      ),
                      textStyle: GoogleFonts.notoSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    enableTooltip: true,
                    pointColorMapper:
                        (CategoryDataPoint data, _) =>
                            _getCategoryColor(data.category),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  format: 'point.x: point.y',
                ),
                palette: const [
                  Color(0xFF4CAF50), // Green
                  Color(0xFF2196F3), // Blue
                  Color(0xFFFF9800), // Orange
                  Color(0xFFE91E63), // Pink
                  Color(0xFF9C27B0), // Purple
                  Color(0xFFFF5722), // Deep Orange
                  Color(0xFF673AB7), // Deep Purple
                  Color(0xFF3F51B5), // Indigo
                  Color(0xFF009688), // Teal
                  Color(0xFF795548), // Brown
                ],
              ),
            ),
          );
        }

        // Show empty state when no data
        return _buildEmptyChartState(
          context,
          l10n.noExpenseData,
          Icons.pie_chart_outline,
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'food':
        return const Color(0xFF4CAF50); // Green
      case 'living':
        return const Color(0xFF2196F3); // Blue
      case 'transport':
        return const Color(0xFFFF9800); // Orange
      case 'health':
        return const Color(0xFFE91E63); // Pink
      case 'shopping':
        return const Color(0xFF9C27B0); // Purple
      case 'entertainment':
        return const Color(0xFFFF5722); // Deep Orange
      case 'education':
        return const Color(0xFF673AB7); // Deep Purple
      case 'bills':
        return const Color(0xFF3F51B5); // Indigo
      case 'gift':
        return const Color(0xFF009688); // Teal
      case 'other':
        return const Color(0xFF795548); // Brown
      default:
        return Colors.grey;
    }
  }

  Widget _buildBalanceChart(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<ReportBloc, ReportState>(
      buildWhen:
          (previous, current) =>
              current is ReportLoading ||
              current is ReportError ||
              current is ReportLoaded,
      builder: (context, state) {
        if (state is ReportLoading) {
          return Center(
            child: UtilityWidgets.buildLoadingIndicator(context: context),
          );
        }

        if (state is ReportError) {
          return UtilityWidgets.buildErrorState(
            context: context,
            message: state.message,
            onRetry: _loadReportData,
          );
        }

        if (state is ReportLoaded && state.balanceData.isNotEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                height: 300, // Fixed height for the chart
                child: SfCartesianChart(
                  primaryXAxis: DateTimeAxis(
                    dateFormat: DateFormat('dd/MM'),
                    intervalType: DateTimeIntervalType.auto,
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat.compact(),
                    axisLine: const AxisLine(width: 0),
                    majorTickLines: const MajorTickLines(size: 0),
                  ),
                  legend: Legend(
                    isVisible: true,
                    position: LegendPosition.bottom,
                  ),
                  tooltipBehavior: TooltipBehavior(enable: true),
                  series: <CartesianSeries>[
                    LineSeries<BalanceDataPoint, DateTime>(
                      name: l10n.totalBalance,
                      dataSource: state.balanceData,
                      xValueMapper: (BalanceDataPoint data, _) => data.date,
                      yValueMapper: (BalanceDataPoint data, _) => data.balance,
                      markerSettings: const MarkerSettings(isVisible: true),
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePanning: true,
                    zoomMode: ZoomMode.x,
                    enablePinching: true,
                  ),
                ),
              ),
            ),
          );
        }

        // Show empty state when no data
        return _buildEmptyChartState(
          context,
          l10n.noBalanceData,
          Icons.show_chart,
        );
      },
    );
  }

  Widget _buildTransactionTypeChart(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return BlocBuilder<ReportBloc, ReportState>(
      buildWhen:
          (previous, current) =>
              current is ReportLoading ||
              current is ReportError ||
              current is ReportLoaded,
      builder: (context, state) {
        if (state is ReportLoading) {
          return Center(
            child: UtilityWidgets.buildLoadingIndicator(context: context),
          );
        }

        if (state is ReportError) {
          return UtilityWidgets.buildErrorState(
            context: context,
            message: state.message,
            onRetry: _loadReportData,
          );
        }

        if (state is ReportLoaded && state.typeData.isNotEmpty) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 300, // Fixed height for the chart
                    child: SfCartesianChart(
                      plotAreaBorderWidth: 0,
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        labelStyle: GoogleFonts.notoSans(fontSize: 12),
                      ),
                      primaryYAxis: NumericAxis(
                        numberFormat: NumberFormat.compact(),
                        axisLine: const AxisLine(width: 0),
                        majorTickLines: const MajorTickLines(size: 0),
                      ),
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        overflowMode: LegendItemOverflowMode.wrap,
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries>[
                        ColumnSeries<TypeDataPoint, String>(
                          dataSource: state.typeData,
                          xValueMapper:
                              (TypeDataPoint data, _) =>
                                  ListsCards.getLocalizedType(
                                    context,
                                    data.type,
                                  ),
                          yValueMapper: (TypeDataPoint data, _) => data.amount,
                          pointColorMapper:
                              (TypeDataPoint data, _) =>
                                  _getTransactionTypeColor(data.type),
                          name: l10n.totalAmountPaidLabel,
                          borderRadius: const BorderRadius.all(
                            Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Summary section below chart
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(
                          context,
                          l10n.totalIncomeLabel,
                          state.totalIncome,
                          AppTheme.incomeColor,
                        ),
                        const SizedBox(height: 8),
                        _buildSummaryRow(
                          context,
                          l10n.totalExpenseLabel,
                          state.totalExpenses,
                          AppTheme.expenseColor,
                        ),
                        const Divider(height: 16),
                        _buildSummaryRow(
                          context,
                          l10n.remainingAmountLabel,
                          state.totalIncome - state.totalExpenses,
                          (state.totalIncome - state.totalExpenses) >= 0
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show empty state when no data
        return _buildEmptyChartState(
          context,
          l10n.noTransactionData,
          Icons.bar_chart,
        );
      },
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(locale),
      decimalDigits: 0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          formatter.format(amount),
          style: GoogleFonts.notoSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbol(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return '₫';
      case 'ja':
        return '¥';
      case 'en':
      default:
        return '\$';
    }
  }

  Color _getTransactionTypeColor(String type) {
    switch (type) {
      case 'income':
        return AppTheme.incomeColor;
      case 'expense':
        return AppTheme.expenseColor;
      case 'transfer':
        return AppTheme.transferColor;
      case 'borrow':
        return AppTheme.borrowColor;
      case 'lend':
        return AppTheme.lendColor;
      case 'adjustment':
        return AppTheme.adjustmentColor;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyChartState(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return UtilityWidgets.buildEmptyState(
      context: context,
      message: message,
      suggestion: l10n.selectDifferentDateRange,
      icon: icon,
      iconSize: 70,
      actionText: l10n.addTransactionTooltip,
      actionIcon: Icons.add,
      onActionPressed: () {
        Navigator.pop(context);
        // This would navigate to add transaction screen in a real app
      },
    );
  }
}
