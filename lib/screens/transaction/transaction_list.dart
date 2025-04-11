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
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/dialogs.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
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
      List<TransactionModel> transactions, int type, Locale locale) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      String key;
      switch (type) {
        case 0: // Ngày
          key = DateFormat.yMMMMd(locale.toString()).format(transaction.date);
          break;
        case 1: // Tháng
          key = DateFormat.yMMMM(locale.toString()).format(transaction.date);
          break;
        case 2: // Năm
          key = DateFormat.y(locale.toString()).format(transaction.date);
          break;
        default:
          key = DateFormat.yMMMMd(locale.toString()).format(transaction.date);
      }
      (grouped[key] ??= []).add(transaction);
    }
    return grouped;
  }

  List<TransactionModel> _filterTransactions(
      String query, List<TransactionModel> transactions) {
    if (query.isEmpty) return transactions;
    return transactions.where((t) {
      final queryLower = query.toLowerCase();
      return t.description.toLowerCase().contains(queryLower) ||
          t.typeKey.toLowerCase().contains(queryLower) ||
          (t.category.isNotEmpty &&
              t.category.toLowerCase().contains(queryLower)) ||
          (t.wallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.fromWallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.toWallet?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  Widget _buildGroupedListView(Map<String, List<TransactionModel>> groupedData,
      AppLocalizations l10n, Locale locale) {
    if (groupedData.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message:
        _isSearching ? l10n.noMatchingTransactions : l10n.noTransactionsYet,
        suggestion: _isSearching ? null : l10n.addFirstTransactionHint,
        onActionPressed:
        _isSearching ? null : () => AppRoutes.navigateToTransaction(context),
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
        final theme = Theme.of(context);

        double groupIncome = groupTransactions
            .where((t) => t.typeKey == 'income' || t.typeKey == 'borrow')
            .fold(0.0, (sum, t) => sum + t.amount);
        double groupExpense = groupTransactions
            .where((t) =>
        t.typeKey == 'expense' ||
            t.typeKey == 'lend' ||
            t.typeKey == 'transfer')
            .fold(0.0, (sum, t) => sum + t.amount);
        double groupNet = groupIncome - groupExpense;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                UtilityWidgets.buildLabel(context: context, text: groupKey),
                Text(
                  NumberFormat.currency(
                    locale: locale.toString(),
                    symbol: _getCurrencySymbol(locale),
                    decimalDigits: 0,
                  ).format(groupNet),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color:
                    groupNet >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...groupTransactions.map((t) => ListsCards.buildTransactionListItem(
              context: context,
              transaction: t,
              menuItems: MenuActions.buildEditDeleteMenuItems(context: context),
              onMenuSelected: (result) => _handleMenuAction(context, result, t),
            )),
            if (index < groupKeys.length - 1)
              Divider(
                height: 16,
                thickness: 0.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
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

  void _handleMenuAction(
      BuildContext context, String result, TransactionModel transaction) {
    MenuActions.handleEditDeleteActions(
      context: context,
      action: result,
      item: transaction,
      itemName: transaction.description,
      onEdit: _showEditDialog,
      onDelete: _confirmDeleteTransaction,
    );
  }

  void _showEditDialog(BuildContext context, TransactionModel transaction) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();
    final descriptionController =
    TextEditingController(text: transaction.description);
    final amountController = TextEditingController(
      text: Formatter.currencyInputFormatter
          .formatEditUpdate(const TextEditingValue(text: ''),
          TextEditingValue(text: transaction.amount.toString()))
          .text,
    );
    final balanceAfterController = TextEditingController(
      text: transaction.balanceAfter != null
          ? Formatter.currencyInputFormatter
          .formatEditUpdate(const TextEditingValue(text: ''),
          TextEditingValue(text: transaction.balanceAfter.toString()))
          .text
          : '',
    );
    final lenderController =
    TextEditingController(text: transaction.lender ?? '');
    final borrowerController =
    TextEditingController(text: transaction.borrower ?? '');

    DateTime selectedDate = transaction.date;
    DateTime? repaymentDate = transaction.repaymentDate;
    String selectedCategory = transaction.category;
    String selectedType =
    ListsCards.getLocalizedType(context, transaction.typeKey); // Dùng chuỗi dịch
    String selectedWallet = transaction.wallet ?? '';
    String selectedFromWallet = transaction.fromWallet ?? '';
    String selectedToWallet = transaction.toWallet ?? '';

    String? dateError;
    String? repaymentDateError;

    List<String> walletNames = [];
    final walletState = context.read<WalletBloc>().state;
    final allWallets = [
      ...walletState.wallets,
      ...walletState.savingsWallets,
      ...walletState.investmentWallets
    ].where((w) => w.id.isNotEmpty).toList();
    allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    walletNames = allWallets.map((w) => w.name).toList();
    final walletBalances =
    Map.fromEntries(allWallets.map((w) => MapEntry(w.name, w.balance.toDouble())));

    final transactionTypes = Constants.getTransactionTypes(l10n);
    final categories = Constants.getAvailableCategories(l10n);

    Dialogs.showFormDialog(
      context: context,
      formKey: formKey,
      title: l10n.editTransactionTitle,
      actionButtonText: l10n.save,
      formFields: [
        InputFields.buildTextField(
          controller: descriptionController,
          label: l10n.descriptionLabel,
          hint: l10n.descriptionHint,
          validator: (v) =>
              Validators.validateNotEmpty(v, fieldName: l10n.descriptionLabel),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        InputFields.buildDropdownField<String>(
          label: l10n.transactionTypeLabel,
          value: selectedType,
          items: transactionTypes
              .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              selectedType = newValue;
              balanceAfterController.clear();
              lenderController.clear();
              borrowerController.clear();
              repaymentDate = null;
              repaymentDateError = null;
              selectedCategory = selectedType == l10n.transactionTypeExpense &&
                  categories.isNotEmpty
                  ? categories.first
                  : '';
              if (walletNames.isNotEmpty) {
                selectedWallet = walletNames.first;
                selectedFromWallet = walletNames.first;
                selectedToWallet = walletNames.length > 1
                    ? walletNames[1]
                    : walletNames.first;
              }
            }
          },
          validator: (v) =>
              Validators.validateNotEmpty(v, fieldName: l10n.transactionTypeLabel),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        InputFields.buildDatePickerField(
          context: context,
          date: selectedDate,
          label: l10n.transactionDateLabel,
          onTap: (picked) {
            if (picked != null) selectedDate = picked;
          },
          errorText: dateError,
          isRequired: true,
        ),
        const SizedBox(height: 16),
        if (selectedType == l10n.transactionTypeExpense) ...[
          InputFields.buildDropdownField<String>(
            label: l10n.expenseCategoryLabel,
            value: selectedCategory,
            items: categories
                .map((cat) => DropdownMenuItem<String>(value: cat, child: Text(cat)))
                .toList(),
            onChanged: (v) => selectedCategory = v ?? selectedCategory,
            validator: (v) =>
                Validators.validateNotEmpty(v, fieldName: l10n.expenseCategoryLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDropdownField<String>(
            label: l10n.fromWalletLabel,
            value: selectedWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedWallet = v ?? selectedWallet,
            validator: (v) =>
                Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == l10n.transactionTypeIncome) ...[
          InputFields.buildDropdownField<String>(
            label: l10n.toWalletLabel,
            value: selectedWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedWallet = v ?? selectedWallet,
            validator: (v) =>
                Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == l10n.transactionTypeTransfer) ...[
          InputFields.buildDropdownField<String>(
            label: l10n.fromWalletSourceLabel,
            value: selectedFromWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                selectedFromWallet = newValue;
                if (walletNames.length > 1 && selectedToWallet == newValue) {
                  final availableTo =
                  walletNames.where((name) => name != newValue).toList();
                  selectedToWallet =
                  availableTo.isNotEmpty ? availableTo.first : '';
                }
              }
            },
            validator: (v) => Validators.validateWallet(
                v, fieldName: l10n.fromWalletSourceLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDropdownField<String>(
            label: l10n.toWalletDestinationLabel,
            value: selectedToWallet,
            items: walletNames
                .where((name) => name != selectedFromWallet)
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedToWallet = v ?? selectedToWallet,
            validator: (v) => Validators.validateWallet(
                v,
                fieldName: l10n.toWalletDestinationLabel,
                checkAgainst: selectedFromWallet),
            isRequired: true,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == l10n.transactionTypeBorrow) ...[
          InputFields.buildTextField(
            controller: lenderController,
            label: l10n.lenderLabel,
            hint: l10n.lenderHint,
            validator: (v) =>
                Validators.validateNotEmpty(v, fieldName: l10n.lenderLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDropdownField<String>(
            label: l10n.toWalletLabel,
            value: selectedWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedWallet = v ?? selectedWallet,
            validator: (v) =>
                Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDatePickerField(
            context: context,
            date: repaymentDate,
            label: l10n.repaymentDateOptionalLabel,
            onTap: (picked) => repaymentDate = picked,
            errorText: repaymentDateError,
            isRequired: false,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == l10n.transactionTypeLend) ...[
          InputFields.buildTextField(
            controller: borrowerController,
            label: l10n.borrowerLabel,
            hint: l10n.borrowerHint,
            validator: (v) =>
                Validators.validateNotEmpty(v, fieldName: l10n.borrowerLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDropdownField<String>(
            label: l10n.fromWalletLabel,
            value: selectedWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedWallet = v ?? selectedWallet,
            validator: (v) =>
                Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          InputFields.buildDatePickerField(
            context: context,
            date: repaymentDate,
            label: l10n.repaymentDateOptionalLabel,
            onTap: (picked) => repaymentDate = picked,
            errorText: repaymentDateError,
            isRequired: false,
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType == l10n.transactionTypeAdjustment) ...[
          InputFields.buildDropdownField<String>(
            label: l10n.walletToAdjustLabel,
            value: selectedWallet,
            items: walletNames
                .map((name) => DropdownMenuItem<String>(value: name, child: Text(name)))
                .toList(),
            onChanged: (v) => selectedWallet = v ?? selectedWallet,
            validator: (v) =>
                Validators.validateWallet(v, fieldName: l10n.walletToAdjustLabel),
            isRequired: true,
          ),
          const SizedBox(height: 16),
          UtilityWidgets.buildLabel(
              context: context, text: l10n.actualBalanceAfterAdjustmentLabel),
          const SizedBox(height: 8),
          InputFields.buildBalanceInputField(
            balanceAfterController,
            validator: (v) => Validators.validateBalanceAfterAdjustment(v),
          ),
          const SizedBox(height: 16),
        ],
        if (selectedType != l10n.transactionTypeAdjustment) ...[
          InputFields.buildBalanceInputField(
            amountController,
            validator: (value) {
              final currentBalance = walletBalances[selectedType ==
                  l10n.transactionTypeTransfer
                  ? selectedFromWallet
                  : selectedWallet] ??
                  0.0;
              return Validators.validateTransactionAmount(
                value: value,
                transactionType: selectedType,
                walletBalance: currentBalance,
                l10n: l10n,
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ],
      onActionButtonPressed: () {
        dateError = Validators.validateDate(selectedDate);
        if (selectedType == l10n.transactionTypeBorrow ||
            selectedType == l10n.transactionTypeLend) {
          repaymentDateError =
              Validators.validateRepaymentDate(repaymentDate, selectedDate);
        } else {
          repaymentDateError = null;
        }

        if (dateError != null || repaymentDateError != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.checkDateError)));
          return;
        }

        if (formKey.currentState!.validate()) {
          if (selectedType == l10n.transactionTypeTransfer) {
            if (selectedFromWallet.isEmpty || selectedToWallet.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.selectSourceAndDestinationWalletError)));
              return;
            }
            if (walletNames.length > 1 && selectedFromWallet == selectedToWallet) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.sourceAndDestinationWalletCannotBeSameError)));
              return;
            }
          } else if (selectedType != l10n.transactionTypeIncome) {
            if (selectedWallet.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                  Text(l10n.selectWalletForTransactionError(selectedType))));
              return;
            }
          }

          final amount = Formatter.getRawCurrencyValue(amountController.text).toDouble();
          final balanceAfter = selectedType == l10n.transactionTypeAdjustment
              ? Formatter.getRawCurrencyValue(balanceAfterController.text).toDouble()
              : null;

          String sourceWalletName = '';
          if (selectedType == l10n.transactionTypeExpense ||
              selectedType == l10n.transactionTypeLend) {
            sourceWalletName = selectedWallet;
          } else if (selectedType == l10n.transactionTypeTransfer) {
            sourceWalletName = selectedFromWallet;
          }

          if (sourceWalletName.isNotEmpty) {
            final sourceBalance = walletBalances[sourceWalletName] ?? 0.0;
            if (amount > sourceBalance) {
              final locale = Intl.getCurrentLocale();
              final formattedSourceBalance = NumberFormat.currency(
                  locale: locale, symbol: '', decimalDigits: 0)
                  .format(sourceBalance);
              final formattedAmount = NumberFormat.currency(
                  locale: locale, symbol: '', decimalDigits: 0)
                  .format(amount);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(l10n.insufficientBalanceError(
                        sourceWalletName, formattedSourceBalance, formattedAmount))),
              );
              return;
            }
          }

          String mapLocalizedTypeToKey(String localizedType, AppLocalizations l10n) {
            if (localizedType == l10n.transactionTypeIncome) return "income";
            if (localizedType == l10n.transactionTypeExpense) return "expense";
            if (localizedType == l10n.transactionTypeTransfer) return "transfer";
            if (localizedType == l10n.transactionTypeBorrow) return "borrow";
            if (localizedType == l10n.transactionTypeLend) return "lend";
            if (localizedType == l10n.transactionTypeAdjustment) return "adjustment";
            return localizedType; // Fallback
          }

          context.read<TransactionBloc>().add(
            UpdateTransaction(
              TransactionModel(
                id: transaction.id,
                userId: transaction.userId,
                description: descriptionController.text.trim(),
                amount: amount,
                date: selectedDate,
                typeKey: mapLocalizedTypeToKey(selectedType, l10n),
                category: selectedType == l10n.transactionTypeExpense
                    ? selectedCategory
                    : '',
                wallet: selectedType != l10n.transactionTypeTransfer
                    ? selectedWallet
                    : null,
                fromWallet: selectedType == l10n.transactionTypeTransfer
                    ? selectedFromWallet
                    : null,
                toWallet: selectedType == l10n.transactionTypeTransfer
                    ? selectedToWallet
                    : null,
                lender: selectedType == l10n.transactionTypeBorrow
                    ? lenderController.text.trim()
                    : null,
                borrower: selectedType == l10n.transactionTypeLend
                    ? borrowerController.text.trim()
                    : null,
                repaymentDate: (selectedType == l10n.transactionTypeBorrow ||
                    selectedType == l10n.transactionTypeLend)
                    ? repaymentDate
                    : null,
                balanceAfter: balanceAfter,
              ),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.checkInputError)));
        }
      },
    );
  }

  void _confirmDeleteTransaction(BuildContext context, TransactionModel transaction) {
    context.read<TransactionBloc>().add(DeleteTransaction(transaction.id));
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
                  SnackBar(content: Text(state.message(context))),
                );
                if (_isInitialized && _userId != null) {
                  context.read<WalletBloc>().add(LoadWallets());
                }
              } else if (state is TransactionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${l10n.genericError}: ${state.message}",
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.surface)),
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
                        AppBarTabBar.buildAppBar(
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
                            child: UtilityWidgets.buildSearchField(
                              context: context,
                              hintText: l10n.searchTransactionsHint,
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                            ),
                          ),
                        AppBarTabBar.buildTabBar(
                          context: context,
                          tabTitles: [
                            l10n.tabByDay,
                            l10n.tabByMonth,
                            l10n.tabByYear
                          ],
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

  Widget _buildTabViewContent(TransactionState state, int type,
      AppLocalizations l10n, Locale locale) {
    if (state is TransactionLoading || state is TransactionInitial) {
      return UtilityWidgets.buildLoadingIndicator(context: context);
    } else if (state is TransactionLoaded) {
      final transactions =
      _filterTransactions(_searchQuery, state.transactions)
        ..sort((a, b) => b.date.compareTo(a.date));
      if (transactions.isEmpty) {
        return UtilityWidgets.buildEmptyState(
          context: context,
          message:
          _isSearching ? l10n.noMatchingTransactions : l10n.noTransactionsYet,
          suggestion: _isSearching ? null : l10n.addFirstTransactionHint,
          onActionPressed:
          _isSearching ? null : () => AppRoutes.navigateToTransaction(context),
          actionText: _isSearching ? null : l10n.addTransactionButton,
        );
      }
      return _buildGroupedListView(_groupTransactions(transactions, type, locale), l10n, locale);
    } else if (state is TransactionError) {
      return UtilityWidgets.buildErrorState(
        context: context,
        message: state.message,
        onRetry: () {
          _refreshTransactions;
        },
      );
    }
    return const SizedBox.shrink();
  }
}