import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> wallets = [
    {'name': 'Tiền mặt', 'balance': 1500000, 'icon': Icons.money_outlined},
    {'name': 'ATM', 'balance': 1200000, 'icon': Icons.credit_card_outlined},
  ];

  final List<Map<String, dynamic>> recentTransactions = [
    {
      'title': 'Ăn trưa',
      'amount': -340000,
      'count': 3,
      'icon': Icons.local_cafe_outlined,
    },
    {
      'title': 'Mua sách',
      'amount': -150000,
      'count': 1,
      'icon': Icons.book_outlined,
    },
  ];

  final List<Map<String, dynamic>> loans = [
    {
      'title': 'Chợ A vay',
      'amount': -10000,
      'note': 'Thời hạn còn lại 5 ngày',
      'icon': Icons.account_balance_outlined,
    },
  ];

  final List<Map<String, dynamic>> savings = [
    {
      'title': 'Sổ tiết kiệm 6 tháng',
      'amount': 5000000,
      'interest': '5.5%/năm',
      'icon': Icons.savings_outlined,
    },
  ];

  final List<Map<String, dynamic>> spendingLimits = [
    {
      'title': 'Hạn mức tháng 4',
      'limit': 3000000,
      'spent': 1200000,
      'icon': Icons.speed_outlined,
    },
  ];

  DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafeArea(context),
            _buildHeader(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildMainBalanceAndWallets(context),
                  const SizedBox(height: 16),
                  _buildChart(),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Giao dịch gần đây',
                    children:
                        recentTransactions
                            .map((tx) => _buildTransactionRow(tx))
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Vay nợ',
                    children:
                        loans
                            .map((loan) => _buildTransactionRow(loan))
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Sổ tiết kiệm',
                    children:
                        savings
                            .map(
                              (saving) => _buildTransactionRow(
                                saving,
                                AppTheme.incomeColor,
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    title: 'Hạn mức chi',
                    children:
                        spendingLimits
                            .map((limit) => _buildSpendingLimitRow(limit))
                            .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeArea(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Xin chào Lương',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMainBalanceAndWallets(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Tổng số dư',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(2917000),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.incomeColor,
            ),
            textAlign: TextAlign.center,
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
                    'Xem tất cả tài khoản',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:
                wallets.map((wallet) {
                  return GestureDetector(
                    onTap: () {
                      context.goNamed(AppRoutes.walletRoute);
                    },
                    child: _buildWalletRow(wallet, context),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    List<Map<String, dynamic>> allTransactions = [
      ...recentTransactions,
      ...loans,
      ...savings,
    ];

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    double cumulativeIncome = 0;
    double cumulativeExpense = 0;

    for (int i = 0; i < allTransactions.length; i++) {
      double amount = allTransactions[i]['amount'].toDouble();

      if (amount > 0) {
        cumulativeIncome += amount / 1000000;
        incomeSpots.add(FlSpot(i.toDouble(), cumulativeIncome));
        expenseSpots.add(FlSpot(i.toDouble(), cumulativeExpense));
      } else {
        cumulativeExpense += (amount.abs() / 1000000);
        expenseSpots.add(FlSpot(i.toDouble(), cumulativeExpense));
        incomeSpots.add(FlSpot(i.toDouble(), cumulativeIncome));
      }
    }

    if (incomeSpots.isEmpty) {
      incomeSpots.add(const FlSpot(0, 0));
    }
    if (expenseSpots.isEmpty) {
      expenseSpots.add(const FlSpot(0, 0));
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.lightTheme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
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
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'Xem tất cả',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _boxDecoration(),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildWalletRow(Map<String, dynamic> wallet, BuildContext context) {
    return Column(
      children: [
        Icon(
          wallet['icon'],
          size: 32,
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          wallet['name'],
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTransactionRow(Map<String, dynamic> tx, [Color? amountColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(
            tx['icon'],
            size: 24,
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (tx['count'] ?? 0) > 1
                      ? '${tx['title']} (${tx['count']} lần)'
                      : tx['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                if (tx['note'] != null)
                  Text(
                    tx['note'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.expenseColor,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${tx['amount'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  amountColor ??
                  (tx['amount'] < 0
                      ? AppTheme.expenseColor
                      : AppTheme.incomeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingLimitRow(Map<String, dynamic> limit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              limit['icon'],
              size: 24,
              color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                alpha: 0.6,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                limit['title'],
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ),
            Text(
              '${limit['spent'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} / ${limit['limit'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} ₫',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: limit['spent'] / limit['limit'],
          backgroundColor: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.2,
          ),
          valueColor: AlwaysStoppedAnimation<Color>(
            AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.2,
          ),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
