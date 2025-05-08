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
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/decorations.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
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

    return BlocBuilder<AuthBloc, AuthState>(
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

        return BlocBuilder<LocalizationBloc, LocalizationState>(
          builder: (context, localizationState) {
            final locale = localizationState.locale;

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: AppBarTabBar.buildAppBar(
                context: context,
                title: l10n.welcomeUser(authState.user.displayName ?? ''),
                showBackButton: false,
                actions: [
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final hasUnread = state.notifications.any((n) => !n.isRead);
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

                      final wallets = [
                        ...walletState.wallets,
                        ...walletState.savingsWallets,
                        ...walletState.investmentWallets,
                      ].where((w) => w.id.isNotEmpty).toList();

                      final transactions = transactionState is TransactionLoaded
                          ? transactionState.transactions
                          : <TransactionModel>[];

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16.0),
                              margin: const EdgeInsets.only(bottom: 100),
                              child: Column(
                                children: [
                                  _buildMainBalanceAndWallets(context, wallets, locale),
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
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
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
              color: totalBalance >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
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

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    double cumulativeIncome = 0;
    double cumulativeExpense = 0;

    final sortedTransactions =
    transactions..sort((a, b) => a.date.compareTo(b.date));

    for (int i = 0; i < sortedTransactions.length; i++) {
      final tx = sortedTransactions[i];
      final amount = tx.amount;

      if (tx.typeKey == 'income' || tx.typeKey == 'borrow') {
        cumulativeIncome += amount / 1000000;
        incomeSpots.add(FlSpot(i.toDouble(), cumulativeIncome));
        expenseSpots.add(FlSpot(i.toDouble(), cumulativeExpense));
      } else if (tx.typeKey == 'expense' ||
          tx.typeKey == 'lend' ||
          tx.typeKey == 'transfer') {
        cumulativeExpense += amount.abs() / 1000000;
        expenseSpots.add(FlSpot(i.toDouble(), cumulativeExpense));
        incomeSpots.add(FlSpot(i.toDouble(), cumulativeIncome));
      }
    }

    if (incomeSpots.isEmpty) incomeSpots.add(const FlSpot(0, 0));
    if (expenseSpots.isEmpty) expenseSpots.add(const FlSpot(0, 0));

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: Decorations.boxDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UtilityWidgets.buildLabel(context: context, text: l10n.spendingTrend),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}M',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'G${value.toInt() + 1}',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    color: AppTheme.incomeColor,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    color: AppTheme.expenseColor,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(show: false),
                  ),
                ],
              ),
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
    final recentTransactions = transactions.take(5).toList();

    return _buildSection(
      context: context,
      title: l10n.recentTransactions,
      children: recentTransactions.isEmpty
          ? [
        UtilityWidgets.buildEmptyState(
          context: context,
          message: l10n.noTransactionsYet,
          suggestion: l10n.addFirstTransactionHint,
          icon: Icons.receipt_long_outlined,
          actionText: l10n.addTransactionButton,
          onActionPressed: () => AppRoutes.navigateToTransaction(context),
        ),
      ]
          : recentTransactions
          .map(
            (tx) => ListsCards.buildTransactionListItem(
          context: context,
          transaction: tx,
        ),
      )
          .toList(),
      onTap: () => AppRoutes.navigateToTransactionList(context),
    );
  }

  Widget _buildLoansSection(
      BuildContext context,
      List<TransactionModel> transactions,
      ) {
    final l10n = AppLocalizations.of(context)!;
    final loans = transactions
        .where((tx) => tx.typeKey == 'borrow' || tx.typeKey == 'lend')
        .take(3)
        .toList();

    return _buildSection(
      context: context,
      title: l10n.loans,
      children: loans.isEmpty
          ? [
        UtilityWidgets.buildEmptyState(
          context: context,
          message: l10n.noLoansYet,
          suggestion: l10n.addLoanHint,
          icon: Icons.account_balance_outlined,
          actionText: l10n.addTransactionButton,
          onActionPressed: () => AppRoutes.navigateToTransaction(context),
        ),
      ]
          : loans
          .map(
            (tx) => ListsCards.buildTransactionListItem(
          context: context,
          transaction: tx,
        ),
      )
          .toList(),
      onTap: () {},
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
      children: savingsWallets.isEmpty
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
      children: investmentWallets.isEmpty
          ? [
        UtilityWidgets.buildEmptyState(
          context: context,
          message: l10n.noSavingsYet,
          suggestion: l10n.addSavingsHint,
          icon: Icons.trending_up_outlined,
          actionText: l10n.addWalletButton,
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