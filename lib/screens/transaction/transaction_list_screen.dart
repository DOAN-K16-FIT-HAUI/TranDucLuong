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
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/bottom_sheets.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/transaction_form.dart';
import 'package:finance_app/utils/common_widget/transaction_widgets.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

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

  // Change from single selection to multi-selection for type filters
  List<String> _selectedTypeFilters = [];
  String _sortOrder = 'newest'; // 'newest', 'oldest', 'highest', 'lowest'

  // Map ánh xạ giữa categoryKey và giá trị dịch
  Map<String, String> _categoryMap = {};
  // Add map for transaction types
  Map<String, String> _transactionTypeMap = {};

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

  void _updateCategoryMap(AppLocalizations l10n) {
    _categoryMap = {
      'food': l10n.categoryFood,
      'living': l10n.categoryLiving,
      'transport': l10n.categoryTransport,
      'health': l10n.categoryHealth,
      'shopping': l10n.categoryShopping,
      'entertainment': l10n.categoryEntertainment,
      'education': l10n.categoryEducation,
      'bills': l10n.categoryBills,
      'gift': l10n.categoryGift,
      'other': l10n.categoryOther,
    };

    // Add transaction type map
    _transactionTypeMap = {
      'income': l10n.transactionTypeIncome,
      'expense': l10n.transactionTypeExpense,
      'transfer': l10n.transactionTypeTransfer,
      'borrow': l10n.transactionTypeBorrow,
      'lend': l10n.transactionTypeLend,
      'adjustment': l10n.transactionTypeAdjustment,
    };
  }

  void _handleMenuAction(
    BuildContext context,
    String result,
    TransactionModel transaction,
  ) {
    MenuActions.handleEditDeleteActions(
      context: context,
      action: result,
      item: transaction,
      itemName: transaction.description,
      onEdit: _showEditDialog,
      onDelete: _confirmDeleteTransaction,
    );
  }

  void _showFilterBottomSheet() {
    TransactionWidgets.showFilterBottomSheet(
      context: context,
      transactionTypeMap: _transactionTypeMap,
      selectedTypeFilters: _selectedTypeFilters,
      onFiltersChanged: (filters) {
        setState(() {
          _selectedTypeFilters = filters;
        });
      },
    );
  }

  void _showSortBottomSheet() {
    TransactionWidgets.showSortBottomSheet(
      context: context,
      currentSortOrder: _sortOrder,
      onSortOrderChanged: (sortOrder) {
        setState(() {
          _sortOrder = sortOrder;
        });
      },
    );
  }

  void _showEditDialog(BuildContext context, TransactionModel transaction) {
    List<String> walletNames = [];
    final walletState = context.read<WalletBloc>().state;
    final allWallets =
        [
          ...walletState.wallets,
          ...walletState.savingsWallets,
          ...walletState.investmentWallets,
        ].where((w) => w.id.isNotEmpty).toList();
    walletNames = allWallets.map((w) => w.name).toList();
    final walletBalances = Map.fromEntries(
      allWallets.map((w) => MapEntry(w.name, w.balance.toDouble())),
    );

    TransactionForm.showEditTransactionDialog(
      context: context,
      transaction: transaction,
      categoryMap: _categoryMap,
      transactionTypeMap: _transactionTypeMap,
      walletNames: walletNames,
      walletBalances: walletBalances,
      onSave: (updatedTransaction) {
        context.read<TransactionBloc>().add(
          UpdateTransaction(updatedTransaction),
        );
      },
    );
  }

  void _confirmDeleteTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) {
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
    _updateCategoryMap(l10n);

    return BlocBuilder<LocalizationBloc, LocalizationState>(
      builder: (context, localizationState) {
        final locale = localizationState.locale;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: BlocConsumer<TransactionBloc, TransactionState>(
            listener: (context, state) {
              if (state is TransactionSuccess) {
                UtilityWidgets.showCustomSnackBar(
                  context: context,
                  message: state.message(context),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                );
                if (_isInitialized && _userId != null) {
                  context.read<WalletBloc>().add(LoadWallets());
                }
              } else if (state is TransactionError) {
                UtilityWidgets.showCustomSnackBar(
                  context: context,
                  message: "${l10n.genericError}: ${state.message(context)}",
                  backgroundColor: Theme.of(context).colorScheme.error,
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
                          showBackButton: false,
                          onBackPressed: () {
                            if (_isSearching) {
                              setState(() {
                                _isSearching = false;
                                _searchQuery = '';
                              });
                            } else {
                              context.pop();
                            }
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          actions: [
                            // Filter button
                            BottomSheets.buildFilterButton(
                              context: context,
                              tooltip: l10n.filterTooltip,
                              onPressed: _showFilterBottomSheet,
                            ),
                            // Sort button
                            BottomSheets.buildSortButton(
                              context: context,
                              tooltip: l10n.sortTooltip,
                              onPressed: _showSortBottomSheet,
                            ),
                            // Search button
                            IconButton(
                              icon: Icon(
                                _isSearching ? Icons.close : Icons.search,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              tooltip:
                                  _isSearching
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
                        if (state is TransactionLoading ||
                            state is TransactionInitial)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            child: UtilityWidgets.buildLoadingIndicator(
                              context: context,
                            ),
                          ),
                        // Search field
                        if (_isSearching)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: UtilityWidgets.buildSearchField(
                              context: context,
                              hintText: l10n.searchTransactionsHint,
                              onChanged:
                                  (value) =>
                                      setState(() => _searchQuery = value),
                            ),
                          ),
                        // Show active filters indicators
                        if (_selectedTypeFilters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 16.0,
                              bottom: 8.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        _selectedTypeFilters.map((filter) {
                                          return BottomSheets.buildFilterChip(
                                            context: context,
                                            label:
                                                _transactionTypeMap[filter] ??
                                                filter,
                                            onDeleted: () {
                                              setState(() {
                                                _selectedTypeFilters.remove(
                                                  filter,
                                                );
                                              });
                                            },
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Show sorting indicator
                        if (_sortOrder != 'newest')
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${l10n.sortLabel}: ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  _sortOrder == 'oldest'
                                      ? l10n.oldest
                                      : _sortOrder == 'highest'
                                      ? l10n.highestAmount
                                      : l10n.lowestAmount,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        if (!(state is TransactionLoading ||
                            state is TransactionInitial))
                          AppBarTabBar.buildTabBar(
                            context: context,
                            tabTitles: [
                              l10n.tabByDay,
                              l10n.tabByMonth,
                              l10n.tabByYear,
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
                  if (!(state is TransactionLoading ||
                      state is TransactionInitial))
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: List.generate(
                          3,
                          (index) => RefreshIndicator(
                            onRefresh: _refreshTransactions,
                            child: _buildTabViewContent(
                              state,
                              index,
                              l10n,
                              locale,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          )
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
    if (state is TransactionLoaded) {
      // First filter by search query
      var transactions = TransactionWidgets.filterTransactionsByQuery(
        query: _searchQuery,
        transactions: state.transactions,
        context: context,
        categoryMap: _categoryMap,
      );

      // Then filter by transaction type
      transactions = TransactionWidgets.filterTransactionsByType(
        transactions: transactions,
        typeFilters: _selectedTypeFilters,
      );

      // Finally sort transactions
      transactions = TransactionWidgets.sortTransactions(
        transactions: transactions,
        sortOrder: _sortOrder,
      );

      if (transactions.isEmpty) {
        return UtilityWidgets.buildEmptyState(
          context: context,
          message:
              _isSearching || _selectedTypeFilters.isNotEmpty
                  ? l10n.noMatchingTransactions
                  : l10n.noTransactionsYet,
          suggestion:
              (_isSearching || _selectedTypeFilters.isNotEmpty)
                  ? null
                  : l10n.addFirstTransactionHint,
          onActionPressed:
              (_isSearching || _selectedTypeFilters.isNotEmpty)
                  ? null
                  : () => AppRoutes.navigateToTransaction(context),
          actionText:
              (_isSearching || _selectedTypeFilters.isNotEmpty)
                  ? null
                  : l10n.addTransactionButton,
        );
      }

      final groupedData = TransactionWidgets.groupTransactions(
        transactions: transactions,
        groupType: type,
        locale: locale,
      );

      return TransactionWidgets.buildGroupedListView(
        context: context,
        groupedData: groupedData,
        l10n: l10n,
        locale: locale,
        onMenuAction: _handleMenuAction,
        isSearching: _isSearching,
      );
    } else if (state is TransactionError) {
      return UtilityWidgets.buildErrorState(
        context: context,
        message: state.message,
        onRetry: _refreshTransactions,
      );
    }
    return const SizedBox.shrink();
  }
}
