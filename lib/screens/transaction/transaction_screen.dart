import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
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
import 'package:finance_app/utils/common_widget.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  TransactionScreenState createState() => TransactionScreenState();
}

class TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _balanceAfterController = TextEditingController();
  final TextEditingController _lenderController = TextEditingController();
  final TextEditingController _borrowerController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime? _repaymentDate;
  String _selectedCategory = 'Ẩn uống';
  String _selectedType = 'Chi tiêu';
  String _selectedWallet = '';
  String _selectedFromWallet = '';
  String _selectedToWallet = '';
  String? _dateError;
  String? _repaymentDateError;
  Map<String, double> _walletBalances = {};
  List<String> _wallets = [];

  final List<String> _categories = [
    'Ẩn uống',
    'Sinh hoạt',
    'Đi lại',
    'Sức khỏe',
  ];

  final List<String> _types = [
    'Thu nhập',
    'Chi tiêu',
    'Chuyển khoản',
    'Đi vay',
    'Cho vay',
    'Điều chỉnh số dư',
  ];

  @override
  void initState() {
    super.initState();
    final userId =
        context.read<AuthBloc>().state is AuthAuthenticated
            ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
            : '';
    if (userId.isNotEmpty) {
      context.read<TransactionBloc>().add(LoadTransactions(userId));
      context.read<WalletBloc>().add(LoadWallets());
    }
  }

  Future<void> _selectDate(
    BuildContext context, {
    bool isRepaymentDate = false,
  }) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isRepaymentDate ? (_repaymentDate ?? DateTime.now()) : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.lightTheme.colorScheme.primary,
              onPrimary: AppTheme.lightTheme.colorScheme.surface,
              onSurface: AppTheme.lightTheme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isRepaymentDate) {
          _repaymentDate = picked;
          _repaymentDateError = Validators.validateDate(_repaymentDate);
        } else {
          _selectedDate = picked;
          _dateError = Validators.validateDate(_selectedDate);
        }
      });
    }
  }

  void _saveTransaction() {
    setState(() {
      _dateError = Validators.validateDate(_selectedDate);
      if (_selectedType == 'Đi vay' || _selectedType == 'Cho vay') {
        _repaymentDateError = Validators.validateDate(_repaymentDate);
      }
    });

    if (_formKey.currentState!.validate() &&
        _dateError == null &&
        (_repaymentDateError == null ||
            (_selectedType != 'Đi vay' && _selectedType != 'Cho vay'))) {
      final userId =
          context.read<AuthBloc>().state is AuthAuthenticated
              ? (context.read<AuthBloc>().state as AuthAuthenticated).user.id
              : '';
      if (userId.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not authenticated')));
        return;
      }

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        description: _descriptionController.text,
        amount: double.parse(
          _amountController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ),
        date: _selectedDate,
        type: _selectedType,
        category: _selectedType == 'Chi tiêu' ? _selectedCategory : '',
        wallet: _selectedType == 'Chuyển khoản' ? '' : _selectedWallet,
        fromWallet:
            _selectedType == 'Chuyển khoản' ? _selectedFromWallet : null,
        toWallet: _selectedType == 'Chuyển khoản' ? _selectedToWallet : null,
        lender: _selectedType == 'Đi vay' ? _lenderController.text : null,
        borrower: _selectedType == 'Cho vay' ? _borrowerController.text : null,
        repaymentDate:
            _selectedType == 'Đi vay' || _selectedType == 'Cho vay'
                ? _repaymentDate
                : null,
        balanceAfter:
            _selectedType == 'Điều chỉnh số dư'
                ? double.parse(
                  _balanceAfterController.text.replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  ),
                )
                : null,
      );

      context.read<TransactionBloc>().add(AddTransaction(transaction));

      // Reset các trường sau khi lưu
      setState(() {
        _descriptionController.clear();
        _amountController.clear();
        _balanceAfterController.clear();
        _lenderController.clear();
        _borrowerController.clear();
        _selectedDate = DateTime.now();
        _repaymentDate = null;
        _selectedCategory = 'Ẩn uống'; // Reset về giá trị mặc định
        _selectedType = 'Chi tiêu'; // Reset về giá trị mặc định
        _selectedWallet =
            _wallets.isNotEmpty
                ? _wallets[0]
                : ''; // Reset về ví đầu tiên nếu có
        _selectedFromWallet =
            _wallets.isNotEmpty
                ? _wallets[0]
                : ''; // Reset về ví đầu tiên nếu có
        _selectedToWallet =
            _wallets.length > 1
                ? _wallets[1]
                : _wallets[0]; // Reset về ví thứ hai nếu có
        _dateError = null;
        _repaymentDateError = null;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _balanceAfterController.dispose();
    _lenderController.dispose();
    _borrowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransactionBloc, TransactionState>(
      listener: (context, state) {
        if (state is TransactionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is TransactionError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, walletState) {
          // Cập nhật danh sách ví và số dư từ WalletBloc
          _wallets = walletState.wallets.map((wallet) => wallet.name).toList();
          _walletBalances = Map.fromEntries(
            walletState.wallets.map(
              (wallet) => MapEntry(wallet.name, wallet.balance.toDouble()),
            ),
          );

          // Log để kiểm tra
          debugPrint("Wallets in TransactionScreen: $_wallets");
          debugPrint("Wallet balances: $_walletBalances");

          // Nếu danh sách ví rỗng, hiển thị thông báo
          if (_wallets.isEmpty) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('No wallets available. Please add a wallet.'),
                    ElevatedButton(
                      onPressed: () {
                        context.read<WalletBloc>().add(
                          AddWallet(
                            Wallet(
                              id: '',
                              name: 'Default Wallet',
                              balance: 0,
                              icon: Icons.account_balance_wallet_outlined,
                              type: 0,
                            ),
                          ),
                        );
                      },
                      child: Text('Add Default Wallet'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Gán giá trị mặc định cho các ví nếu chưa được chọn
          if (_selectedWallet.isEmpty) {
            _selectedWallet = _wallets[0];
            _selectedFromWallet = _wallets[0];
            _selectedToWallet = _wallets.length > 1 ? _wallets[1] : _wallets[0];
          }

          return Scaffold(
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            body: Column(
              children: [
                CommonWidgets.buildAppBar(
                  context: context,
                  showDropdown: true,
                  dropdownItems: _types,
                  dropdownValue: _selectedType,
                  onDropdownChanged: (String? newValue) {
                    setState(() {
                      _selectedType = newValue!;
                    });
                  },
                  backIcon: Icons.arrow_back,
                  onBackPressed: () {
                    AppRoutes.navigateToDashboard(context);
                  },
                  actions: [
                    IconButton(
                      icon: Icon(
                        Icons.check,
                        color: AppTheme.lightTheme.colorScheme.surface,
                      ),
                      onPressed: _saveTransaction,
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CommonWidgets.buildTextField(
                            controller: _descriptionController,
                            label: 'Diễn tả hoạt động',
                            hint: 'Nhập mô tả giao dịch',
                            validator: Validators.validateDescription,
                          ),
                          const SizedBox(height: 16),
                          CommonWidgets.buildDatePickerField(
                            context: context,
                            date: _selectedDate,
                            label: 'Ngày giao dịch',
                            onTap: () => _selectDate(context),
                            errorText: _dateError,
                          ),
                          const SizedBox(height: 16),
                          if (_selectedType == 'Đi vay' ||
                              _selectedType == 'Cho vay') ...[
                            CommonWidgets.buildDatePickerField(
                              context: context,
                              date: _repaymentDate ?? DateTime.now(),
                              label: 'Ngày hẹn trả',
                              onTap:
                                  () => _selectDate(
                                    context,
                                    isRepaymentDate: true,
                                  ),
                              errorText: _repaymentDateError,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType == 'Chi tiêu') ...[
                            CommonWidgets.buildDropdownField(
                              label: 'Chọn danh mục',
                              value: _selectedCategory,
                              items: _categories,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue!;
                                });
                              },
                              validator: Validators.validateCategory,
                            ),
                            const SizedBox(height: 16),
                            CommonWidgets.buildCategoryChips(
                              categories: _categories,
                              selectedCategory: _selectedCategory,
                              onCategorySelected: (category) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType == 'Chuyển khoản') ...[
                            CommonWidgets.buildDropdownField(
                              label: 'Điện khoản',
                              value: _selectedFromWallet,
                              items: _wallets,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFromWallet = newValue!;
                                });
                              },
                              validator: Validators.validateWallet,
                            ),
                            const SizedBox(height: 16),
                            CommonWidgets.buildDropdownField(
                              label: 'Tài khoản đích',
                              value: _selectedToWallet,
                              items: _wallets,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedToWallet = newValue!;
                                });
                              },
                              validator: Validators.validateWallet,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType == 'Đi vay') ...[
                            CommonWidgets.buildTextField(
                              controller: _lenderController,
                              label: 'Người cho vay',
                              hint: 'Nhập tên người cho vay',
                              validator: Validators.validateNotEmpty,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType == 'Cho vay') ...[
                            CommonWidgets.buildTextField(
                              controller: _borrowerController,
                              label: 'Người vay',
                              hint: 'Nhập tên người vay',
                              validator: Validators.validateNotEmpty,
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (_selectedType != 'Chuyển khoản') ...[
                            CommonWidgets.buildDropdownField(
                              label: 'Ví',
                              value: _selectedWallet,
                              items: _wallets,
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedWallet = newValue!;
                                });
                              },
                              validator: Validators.validateWallet,
                            ),
                            const SizedBox(height: 16),
                          ],
                          CommonWidgets.buildLabel(text: 'Nhập số tiền'),
                          const SizedBox(height: 8),
                          CommonWidgets.buildBalanceInputField(
                            _amountController,
                            validator:
                                (value) => Validators.validateTransactionAmount(
                                  value: value,
                                  transactionType: _selectedType,
                                  walletBalance:
                                      _selectedType == 'Chuyển khoản'
                                          ? _walletBalances[_selectedFromWallet] ??
                                              0
                                          : _walletBalances[_selectedWallet] ??
                                              0,
                                ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedType == 'Điều chỉnh số dư') ...[
                            CommonWidgets.buildLabel(text: 'Số dư dự kiến'),
                            const SizedBox(height: 8),
                            CommonWidgets.buildBalanceInputField(
                              _balanceAfterController,
                              validator:
                                  (value) => Validators.validateBalance(
                                    value,
                                    currentBalance:
                                        _walletBalances[_selectedWallet] ?? 0,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
