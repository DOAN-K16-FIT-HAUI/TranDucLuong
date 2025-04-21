import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/report/report_bloc.dart';
import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/buttons.dart';
import 'package:finance_app/utils/common_widget/decorations.dart';
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
      if (_startDate.isAfter(_endDate)) {
        UtilityWidgets.showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.invalidDateRange,
          backgroundColor: Theme.of(context).colorScheme.error,
          textStyle: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onError,
            fontSize: 14,
          ),
        );
        return;
      }
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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return UtilityWidgets.buildEmptyState(
              context: context,
              message: l10n.pleaseLoginToViewReports,
              suggestion: l10n.loginNow,
              onActionPressed: () {
                // Navigate to login screen
              },
              icon: Icons.lock_outline,
              actionText: l10n.loginTitle,
            );
          }

          return Column(
            children: [
              AppBarTabBar.buildAppBar(
                context: context,
                title: l10n.reportsTitle,
                showBackButton: false,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 4,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(16),
                decoration: Decorations.boxDecoration(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UtilityWidgets.buildLabel(
                      context: context,
                      text: l10n.dateRangeFilter,
                    ),
                    const SizedBox(height: 8),
                    Row(
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
                                });
                              }
                            },
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InputFields.buildDatePickerField(
                            context: context,
                            date: _endDate,
                            label: l10n.endDateLabel,
                            onTap: (picked) {
                              if (picked != null && mounted) {
                                setState(() {
                                  _endDate = picked;
                                });
                              }
                            },
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Buttons.buildSubmitButton(
                      context,
                      l10n.apply,
                      _loadReportData,
                      backgroundColor: theme.colorScheme.primary,
                      textColor: theme.colorScheme.onPrimary,
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: Decorations.boxDecoration(context),
                child: AppBarTabBar.buildTabBar(
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
                  indicatorColor: theme.colorScheme.primary,
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: BlocBuilder<ReportBloc, ReportState>(
                    key: ValueKey(_selectedChartType),
                    builder: (context, state) {
                      if (state is ReportLoading) {
                        return UtilityWidgets.buildLoadingIndicator(
                          context: context,
                          color: theme.colorScheme.primary,
                        );
                      } else if (state is ReportError) {
                        return UtilityWidgets.buildErrorState(
                          context: context,
                          message: state.message,
                          onRetry: _loadReportData,
                          icon: Icons.error_outline,
                          iconColor: theme.colorScheme.error,
                        );
                      } else if (state is ReportLoaded) {
                        return _buildChartContent(context, state, l10n);
                      }
                      return UtilityWidgets.buildEmptyState(
                        context: context,
                        message: l10n.noDataAvailable,
                        suggestion: l10n.selectDifferentDateRange,
                        icon: Icons.bar_chart_outlined,
                        actionText: l10n.tryAgain,
                        onActionPressed: _loadReportData,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartContent(BuildContext context, ReportLoaded state, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: Decorations.boxDecoration(context),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            UtilityWidgets.buildLabel(
              context: context,
              text: _selectedChartType == 'category'
                  ? l10n.categoryChart
                  : _selectedChartType == 'balance'
                  ? l10n.balanceChart
                  : l10n.typeChart,
            ),
            const SizedBox(height: 16),
            switch (_selectedChartType) {
              'category' => _buildPieChart(context, state.categoryExpenses, l10n),
              'balance' => _buildLineChart(context, state.dailyBalances, l10n),
              'type' => _buildBarChart(context, state.transactionTypeTotals, l10n),
              _ => const SizedBox.shrink(),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> data, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final total = data.values.fold(0.0, (sum, value) => sum + value);

    if (total == 0) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message: l10n.noExpenseData,
        suggestion: l10n.addTransactionsToSeeChart,
        icon: Icons.pie_chart_outline,
        actionText: l10n.addTransaction,
        onActionPressed: () {
          // Navigate to transaction creation screen
        },
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220, // Giảm chiều cao từ 320 xuống 220
          child: PieChart(
            PieChartData(
              sections: data.entries.toList().asMap().entries.map((entry) {
                final index = entry.key;
                final value = entry.value.value;
                return PieChartSectionData(
                  color: AppTheme.categoryColors[index % AppTheme.categoryColors.length],
                  value: value,
                  title: '${(value / total * 100).toStringAsFixed(1)}%',
                  radius: 80, // Giảm bán kính từ 120 xuống 80
                  titleStyle: GoogleFonts.poppins(
                    fontSize: 12, // Giảm cỡ chữ từ 14 xuống 12
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  titlePositionPercentageOffset: 0.6,
                );
              }).toList(),
              sectionsSpace: 2, // Giảm khoảng cách giữa các phần từ 4 xuống 2
              centerSpaceRadius: 40, // Giảm bán kính trung tâm từ 50 xuống 40
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.categoryColors[index % AppTheme.categoryColors.length],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  ListsCards.getLocalizedCategory(context, category),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface,
                  ),
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
        icon: Icons.show_chart_outlined,
        actionText: l10n.addTransaction,
        onActionPressed: () {
          // Navigate to transaction creation screen
        },
      );
    }

    final sortedDates = data.keys.toList()..sort();
    final minBalance = data.values.fold<double>(double.infinity, (min, v) => v < min ? v : min);
    final maxBalance = data.values.fold<double>(-double.infinity, (max, v) => v > max ? v : max);

    return SizedBox(
      height: 320,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: (maxBalance - minBalance) / 5,
            verticalInterval: sortedDates.length > 10 ? sortedDates.length / 5 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: (maxBalance - minBalance) / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: sortedDates.length > 10 ? sortedDates.length / 5 : 1,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= sortedDates.length) return const SizedBox.shrink();
                  final date = sortedDates[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          minY: minBalance - (minBalance.abs() * 0.1),
          maxY: maxBalance + (maxBalance.abs() * 0.1),
          lineBarsData: [
            LineChartBarData(
              spots: sortedDates.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), data[entry.value]!);
              }).toList(),
              isCurved: true,
              curveSmoothness: 0.35, // Tăng độ mượt của đường cong
              // color: [
              //   theme.colorScheme.primary,
              //   theme.colorScheme.secondary,
              // ],
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                  theme.colorScheme.secondary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              barWidth: 4, // Tăng độ dày đường từ 3 lên 4
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 5,
                  color: theme.colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: theme.colorScheme.onPrimary,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withValues(alpha: 0.3),
                    theme.colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
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
        icon: Icons.bar_chart_outlined,
        actionText: l10n.addTransaction,
        onActionPressed: () {
          // Navigate to transaction creation screen
        },
      );
    }

    final maxAmount = data.values.fold<double>(
        0, (max, v) => (v['amount'] as double) > max ? v['amount'] as double : max);

    return SizedBox(
      height: 360, // Tăng chiều cao để chứa nhãn dọc
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAmount + (maxAmount * 0.1),
          barGroups: data.entries.toList().asMap().entries.map((entry) {
            final index = entry.key;
            final value = entry.value.value['amount'] as double;
            final color = entry.value.value['color'] as Color;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  color: color,
                  width: 16, // Giảm chiều rộng thanh để chứa nhiều cột hơn
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxAmount + (maxAmount * 0.1),
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxAmount / 5,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60, // Tăng không gian cho nhãn xoay
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= data.keys.length) return const SizedBox.shrink();
                  final type = data.keys.toList()[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -45 * 3.14159 / 180, // Xoay nhãn 45 độ
                      child: Text(
                        ListsCards.getLocalizedType(context, type),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxAmount / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
        ),
      ),
    );
  }
}