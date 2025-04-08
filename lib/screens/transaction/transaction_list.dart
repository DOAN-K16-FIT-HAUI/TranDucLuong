import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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

  Map<String, List<TransactionModel>> _groupTransactionsByDay(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final dayKey = Formatter.formatDay(transaction.date);
      (grouped[dayKey] ??= []).add(transaction);
    }
    return grouped;
  }

  Map<String, List<TransactionModel>> _groupTransactionsByMonth(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final monthKey = Formatter.formatMonth(transaction.date);
      (grouped[monthKey] ??= []).add(transaction);
    }
    return grouped;
  }

  Map<String, List<TransactionModel>> _groupTransactionsByYear(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      final yearKey = Formatter.formatYear(transaction.date);
      (grouped[yearKey] ??= []).add(transaction);
    }
    return grouped;
  }

  List<TransactionModel> _filterTransactions(
    String query,
    List<TransactionModel> transactions,
  ) {
    if (query.isEmpty) return transactions;
    return transactions.where((transaction) {
      return transaction.description.toLowerCase().contains(
            query.toLowerCase(),
          ) ||
          transaction.type.toLowerCase().contains(query.toLowerCase()) ||
          (transaction.category.isNotEmpty &&
              transaction.category.toLowerCase().contains(
                query.toLowerCase(),
              )) ||
          (transaction.wallet != null &&
              transaction.wallet!.toLowerCase().contains(query.toLowerCase()));
    }).toList();
  }

  Widget _buildGroupedListView(
    Map<String, List<TransactionModel>> groupedData,
  ) {
    if (groupedData.isEmpty) {
      return Center(
        child: Text(
          _isSearching
              ? 'Không tìm thấy giao dịch phù hợp'
              : 'Không có giao dịch nào',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 204,
            ),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final groupKeys = groupedData.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0).copyWith(bottom: 80),
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

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
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
                      color: AppTheme.lightTheme.colorScheme.primary.withValues(
                        alpha: 0.9,
                      ),
                    ),
                  ),
                  Text(
                    Formatter.formatCurrency(groupNet),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color:
                          groupNet >= 0
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                    ),
                  ),
                ],
              ),
              Column(
                children:
                    groupTransactions
                        .asMap()
                        .entries
                        .map(
                          (entry) => _buildTransactionCard(
                            context: context,
                            transaction: entry.value,
                            type: _selectedTabIndex,
                            index: entry.key,
                          ),
                        )
                        .toList(),
              ),
              if (index < groupKeys.length - 1)
                Divider(
                  height: 16,
                  thickness: 0.5,
                  indent: 16,
                  endIndent: 16,
                  color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                    alpha: 0.2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionCard({
    required BuildContext context,
    required TransactionModel transaction,
    required int type,
    required int index,
  }) {
    return CommonWidgets.buildItemCard(
      context: context,
      item: transaction,
      itemKey: ValueKey(transaction.id),
      title:
          transaction.description.isNotEmpty
              ? transaction.description
              : 'Không có mô tả',
      value: transaction.amount,
      icon:
          transaction.type == 'Thu nhập' || transaction.type == 'Đi vay'
              ? Icons.arrow_downward
              : Icons.arrow_upward,
      menuItems: CommonWidgets.buildEditDeleteMenuItems(context: context),
      onMenuSelected: (result) {
        CommonWidgets.handleEditDeleteActions(
          context: context,
          action: result,
          item: transaction,
          itemName:
              transaction.description.isNotEmpty
                  ? transaction.description
                  : 'giao dịch này',
          onEdit:
              (context, transaction) => _showEditDialog(context, transaction),
          onDelete:
              (context, transaction) => context.read<TransactionBloc>().add(
                DeleteTransaction(transaction.id),
              ),
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, TransactionModel transaction) {
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController(
      text: transaction.description,
    );
    final amountController = TextEditingController(
      text:
          Formatter.currencyInputFormatter
              .formatEditUpdate(
                TextEditingValue.empty,
                TextEditingValue(text: transaction.amount.toString()),
              )
              .text,
    );
    DateTime selectedDate = transaction.date;
    String selectedType = transaction.type;
    String selectedCategory = transaction.category;
    String? selectedWallet = transaction.wallet;
    String? selectedFromWallet = transaction.fromWallet;
    String? selectedToWallet = transaction.toWallet;
    final lenderController = TextEditingController(
      text: transaction.lender ?? '',
    );
    final borrowerController = TextEditingController(
      text: transaction.borrower ?? '',
    );
    DateTime? selectedRepaymentDate = transaction.repaymentDate;

    // Danh sách cho dropdown (tương tự TransactionScreen)
    final List<String> transactionTypes = Constants.transactionTypes;
    final List<String> categories = Constants.availableCategories;

    // Lấy danh sách ví từ WalletBloc
    List<String> walletNames = [];
    final walletState = context.read<WalletBloc>().state;
    final allWallets =
        [
          ...walletState.wallets,
          ...walletState.savingsWallets,
          ...walletState.investmentWallets,
        ].where((w) => w.id.isNotEmpty).toList();
    allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    walletNames = allWallets.map((wallet) => wallet.name).toList();

    // Nếu ví hiện tại không có trong danh sách, đặt về giá trị mặc định
    if (!walletNames.contains(selectedWallet) && walletNames.isNotEmpty) {
      selectedWallet = walletNames.first;
    }
    if (!walletNames.contains(selectedFromWallet) && walletNames.isNotEmpty) {
      selectedFromWallet = walletNames.first;
    }
    if (!walletNames.contains(selectedToWallet) && walletNames.isNotEmpty) {
      final availableToWallets =
          walletNames.where((name) => name != selectedFromWallet).toList();
      selectedToWallet =
          availableToWallets.isNotEmpty
              ? availableToWallets.first
              : walletNames.first;
    }

    CommonWidgets.showFormDialog(
      context: context,
      formKey: formKey,
      formFields: [
        CommonWidgets.buildTextField(
          controller: descriptionController,
          label: 'Diễn giải',
          hint: 'Nhập mô tả (vd: Ăn trưa, Tiền nhà)',
          validator: Validators.validateDescription,
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildBalanceInputField(
          amountController,
          validator: Validators.validateBalanceAfterAdjustment,
        ),
        const SizedBox(height: 16),
        CommonWidgets.buildDatePickerField(
          context: context,
          date: selectedDate,
          label: 'Ngày giao dịch',
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() => selectedDate = pickedDate);
            }
          },
        ),
        const SizedBox(height: 16),
        StatefulBuilder(
          builder:
              (context, setState) => CommonWidgets.buildDropdownField(
                label: 'Loại giao dịch',
                value: selectedType,
                items: transactionTypes,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedType = newValue;
                      // Reset các trường không liên quan khi đổi loại giao dịch
                      if (selectedType != 'Chi tiêu') {
                        selectedCategory = categories.first;
                      }
                      if (selectedType != 'Chuyển khoản') {
                        selectedFromWallet =
                            walletNames.isNotEmpty ? walletNames.first : null;
                        selectedToWallet =
                            walletNames.isNotEmpty
                                ? (walletNames.length > 1
                                    ? walletNames
                                        .where(
                                          (name) => name != selectedFromWallet,
                                        )
                                        .first
                                    : walletNames.first)
                                : null;
                      }
                      if (selectedType != 'Đi vay') {
                        lenderController.clear();
                      }
                      if (selectedType != 'Cho vay') {
                        borrowerController.clear();
                      }
                      if (selectedType != 'Đi vay' &&
                          selectedType != 'Cho vay') {
                        selectedRepaymentDate = null;
                      }
                    });
                  }
                },
                validator: Validators.validateNotEmpty,
              ),
        ),
        const SizedBox(height: 16),
        if (selectedType == 'Chi tiêu') ...[
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Danh mục chi tiêu',
                  value: selectedCategory,
                  items: categories,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedCategory = newValue);
                    }
                  },
                  validator: Validators.validateCategory,
                ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Từ ví',
                  value: selectedWallet ?? '',
                  items: walletNames,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedWallet = newValue);
                    }
                  },
                  validator:
                      (v) => Validators.validateWallet(
                        v,
                        fieldName: "Ví chi tiêu",
                      ),
                ),
          ),
        ],
        if (selectedType == 'Thu nhập') ...[
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Vào ví',
                  value: selectedWallet ?? '',
                  items: walletNames,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedWallet = newValue);
                    }
                  },
                  validator:
                      (v) => Validators.validateWallet(
                        v,
                        fieldName: "Ví nhận tiền",
                      ),
                ),
          ),
        ],
        if (selectedType == 'Chuyển khoản') ...[
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Từ ví (Nguồn)',
                  value: selectedFromWallet ?? '',
                  items: walletNames,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedFromWallet = newValue;
                        // Tự động chọn ví đích khác nếu trùng
                        if (walletNames.length > 1 &&
                            selectedToWallet == newValue) {
                          final otherWallets =
                              walletNames
                                  .where((name) => name != newValue)
                                  .toList();
                          selectedToWallet =
                              otherWallets.isNotEmpty ? otherWallets.first : '';
                        }
                      });
                    }
                  },
                  validator:
                      (v) =>
                          Validators.validateWallet(v, fieldName: "Ví nguồn"),
                ),
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Đến ví (Đích)',
                  value: selectedToWallet ?? '',
                  items:
                      walletNames
                          .where((name) => name != selectedFromWallet)
                          .toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedToWallet = newValue);
                    }
                  },
                  validator:
                      (v) => Validators.validateWallet(
                        v,
                        fieldName: "Ví đích",
                        checkAgainst: selectedFromWallet,
                      ),
                ),
          ),
        ],
        if (selectedType == 'Đi vay') ...[
          CommonWidgets.buildTextField(
            controller: lenderController,
            label: 'Người cho vay',
            hint: 'Tên người hoặc tổ chức cho vay',
            validator: Validators.validateNotEmpty,
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Vào ví',
                  value: selectedWallet ?? '',
                  items: walletNames,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedWallet = newValue);
                    }
                  },
                  validator:
                      (v) => Validators.validateWallet(
                        v,
                        fieldName: "Ví nhận tiền vay",
                      ),
                ),
          ),
          const SizedBox(height: 16),
          CommonWidgets.buildDatePickerField(
            context: context,
            date: selectedRepaymentDate ?? DateTime.now(),
            label: 'Ngày hẹn trả (tùy chọn)',
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedRepaymentDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() => selectedRepaymentDate = pickedDate);
              }
            },
          ),
        ],
        if (selectedType == 'Cho vay') ...[
          CommonWidgets.buildTextField(
            controller: borrowerController,
            label: 'Người vay tiền',
            hint: 'Tên người hoặc tổ chức vay',
            validator: Validators.validateNotEmpty,
          ),
          const SizedBox(height: 16),
          StatefulBuilder(
            builder:
                (context, setState) => CommonWidgets.buildDropdownField(
                  label: 'Từ ví',
                  value: selectedWallet ?? '',
                  items: walletNames,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => selectedWallet = newValue);
                    }
                  },
                  validator:
                      (v) =>
                          Validators.validateWallet(v, fieldName: "Ví cho vay"),
                ),
          ),
          const SizedBox(height: 16),
          CommonWidgets.buildDatePickerField(
            context: context,
            date: selectedRepaymentDate ?? DateTime.now(),
            label: 'Ngày hẹn trả (tùy chọn)',
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedRepaymentDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() => selectedRepaymentDate = pickedDate);
              }
            },
          ),
        ],
      ],
      title: 'Sửa thông tin giao dịch',
      actionButtonText: 'Lưu',
      onActionButtonPressed: () {
        if (formKey.currentState!.validate()) {
          context.read<TransactionBloc>().add(
            UpdateTransaction(
              TransactionModel(
                id: transaction.id,
                userId: transaction.userId,
                description: descriptionController.text.trim(),
                amount:
                    Formatter.getRawCurrencyValue(
                      amountController.text,
                    ).toDouble(),
                date: selectedDate,
                type: selectedType,
                category: selectedType == 'Chi tiêu' ? selectedCategory : '',
                wallet:
                    (selectedType != 'Chuyển khoản') ? selectedWallet : null,
                fromWallet:
                    (selectedType == 'Chuyển khoản')
                        ? selectedFromWallet
                        : null,
                toWallet:
                    (selectedType == 'Chuyển khoản') ? selectedToWallet : null,
                lender:
                    (selectedType == 'Đi vay')
                        ? lenderController.text.trim()
                        : null,
                borrower:
                    (selectedType == 'Cho vay')
                        ? borrowerController.text.trim()
                        : null,
                repaymentDate:
                    (selectedType == 'Đi vay' || selectedType == 'Cho vay')
                        ? selectedRepaymentDate
                        : null,
                balanceAfter: transaction.balanceAfter,
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _refreshTransactions() async {
    if (_isInitialized && _userId != null) {
      debugPrint("Refreshing transactions for user $_userId");
      context.read<TransactionBloc>().add(LoadTransactions(_userId!));
    } else {
      debugPrint(
        "Cannot refresh: Screen not initialized or user not authenticated.",
      );
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      body: BlocConsumer<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionSuccess &&
              !ModalRoute.of(context)!.isCurrent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.lightTheme.colorScheme.surface,
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
                  "Lỗi: ${state.message}",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.lightTheme.colorScheme.surface,
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
                      title: 'Lịch sử Giao dịch',
                      backIcon: Icons.arrow_back,
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
                          icon: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            color: AppTheme.lightTheme.colorScheme.surface,
                          ),
                          tooltip: _isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
                          onPressed: () {
                            setState(() {
                              _isSearching = !_isSearching;
                              if (!_isSearching) {
                                _searchQuery = '';
                              }
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
                          hintText: 'Tìm kiếm giao dịch...',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 16),
                    CommonWidgets.buildTabBar(
                      context: context,
                      tabTitles: const ['Theo Ngày', 'Theo Tháng', 'Theo Năm'],
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
                  children: [
                    RefreshIndicator(
                      onRefresh: _refreshTransactions,
                      color: AppTheme.lightTheme.indicatorColor,
                      child: _buildTabViewContent(state, 0),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshTransactions,
                      color: AppTheme.lightTheme.indicatorColor,
                      child: _buildTabViewContent(state, 1),
                    ),
                    RefreshIndicator(
                      onRefresh: _refreshTransactions,
                      color: AppTheme.lightTheme.indicatorColor,
                      child: _buildTabViewContent(state, 2),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          AppRoutes.navigateToTransaction(context);
        },
        tooltip: 'Thêm giao dịch mới',
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        child: Icon(Icons.add, color: AppTheme.lightTheme.colorScheme.surface),
      ),
    );
  }

  Widget _buildTabViewContent(TransactionState state, int type) {
    if (state is TransactionInitial) {
      return CommonWidgets.buildLoadingIndicator(context);
    } else if (state is TransactionLoading) {
      return CommonWidgets.buildLoadingIndicator(context);
    } else if (state is TransactionLoaded) {
      final transactions = _filterTransactions(
        _searchQuery,
        state.transactions,
      );
      transactions.sort((a, b) => b.date.compareTo(a.date));
      if (transactions.isEmpty) {
        return CommonWidgets.buildEmptyState(
          context: context,
          message: 'Chưa có giao dịch nào',
          suggestion: 'Hãy nhấn nút "+" để tạo giao dịch đầu tiên!',
          icon: Icons.receipt_long_outlined,
          actionText: 'Thêm giao dịch',
          actionIcon: Icons.add,
          onActionPressed: () {
            AppRoutes.navigateToTransaction(context);
          },
        );
      }
      switch (type) {
        case 0:
          return _buildGroupedListView(_groupTransactionsByDay(transactions));
        case 1:
          return _buildGroupedListView(_groupTransactionsByMonth(transactions));
        case 2:
          return _buildGroupedListView(_groupTransactionsByYear(transactions));
        default:
          return const SizedBox.shrink();
      }
    } else if (state is TransactionError) {
      return CommonWidgets.buildErrorState(
        context: context,
        message: state.message,
        onRetry: _refreshTransactions,
      );
    } else {
      return CommonWidgets.buildLoadingIndicator(context);
    }
  }
}
