import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/app_notification/notification_state.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/screens/top/top_screen.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/decorations.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WalletBloc>().add(LoadWallets());
      context.read<TransactionBloc>().add(LoadTransactions(authState.user.id));
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is TransactionSuccess) {
              // Tải lại dữ liệu khi thêm/xóa/sửa giao dịch
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                context.read<WalletBloc>().add(LoadWallets());
                context.read<TransactionBloc>().add(
                  LoadTransactions(authState.user.id),
                );
              }
            }
          },
        ),
      ],
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return UtilityWidgets.buildEmptyState(
              context: context,
              message: l10n.pleaseLoginToViewReports,
              suggestion: l10n.loginNow,
              onActionPressed: () {
                AppRoutes.navigateToLogin(context);
              },
              icon: Icons.lock_outline,
              actionText: l10n.loginTitle,
            );
          }

          return BlocBuilder<LocalizationBloc, LocalizationState>(
            builder: (context, localizationState) {
              final locale = localizationState.locale;

              return Scaffold(
                backgroundColor: theme.colorScheme.surface,
                appBar: AppBarTabBar.buildAppBar(
                  context: context,
                  title: l10n.appTitle,
                  showBackButton: false,
                  actions: [
                    BlocBuilder<NotificationBloc, NotificationState>(
                      builder: (context, state) {
                        final hasUnread = state.notifications.any(
                          (n) => !n.isRead,
                        );
                        return IconButton(
                          icon: Icon(
                            hasUnread
                                ? Icons.notifications
                                : Icons.notifications_outlined,
                            color: theme.colorScheme.onPrimary,
                          ),
                          tooltip: l10n.notificationsTooltip,
                          onPressed: () {
                            AppRoutes.navigateToAppNotification(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
                body: BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, walletState) {
                    return BlocBuilder<TransactionBloc, TransactionState>(
                      builder: (context, transactionState) {
                        if (walletState.isLoading ||
                            transactionState is TransactionLoading) {
                          return UtilityWidgets.buildLoadingIndicator(
                            context: context,
                          );
                        }

                        final wallets =
                            [
                              ...walletState.wallets,
                              ...walletState.savingsWallets,
                              ...walletState.investmentWallets,
                            ].where((w) => w.id.isNotEmpty).toList();

                        final transactions =
                            transactionState is TransactionLoaded
                                ? transactionState.transactions
                                : <TransactionModel>[];

                        return RefreshIndicator(
                          onRefresh: () async {
                            final authState = context.read<AuthBloc>().state;
                            if (authState is AuthAuthenticated) {
                              context.read<WalletBloc>().add(LoadWallets());
                              context.read<TransactionBloc>().add(
                                LoadTransactions(authState.user.id),
                              );
                            }
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  margin: const EdgeInsets.only(bottom: 100),
                                  child: Column(
                                    children: [
                                      _buildMainBalanceAndWallets(
                                        context,
                                        wallets,
                                        locale,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildChart(context, transactions),
                                      const SizedBox(height: 16),
                                      _buildRecentTransactionsSection(
                                        context,
                                        transactions,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildLoansSection(context, transactions),
                                      const SizedBox(height: 16),
                                      _buildSavingsSection(
                                        context,
                                        walletState.savingsWallets,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildInvestmentsSection(
                                        context,
                                        walletState.investmentWallets,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainBalanceAndWallets(
    BuildContext context,
    List<Wallet> wallets,
    Locale locale,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final totalBalance = wallets.fold<double>(
      0,
      (sum, wallet) => sum + wallet.balance,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: Decorations.boxDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UtilityWidgets.buildLabel(context: context, text: l10n.totalBalance),
          Text(
            NumberFormat.currency(
              locale: locale.toString(),
              symbol: _getCurrencySymbol(locale),
              decimalDigits: 0,
            ).format(totalBalance),
            style: GoogleFonts.notoSans(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color:
                  totalBalance >= 0
                      ? AppTheme.incomeColor
                      : AppTheme.expenseColor,
            ),
          ),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextButton(
                  onPressed: () {
                    AppRoutes.navigateToWallet(context);
                  },
                  child: Text(
                    l10n.viewAllAccounts,
                    style: GoogleFonts.notoSans(
                      fontSize: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Create data points for the chart
    List<ChartData> chartData = [];
    double cumulativeIncome = 0;
    double cumulativeExpense = 0;

    final sortedTransactions =
        transactions..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < sortedTransactions.length; i++) {
      final tx = sortedTransactions[i];
      final amount = tx.amount;

      if (tx.typeKey == 'income' || tx.typeKey == 'borrow') {
        cumulativeIncome += amount / 1000000;
      } else if (tx.typeKey == 'expense' ||
          tx.typeKey == 'lend' ||
          tx.typeKey == 'transfer') {
        cumulativeExpense += amount.abs() / 1000000;
      }

      chartData.add(
        ChartData(i, cumulativeIncome, cumulativeExpense, '${i + 1}'),
      );
    }

    // Add initial point if there are no transactions
    if (chartData.isEmpty) {
      chartData.add(ChartData(0, 0, 0, 'G1'));
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: Decorations.boxDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UtilityWidgets.buildLabel(context: context, text: l10n.spendingTrend),
          Expanded(
            child: SfCartesianChart(
              palette: [AppTheme.incomeColor, AppTheme.expenseColor],
              margin: EdgeInsets.zero,
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontFamily: 'Noto Sans',
                ),
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}M',
                axisLine: const AxisLine(width: 0),
                majorTickLines: const MajorTickLines(width: 0),
                majorGridLines: MajorGridLines(
                  width: 0.5,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  dashArray: const <double>[3, 3],
                ),
                labelStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 10,
                  fontFamily: 'Noto Sans',
                ),
              ),
              plotAreaBorderWidth: 0,
              tooltipBehavior: TooltipBehavior(
                enable: true,
                animationDuration: 150,
                color: theme.colorScheme.surface,
                textStyle: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontFamily: 'Noto Sans',
                ),
              ),
              legend: Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                overflowMode: LegendItemOverflowMode.wrap,
                textStyle: GoogleFonts.notoSans(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              series: <CartesianSeries>[
                SplineAreaSeries<ChartData, String>(
                  name: l10n.incomeType,
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.income,
                  color: AppTheme.incomeColor.withValues(alpha: 0.8),
                  borderWidth: 2,
                  borderColor: AppTheme.incomeColor,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.incomeColor.withValues(alpha: 0.5),
                      AppTheme.incomeColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                    shape: DataMarkerType.circle,
                    borderWidth: 1,
                    borderColor: AppTheme.incomeColor,
                    color: theme.colorScheme.surface,
                  ),
                  animationDuration: 1200,
                  animationDelay: 150,
                ),
                SplineAreaSeries<ChartData, String>(
                  name: l10n.expenseType,
                  dataSource: chartData,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.expense,
                  color: AppTheme.expenseColor.withValues(alpha: 0.8),
                  borderWidth: 2,
                  borderColor: AppTheme.expenseColor,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.expenseColor.withValues(alpha: 0.5),
                      AppTheme.expenseColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  markerSettings: MarkerSettings(
                    isVisible: true,
                    height: 4,
                    width: 4,
                    shape: DataMarkerType.circle,
                    borderWidth: 1,
                    borderColor: AppTheme.expenseColor,
                    color: theme.colorScheme.surface,
                  ),
                  animationDuration: 1200,
                  animationDelay: 300,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Sort by date in descending order (newest first) and then take the most recent 5
    final recentTransactions = List<TransactionModel>.from(transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    final topFiveTransactions = recentTransactions.take(5).toList();

    return _buildSection(
      context: context,
      title: l10n.recentTransactions,
      children:
          topFiveTransactions.isEmpty
              ? [
                UtilityWidgets.buildEmptyState(
                  context: context,
                  message: l10n.noTransactionsYet,
                  suggestion: l10n.addFirstTransactionHint,
                  icon: Icons.receipt_long_outlined,
                  actionText: l10n.addTransactionButton,
                  onActionPressed:
                      () => AppRoutes.navigateToTransaction(context),
                ),
              ]
              : topFiveTransactions
                  .map(
                    (tx) => ListsCards.buildTransactionListItem(
                      context: context,
                      transaction: tx,
                    ),
                  )
                  .toList(),
      onTap: () {
        // Navigate to the parent TopScreen and select the transactions tab (index 1)
        if (context.findAncestorStateOfType<TopScreenState>() != null) {
          context.findAncestorStateOfType<TopScreenState>()!.setSelectedIndex(
            1,
          );
        }
      },
    );
  }

  Widget _buildLoansSection(
    BuildContext context,
    List<TransactionModel> transactions,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // Sort loans by date in descending order (newest first)
    final loans =
        transactions
            .where((tx) => tx.typeKey == 'borrow' || tx.typeKey == 'lend')
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    final recentLoans = loans.take(3).toList();

    return _buildSection(
      context: context,
      title: l10n.loans,
      children:
          recentLoans.isEmpty
              ? [
                UtilityWidgets.buildEmptyState(
                  context: context,
                  message: l10n.noLoansYet,
                  suggestion: l10n.addLoanHint,
                  icon: Icons.account_balance_outlined,
                  actionText: l10n.addTransactionButton,
                  onActionPressed:
                      () => AppRoutes.navigateToTransaction(context),
                ),
              ]
              : recentLoans
                  .map(
                    (tx) => ListsCards.buildTransactionListItem(
                      context: context,
                      transaction: tx,
                    ),
                  )
                  .toList(),
      onTap: () {
        // Navigate to the parent TopScreen and select the transactions tab (index 1)
        if (context.findAncestorStateOfType<TopScreenState>() != null) {
          context.findAncestorStateOfType<TopScreenState>()!.setSelectedIndex(
            1,
          );
        }
      },
    );
  }

  Widget _buildSavingsSection(
    BuildContext context,
    List<Wallet> savingsWallets,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      context: context,
      title: l10n.savings,
      children:
          savingsWallets.isEmpty
              ? [
                UtilityWidgets.buildEmptyState(
                  context: context,
                  message: l10n.noSavingsYet,
                  suggestion: l10n.addSavingsHint,
                  icon: Icons.savings_outlined,
                  actionText: l10n.addSavingsButton,
                  onActionPressed: () => AppRoutes.navigateToWallet(context),
                ),
              ]
              : savingsWallets.take(3).map((wallet) {
                return ListsCards.buildItemCard(
                  context: context,
                  item: wallet,
                  itemKey: ValueKey(wallet.id),
                  title: wallet.name,
                  value: wallet.balance.toDouble(),
                  icon: wallet.icon,
                  valueLocale: Localizations.localeOf(context).toString(),
                  valuePrefix: '',
                  onTap: () => AppRoutes.navigateToWallet(context),
                );
              }).toList(),
      onTap: () => AppRoutes.navigateToWallet(context),
    );
  }

  Widget _buildInvestmentsSection(
    BuildContext context,
    List<Wallet> investmentWallets,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return _buildSection(
      context: context,
      title: l10n.tabInvestments,
      children:
          investmentWallets.isEmpty
              ? [
                UtilityWidgets.buildEmptyState(
                  context: context,
                  message: l10n.noInvestmentsYet,
                  suggestion: l10n.addInvestmentsHint,
                  icon: Icons.trending_up_outlined,
                  actionText: l10n.addInvestmentsButton,
                  onActionPressed: () => AppRoutes.navigateToWallet(context),
                ),
              ]
              : investmentWallets.take(3).map((wallet) {
                return ListsCards.buildItemCard(
                  context: context,
                  item: wallet,
                  itemKey: ValueKey(wallet.id),
                  title: wallet.name,
                  value: wallet.balance.toDouble(),
                  icon: wallet.icon,
                  valueLocale: Localizations.localeOf(context).toString(),
                  valuePrefix: '',
                  onTap: () => AppRoutes.navigateToWallet(context),
                );
              }).toList(),
      onTap: () => AppRoutes.navigateToWallet(context),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required VoidCallback? onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UtilityWidgets.buildLabel(context: context, text: title),
            TextButton(
              onPressed: onTap,
              child: Text(
                l10n.viewAll,
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: Decorations.boxDecoration(context),
          child: Column(children: children),
        ),
      ],
    );
  }
}

// Class for chart data
class ChartData {
  final int index;
  final double income;
  final double expense;
  final String label;

  ChartData(this.index, this.income, this.expense, this.label);
}
