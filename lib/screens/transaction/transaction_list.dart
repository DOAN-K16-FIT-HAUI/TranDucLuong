import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen>
    with TickerProviderStateMixin {
  String? _userId;
  bool _isInitialized = false;
  late TabController _tabController;
  int _selectedTabIndex = 0;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _selectedTabIndex) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _userId = authState.user.id;
      context.read<TransactionBloc>().add(LoadTransactions(_userId!));
      _isInitialized = true;
    } else {
      debugPrint("TransactionListScreen: User not authenticated.");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Map<String, List<TransactionModel>> _groupTransactions(
      List<TransactionModel> transactions,
      int type,
      ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      String key;
      switch (type) {
        case 0:
          key = Formatter.formatDay(transaction.date);
          break;
        case 1:
          key = Formatter.formatMonth(transaction.date);
          break;
        case 2:
          key = Formatter.formatYear(transaction.date);
          break;
        default:
          key = Formatter.formatDay(transaction.date);
      }
      (grouped[key] ??= []).add(transaction);
    }
    return grouped;
  }

  List<TransactionModel> _filterTransactions(
      String query,
      List<TransactionModel> transactions,
      ) {
    if (query.isEmpty) return transactions;
    return transactions.where((t) {
      final queryLower = query.toLowerCase();
      return t.description.toLowerCase().contains(queryLower) ||
          t.type.toLowerCase().contains(queryLower) ||
          (t.category.isNotEmpty && t.category.toLowerCase().contains(queryLower)) ||
          (t.wallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.fromWallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.toWallet?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  Widget _buildGroupedListView(
      Map<String, List<TransactionModel>> groupedData,
      AppLocalizations l10n,
      Locale locale,
      ) {
    if (groupedData.isEmpty) {
      return CommonWidgets.buildEmptyState(
        context: context,
        message: _isSearching ? l10n.noMatchingTransactions : l10n.noTransactionsYet,
        suggestion: _isSearching ? null : l10n.addFirstTransactionHint,
        onActionPressed: _isSearching ? null : () => AppRoutes.navigateToTransaction(context),
        actionText: _isSearching ? null : l10n.addTransactionButton,
      );
    }

    final groupKeys = groupedData.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupKey = groupKeys[index];
        final groupTransactions = groupedData[groupKey]!;

        double groupIncome = groupTransactions
            .where((t) => t.type == 'Thu nhập' || t.type == 'Đi vay')
            .fold(0.0, (sum, t) => sum + t.amount);
        double groupExpense = groupTransactions
            .where((t) => t.type == 'Chi tiêu' || t.type == 'Cho vay')
            .fold(0.0, (sum, t) => sum + t.amount);
        double groupNet = groupIncome - groupExpense;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  groupKey,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  ),
                ),
                Text(
                  NumberFormat.currency(
                    locale: locale.toString(),
                    symbol: _getCurrencySymbol(locale),
                    decimalDigits: 0,
                  ).format(groupNet),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: groupNet >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...groupTransactions.map((t) => _buildTransactionCard(context, t, locale)),
            if (index < groupKeys.length - 1)
              Divider(
                height: 16,
                thickness: 0.5,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
          ],
        );
      },
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

  Widget _buildTransactionCard(
      BuildContext context,
      TransactionModel transaction,
      Locale locale,
      ) {
    final l10n = AppLocalizations.of(context)!;
    final iconData = CommonWidgets.getTransactionIcon(transaction.type);
    final amountColor = CommonWidgets.getAmountColor(context, transaction.type);
    final formattedTime = Formatter.formatTime(transaction.date);

    String subtitleText = '$formattedTime • ${transaction.wallet ?? ''}';
    if (transaction.type == 'Chi tiêu' && transaction.category.isNotEmpty) {
      subtitleText = '$formattedTime • ${transaction.category}';
    } else if (transaction.type == 'Chuyển khoản') {
      subtitleText = '$formattedTime • ${l10n.from}: ${transaction.fromWallet ?? '?'} → ${l10n.to}: ${transaction.toWallet ?? '?'}';
    } else if (transaction.type == 'Đi vay' && transaction.lender != null) {
      subtitleText = '$formattedTime • ${l10n.borrowFrom}: ${transaction.lender}';
    } else if (transaction.type == 'Cho vay' && transaction.borrower != null) {
      subtitleText = '$formattedTime • ${l10n.lendTo}: ${transaction.borrower}';
    }

    return CommonWidgets.buildItemCard(
      context: context,
      item: transaction,
      itemKey: ValueKey(transaction.id),
      title: transaction.description.isNotEmpty ? transaction.description : l10n.noDescription,
      value: transaction.amount,
      icon: iconData['icon'],
      iconColor: iconData['backgroundColor'],
      valueLocale: locale.toString(),
      valuePrefix: CommonWidgets.getAmountPrefix(context, transaction.type),
      menuItems: CommonWidgets.buildEditDeleteMenuItems(context: context),
      onMenuSelected: (result) {
        if (result == 'edit') {
          _showEditDialog(context, transaction);
        } else if (result == 'delete') {
          CommonWidgets.showDeleteDialog(
            context: context,
            title: l10n.confirmDeleteTitle,
            content: l10n.confirmDeleteTransactionContent(transaction.description),
            onDeletePressed: () =>
                context.read<TransactionBloc>().add(DeleteTransaction(transaction.id)),
          );
        }
      },
      subtitle: Text(
        subtitleText,
        style: GoogleFonts.poppins(
          color: Theme.of(context).hintColor,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showEditDialog(BuildContext context, TransactionModel transaction) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController(text: transaction.description);
    final amountController = TextEditingController(
      text: Formatter.currencyInputFormatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        TextEditingValue(text: transaction.amount.toString()),
      ).text,
    );
    DateTime selectedDate = transaction.date;
    String selectedType = transaction.type;
    String selectedCategory = transaction.category;
    String? selectedWallet = transaction.wallet;
    String? selectedFromWallet = transaction.fromWallet;
    String? selectedToWallet = transaction.toWallet;
    final lenderController = TextEditingController(text: transaction.lender ?? '');
    final borrowerController = TextEditingController(text: transaction.borrower ?? '');
    DateTime? selectedRepaymentDate = transaction.repaymentDate;

    List<String> walletNames = [];
    final walletState = context.read<WalletBloc>().state;
    final allWallets = [
      ...walletState.wallets,
      ...walletState.savingsWallets,
      ...walletState.investmentWallets,
    ].where((w) => w.id.isNotEmpty).toList();
    allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    walletNames = allWallets.map((w) => w.name).toList();

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      title: l10n.editTransactionTitle,
      actionButtonText: l10n.save,
      formFields: [
        CommonWidgets.buildTextField(
          controller: descriptionController,
          label: l10n.descriptionLabel,
          hint: l10n.descriptionHint,
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(amountController),
        const SizedBox(height: 16),
        CommonWidgets.buildDatePickerField(
          context: context,
          date: selectedDate,
          label: l10n.transactionDateLabel,
          onTap: (picked) => selectedDate = picked ?? selectedDate,
        ),
        // Thêm các trường khác nếu cần
      ],
      onActionButtonPressed: () {
        if (formKey.currentState!.validate()) {
          context.read<TransactionBloc>().add(UpdateTransaction(
            TransactionModel(
              id: transaction.id,
              userId: transaction.userId,
              description: descriptionController.text.trim(),
              amount: Formatter.getRawCurrencyValue(amountController.text).toDouble(),
              date: selectedDate,
              type: selectedType,
              category: selectedType == 'Chi tiêu' ? selectedCategory : '',
              wallet: selectedType != 'Chuyển khoản' ? selectedWallet : null,
              fromWallet: selectedType == 'Chuyển khoản' ? selectedFromWallet : null,
              toWallet: selectedType == 'Chuyển khoản' ? selectedToWallet : null,
              lender: selectedType == 'Đi vay' ? lenderController.text.trim() : null,
              borrower: selectedType == 'Cho vay' ? borrowerController.text.trim() : null,
              repaymentDate: (selectedType == 'Đi vay' || selectedType == 'Cho vay')
                  ? selectedRepaymentDate
                  : null,
              balanceAfter: transaction.balanceAfter,
            ),
          ));
        }
      },
    );
  }

  Future<void> _refreshTransactions() async {
    if (_isInitialized && _userId != null) {
      context.read<TransactionBloc>().add(LoadTransactions(_userId!));
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final locale = localizationState.locale;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: BlocConsumer<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    backgroundColor: AppTheme.incomeColor,
                  ),
                );
                if (_isInitialized && _userId != null) {
                  context.read<WalletBloc>().add(LoadWallets());
                }
              } else if (state is TransactionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "${l10n.genericError}: ${state.message}",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    backgroundColor: AppTheme.expenseColor,
                  ),
                );
              }
            },
            builder: (context, state) {
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        CommonWidgets.buildAppBar(
                          context: context,
                          title: l10n.transactionHistoryTitle,
                          onBackPressed: () {
                            if (_isSearching) {
                              setState(() {
                                _isSearching = false;
                                _searchQuery = '';
                              });
                            } else {
                              AppRoutes.navigateToDashboard(context);
                            }
                          },
                          actions: [
                            IconButton(
                              icon: Icon(_isSearching ? Icons.close : Icons.search),
                              tooltip: _isSearching
                                  ? l10n.closeSearchTooltip
                                  : l10n.searchTooltip,
                              onPressed: () {
                                setState(() {
                                  _isSearching = !_isSearching;
                                  if (!_isSearching) _searchQuery = '';
                                });
                              },
                            ),
                          ],
                        ),
                        if (_isSearching)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: CommonWidgets.buildSearchField(
                              context: context,
                              hintText: l10n.searchTransactionsHint,
                              onChanged: (value) => setState(() => _searchQuery = value),
                            ),
                          ),
                        CommonWidgets.buildTabBar(
                          context: context,
                          tabTitles: [l10n.tabByDay, l10n.tabByMonth, l10n.tabByYear],
                          onTabChanged: (index) {
                            setState(() {
                              _selectedTabIndex = index;
                              _tabController.animateTo(index);
                            });
                          },
                          controller: _tabController,
                        ),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        3,
                            (index) => RefreshIndicator(
                          onRefresh: _refreshTransactions,
                          child: _buildTabViewContent(state, index, l10n, locale),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => AppRoutes.navigateToTransaction(context),
            tooltip: l10n.addTransactionTooltip,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
          ),
        );
      },
    );
  }

  Widget _buildTabViewContent(
      TransactionState state,
      int type,
      AppLocalizations l10n,
      Locale locale,
      ) {
    if (state is TransactionLoading || state is TransactionInitial) {
      return CommonWidgets.buildLoadingIndicator(context: context);
    } else if (state is TransactionLoaded) {
      final transactions = _filterTransactions(_searchQuery, state.transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      if (transactions.isEmpty) {
        return CommonWidgets.buildEmptyState(
          context: context,
          message: l10n.noTransactionsYet,
          suggestion: l10n.addFirstTransactionHint,
          onActionPressed: () => AppRoutes.navigateToTransaction(context),
          actionText: l10n.addTransactionButton,
        );
      }
      return _buildGroupedListView(_groupTransactions(transactions, type), l10n, locale);
    } else if (state is TransactionError) {
      return CommonWidgets.buildErrorState(
        context: context,
        message: state.message,
        onRetry: _refreshTransactions,
      );
    }
    return const SizedBox.shrink();
  }
}