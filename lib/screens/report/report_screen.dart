import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/report/report_bloc.dart';
import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  ReportScreenState createState() => ReportScreenState();
}

class ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  late TabController _tabController;
  String _selectedChartType = 'category';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadReportData();
  }

  void _loadReportData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ReportBloc>().add(LoadReportData(
        userId: authState.user.id,
        startDate: _startDate,
        endDate: _endDate,
      ));
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return UtilityWidgets.buildEmptyState(
              context: context,
              message: l10n.pleaseLoginToViewReports,
              suggestion: null,
              onActionPressed: null,
            );
          }

          return Column(
            children: [
              AppBarTabBar.buildAppBar(
                context: context,
                title: l10n.reportsTitle,
                showBackButton: false,
                backIcon: Icons.arrow_back,
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: InputFields.buildDatePickerField(
                        context: context,
                        date: _startDate,
                        label: l10n.startDateLabel,
                        onTap: (picked) {
                          if (picked != null && mounted) {
                            setState(() {
                              _startDate = picked;
                              if (_startDate.isAfter(_endDate)) {
                                _endDate = _startDate;
                              }
                              _loadReportData();
                            });
                          }
                        },
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InputFields.buildDatePickerField(
                        context: context,
                        date: _endDate,
                        label: l10n.endDateLabel,
                        onTap: (picked) {
                          if (picked != null && mounted) {
                            setState(() {
                              _endDate = picked;
                              if (_endDate.isBefore(_startDate)) {
                                _startDate = _endDate;
                              }
                              _loadReportData();
                            });
                          }
                        },
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
              ),
              AppBarTabBar.buildTabBar(
                context: context,
                tabTitles: [
                  l10n.categoryChart,
                  l10n.balanceChart,
                  l10n.typeChart,
                ],
                onTabChanged: (index) {
                  setState(() {
                    _selectedChartType = ['category', 'balance', 'type'][index];
                  });
                },
                controller: _tabController,
              ),
              Expanded(
                child: BlocBuilder<ReportBloc, ReportState>(
                  builder: (context, state) {
                    if (state is ReportLoading) {
                      return UtilityWidgets.buildLoadingIndicator(context: context);
                    } else if (state is ReportError) {
                      return UtilityWidgets.buildErrorState(
                        context: context,
                        message: state.message, // Sửa ở đây
                        onRetry: _loadReportData,
                      );
                    } else if (state is ReportLoaded) {
                      return _buildChartContent(context, state, l10n);
                    }
                    return UtilityWidgets.buildEmptyState(
                      context: context,
                      message: l10n.noDataAvailable,
                      suggestion: l10n.selectDifferentDateRange,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartContent(BuildContext context, ReportLoaded state, AppLocalizations l10n) {
    switch (_selectedChartType) {
      case 'category':
        return _buildPieChart(context, state.categoryExpenses, l10n);
      case 'balance':
        return _buildLineChart(context, state.dailyBalances, l10n);
      case 'type':
        return _buildBarChart(context, state.transactionTypeTotals, l10n);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> data, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    if (total == 0) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message: l10n.noExpenseData,
        suggestion: l10n.addTransactionsToSeeChart,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 300,
          child: PieChart(
            PieChartData(
              sections: data.entries.toList().asMap().entries.map((entry) { // Sửa ở đây
                final index = entry.key;
                final category = entry.value.key;
                final value = entry.value.value;
                return PieChartSectionData(
                  color: AppTheme.categoryColors[index % AppTheme.categoryColors.length],
                  value: value,
                  title: '${(value / total * 100).toStringAsFixed(1)}%',
                  radius: 100,
                  titleStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: data.entries.toList().asMap().entries.map((entry) { // Sửa ở đây
            final index = entry.key;
            final category = entry.value.key;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  color: AppTheme.categoryColors[index % AppTheme.categoryColors.length],
                ),
                const SizedBox(width: 4),
                Text(
                  ListsCards.getLocalizedCategory(context, category),
                  style: GoogleFonts.poppins(fontSize: 12, color: theme.colorScheme.onSurface),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLineChart(BuildContext context, Map<DateTime, double> data, AppLocalizations l10n) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message: l10n.noBalanceData,
        suggestion: l10n.addTransactionsToSeeChart,
      );
    }

    final sortedDates = data.keys.toList()..sort();
    final minBalance = data.values.fold<double>(double.infinity, (min, v) => v < min ? v : min);
    final maxBalance = data.values.fold<double>(-double.infinity, (max, v) => v > max ? v : max);

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: GoogleFonts.poppins(fontSize: 10, color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedDates.length) return const SizedBox.shrink();
                  final date = sortedDates[value.toInt()];
                  return Text(
                    DateFormat('dd/MM').format(date),
                    style: GoogleFonts.poppins(fontSize: 10, color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
          ),
          minY: minBalance - (minBalance.abs() * 0.1),
          maxY: maxBalance + (maxBalance.abs() * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: sortedDates.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), data[entry.value]!);
              }).toList(),
              isCurved: true,
              color: AppTheme.incomeColor,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.incomeColor.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, Map<String, Map<String, dynamic>> data, AppLocalizations l10n) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message: l10n.noTransactionData,
        suggestion: l10n.addTransactionsToSeeChart,
      );
    }

    final maxAmount = data.values.fold<double>(
        0, (max, v) => (v['amount'] as double) > max ? v['amount'] as double : max);

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount + (maxAmount * 0.1),
          barGroups: data.entries.toList().asMap().entries.map((entry) { // Sửa ở đây
            final index = entry.key;
            final type = entry.value.key;
            final value = entry.value.value['amount'] as double;
            final color = entry.value.value['color'] as Color;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: color,
                  width: 20,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: GoogleFonts.poppins(fontSize: 10, color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= data.keys.length) return const SizedBox.shrink();
                  final type = data.keys.toList()[value.toInt()];
                  return Text(
                    ListsCards.getLocalizedType(context, type),
                    style: GoogleFonts.poppins(fontSize: 10, color: theme.colorScheme.onSurface),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }
}