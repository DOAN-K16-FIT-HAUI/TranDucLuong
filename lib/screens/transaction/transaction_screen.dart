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
import 'package:finance_app/utils/common_widget.dart'; // Import CommonWidgets đã sửa
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


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
  String _selectedCategory = '';
  String _selectedType = '';
  String _selectedWallet = '';
  String _selectedFromWallet = '';
  String _selectedToWallet = '';

  String? _dateError;
  String? _repaymentDateError;

  List<Wallet> _allWallets = [];
  Map<String, double> _walletBalances = {};

  bool _isSaving = false;
  bool _isLoadingWallets = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeDefaultValues();
        _loadWallets();
      }
    });
  }

  void _initializeDefaultValues() {
    final l10n = AppLocalizations.of(context)!;
    final categories = Constants.getAvailableCategories(l10n);
    final types = Constants.getTransactionTypes(l10n);
    if (mounted) {
      setState(() {
        _selectedCategory = categories.isNotEmpty ? categories.first : '';
        _selectedType = types.isNotEmpty ? types.first : '';
        _setDefaultWallets();
      });
    }
  }

  void _loadWallets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WalletBloc>().add(LoadWallets());
    } else {
      if (mounted) {
        setState(() { _isLoadingWallets = false; });
        _showLoginRequiredSnackbar(context);
      }
    }
  }

  void _showLoginRequiredSnackbar(BuildContext context) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loginToAddTransaction)),
    );
  }

  void _saveTransaction() {
    final l10n = AppLocalizations.of(context)!;
    // final theme = Theme.of(context);

    if (_isSaving || _isLoadingWallets) return;

    if (mounted) {
      setState(() {
        _dateError = Validators.validateDate(_selectedDate); // Truyền l10n nếu cần
        // !! So sánh type gốc !!
        if (_selectedType == 'borrow' || _selectedType == 'lend') {
          _repaymentDateError = Validators.validateRepaymentDate(_repaymentDate, _selectedDate); // Truyền l10n nếu cần
        } else { _repaymentDateError = null; }
      });
    }
    if (_dateError != null || _repaymentDateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.checkDateError)));
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.userNotLoggedInError)));
        return;
      }
      final userId = authState.user.id;

      // --- Kiểm tra logic ví ---
      // !! So sánh type gốc !!
      if (_selectedType == 'transfer') {
        if (_selectedFromWallet.isEmpty || _selectedToWallet.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectSourceAndDestinationWalletError)));
          return;
        }
        if (_allWallets.length > 1 && _selectedFromWallet == _selectedToWallet) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.sourceAndDestinationWalletCannotBeSameError)));
          return;
        }
      } else if (_selectedType != 'income') {
        if (_selectedWallet.isEmpty) {
          // String displayType = l10n.transactionTypeName(_selectedType);
          String displayType = _selectedType;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.selectWalletForTransactionError(displayType))));
          return;
        }
      }

      final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      // !! So sánh type gốc !!
      final balanceAfter = _selectedType == 'adjustment'
          ? (double.tryParse(_balanceAfterController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0)
          : null;

      // Kiểm tra số dư ví nguồn
      String sourceWalletName = '';
      // !! So sánh type gốc !!
      if (_selectedType == 'expense' || _selectedType == 'lend') { sourceWalletName = _selectedWallet; }
      else if (_selectedType == 'transfer') { sourceWalletName = _selectedFromWallet; }

      if (sourceWalletName.isNotEmpty) {
        final sourceBalance = _walletBalances[sourceWalletName] ?? 0.0;
        if (amount > sourceBalance) {
          final locale = Intl.getCurrentLocale();
          final formattedSourceBalance = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0).format(sourceBalance);
          final formattedAmount = NumberFormat.currency(locale: locale, symbol: '', decimalDigits: 0).format(amount);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.insufficientBalanceError(sourceWalletName, formattedSourceBalance, formattedAmount))));
          return;
        }
      }

      // --- Tạo TransactionModel ---
      final transaction = TransactionModel(
        id: '', userId: userId, description: _descriptionController.text.trim(),
        amount: amount, date: _selectedDate, type: _selectedType, // Lưu type gốc
        category: _selectedType == 'expense' ? _selectedCategory : '', // type gốc
        wallet: (_selectedType != 'transfer') ? _selectedWallet : null, // type gốc
        fromWallet: (_selectedType == 'transfer') ? _selectedFromWallet : null, // type gốc
        toWallet: (_selectedType == 'transfer') ? _selectedToWallet : null, // type gốc
        lender: (_selectedType == 'borrow') ? _lenderController.text.trim() : null, // type gốc
        borrower: (_selectedType == 'lend') ? _borrowerController.text.trim() : null, // type gốc
        repaymentDate: (_selectedType == 'borrow' || _selectedType == 'lend') ? _repaymentDate : null, // type gốc
        balanceAfter: balanceAfter,
      );

      if (mounted) setState(() { _isSaving = true; });
      context.read<TransactionBloc>().add(AddTransaction(transaction));

    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.checkInputError)));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    final l10n = AppLocalizations.of(context)!;
    final categories = Constants.getAvailableCategories(l10n);
    final types = Constants.getTransactionTypes(l10n);
    if (mounted) {
      setState(() {
        _descriptionController.clear(); _amountController.clear(); _balanceAfterController.clear();
        _lenderController.clear(); _borrowerController.clear();
        _selectedDate = DateTime.now(); _repaymentDate = null;
        _selectedCategory = categories.isNotEmpty ? categories.first : '';
        _selectedType = types.isNotEmpty ? types.first : '';
        _dateError = null; _repaymentDateError = null;
        _setDefaultWallets();
      });
    }
  }

  void _setDefaultWallets() {
    if (!mounted) return;
    setState(() {
      if (_allWallets.isNotEmpty) {
        _selectedWallet = _allWallets.any((w) => w.name == _selectedWallet) ? _selectedWallet : _allWallets.first.name;
        _selectedFromWallet = _allWallets.any((w) => w.name == _selectedFromWallet) ? _selectedFromWallet : _allWallets.first.name;
        final availableToWallets = _allWallets.where((w) => w.name != _selectedFromWallet).toList();
        _selectedToWallet = _allWallets.any((w) => w.name == _selectedToWallet && w.name != _selectedFromWallet)
            ? _selectedToWallet : (availableToWallets.isNotEmpty ? availableToWallets.first.name : _allWallets.first.name);
      } else { _selectedWallet = ''; _selectedFromWallet = ''; _selectedToWallet = ''; }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose(); _amountController.dispose(); _balanceAfterController.dispose();
    _lenderController.dispose(); _borrowerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is! TransactionLoading) { if (mounted) setState(() { _isSaving = false; }); }
            if (state is TransactionSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppTheme.incomeColor));
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) { context.read<WalletBloc>().add(LoadWallets()); }
                _resetForm();
                // Navigator.maybePop(context);
              }
            } else if (state is TransactionError) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error));
              }
            }
          },
        ),
        BlocListener<WalletBloc, WalletState>(
          listener: (context, state) {
            if (mounted) {
              setState(() {
                _isLoadingWallets = false;
                _allWallets = [...state.wallets, ...state.savingsWallets, ...state.investmentWallets].where((w) => w.id.isNotEmpty).toList();
                _allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
                _walletBalances = Map.fromEntries(_allWallets.map((w) => MapEntry(w.name, w.balance.toDouble())));
                if (_selectedWallet.isEmpty || !_allWallets.any((w) => w.name == _selectedWallet)) {
                  _setDefaultWallets();
                }
              });
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: BlocBuilder<WalletBloc, WalletState>(
            builder: (context, walletState) {
              final walletNames = _allWallets.map((wallet) => wallet.name).toList();

              // --- Dropdown Items ---
              // !! Dùng giá trị hiển thị từ _types !!
              final List<DropdownMenuItem<String>> transactionTypeItems = Constants.getTransactionTypes(l10n)
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList();
              final List<DropdownMenuItem<String>> categoryItems = Constants.getAvailableCategories(l10n)
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat))) // Ép kiểu nếu cần
                  .toList();
              final List<DropdownMenuItem<String>> walletDropdownItems = walletNames
                  .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                  .toList();
              final List<DropdownMenuItem<String>> toWalletDropdownItems = walletNames
                  .where((name) => name != _selectedFromWallet)
                  .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                  .toList();

              // --- UI Logic ---
              Widget bodyContent;
              if (_isLoadingWallets && _allWallets.isEmpty) {
                bodyContent = CommonWidgets.buildLoadingIndicator(context: context); // Pass context
              } else if (_allWallets.isEmpty && context.read<AuthBloc>().state is AuthAuthenticated) {
                bodyContent = CommonWidgets.buildEmptyState(
                  context: context, // Pass context
                  message: l10n.noWalletsAvailable, // l10n
                  suggestion: l10n.pleaseCreateWalletFirst, // l10n
                  icon: Icons.account_balance_wallet_outlined,
                  actionText: l10n.goToWalletManagement, // l10n
                  actionIcon: Icons.arrow_forward,
                  onActionPressed: () => AppRoutes.navigateToWallet(context),
                );
              } else if (context.read<AuthBloc>().state is! AuthAuthenticated) {
                bodyContent = Center(child: Text(l10n.pleaseLoginToManageTransactions)); // l10n
              } else {
                // --- FORM UI ---
                bodyContent = Column(
                  children: [
                    // --- AppBar ---
                    CommonWidgets.buildAppBar(
                      context: context, // Pass context
                      titleWidget: DropdownButtonHideUnderline(
                        child: DropdownButton<String>( // Sửa kiểu thành <String>
                          value: _selectedType,
                          items: transactionTypeItems,
                          onChanged: (String? newValue) {
                            if (newValue != null && mounted) {
                              setState(() {
                                _selectedType = newValue;
                                _formKey.currentState?.reset();
                                _balanceAfterController.clear(); _lenderController.clear(); _borrowerController.clear();
                                _repaymentDate = null; _repaymentDateError = null;
                                _setDefaultWallets();
                                WidgetsBinding.instance.addPostFrameCallback((_) { _formKey.currentState?.validate(); });
                              });
                            }
                          },
                          style: GoogleFonts.poppins(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                          iconEnabledColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                          dropdownColor: theme.colorScheme.primaryContainer,
                          selectedItemBuilder: (context) {
                            return transactionTypeItems.map((item) => Align(alignment: Alignment.center, child: Text(item.value ?? '', style: GoogleFonts.poppins(color: theme.colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w600)))).toList();
                          },
                          underline: Container(),
                          isExpanded: false,
                        ),
                      ),
                      showBackButton: true,
                      backIcon: Icons.arrow_back,
                      onBackPressed: () => AppRoutes.navigateToDashboard(context),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: _isSaving
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.colorScheme.onPrimary, strokeWidth: 2.5))
                                : Icon(Icons.check, color: theme.colorScheme.onPrimary), // theme
                            onPressed: _isSaving ? null : _saveTransaction,
                            tooltip: l10n.saveTransactionTooltip, // l10n
                          ),
                        ),
                      ],
                    ),
                    // --- Form Body ---
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Các trường nhập liệu ---
                              CommonWidgets.buildTextField( // Dùng CommonWidgets
                                controller: _descriptionController, label: l10n.descriptionLabel, hint: l10n.descriptionHint, // l10n
                                validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.descriptionLabel), isRequired: true, // l10n
                              ),
                              const SizedBox(height: 16),
                              CommonWidgets.buildDatePickerField( // Dùng CommonWidgets
                                context: context, date: _selectedDate, label: l10n.transactionDateLabel, // l10n
                                onTap: (picked) { if (picked != null && mounted) setState(() => _selectedDate = picked); },
                                errorText: _dateError, isRequired: true,
                              ),
                              const SizedBox(height: 16),

                              // --- Conditional Fields ---
                              // !! So sánh type gốc !!
                              if (_selectedType == 'Chi tiêu') ...[
                                CommonWidgets.buildDropdownField<String>( // Dùng CommonWidgets
                                  label: l10n.expenseCategoryLabel, value: _selectedCategory, items: categoryItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedCategory = v); },
                                  validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.expenseCategoryLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDropdownField<String>( // Dùng CommonWidgets
                                  label: l10n.fromWalletLabel, value: _selectedWallet, items: walletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_selectedType == 'Thu nhập') ...[
                                CommonWidgets.buildDropdownField<String>( // Dùng CommonWidgets
                                  label: l10n.toWalletLabel, value: _selectedWallet, items: walletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_selectedType == 'Chuyển khoản') ...[
                                CommonWidgets.buildDropdownField<String>( // Dùng CommonWidgets
                                  label: l10n.fromWalletSourceLabel, value: _selectedFromWallet, items: walletDropdownItems, // l10n
                                  onChanged: (newValue) {
                                    if (newValue != null && mounted) {
                                      setState(() {
                                        _selectedFromWallet = newValue;
                                        if (_allWallets.length > 1 && _selectedToWallet == newValue) {
                                          final availableTo = _allWallets.where((w) => w.name != newValue).toList();
                                          _selectedToWallet = availableTo.isNotEmpty ? availableTo.first.name : '';
                                        }
                                      });
                                    }
                                  },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletSourceLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDropdownField<String>( // Dùng CommonWidgets
                                  label: l10n.toWalletDestinationLabel, value: _selectedToWallet, items: toWalletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedToWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.toWalletDestinationLabel, checkAgainst: _selectedFromWallet), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_selectedType == 'Đi vay') ...[
                                CommonWidgets.buildTextField(controller: _lenderController, label: l10n.lenderLabel, hint: l10n.lenderHint, // l10n
                                  validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.lenderLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDropdownField<String>(label: l10n.toWalletLabel, value: _selectedWallet, items: walletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDatePickerField(context: context, date: _repaymentDate, label: l10n.repaymentDateOptionalLabel, // l10n
                                  onTap: (picked) { if (mounted) setState(() => _repaymentDate = picked); },
                                  errorText: _repaymentDateError, isRequired: false,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_selectedType == 'Cho vay') ...[
                                CommonWidgets.buildTextField(controller: _borrowerController, label: l10n.borrowerLabel, hint: l10n.borrowerHint, // l10n
                                  validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.borrowerLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDropdownField<String>(label: l10n.fromWalletLabel, value: _selectedWallet, items: walletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildDatePickerField(context: context, date: _repaymentDate, label: l10n.repaymentDateOptionalLabel, // l10n
                                  onTap: (picked) { if (mounted) setState(() => _repaymentDate = picked); },
                                  errorText: _repaymentDateError, isRequired: false,
                                ),
                                const SizedBox(height: 16),
                              ],
                              if (_selectedType == 'Điều chỉnh số dư') ...[
                                CommonWidgets.buildDropdownField<String>(label: l10n.walletToAdjustLabel, value: _selectedWallet, items: walletDropdownItems, // l10n
                                  onChanged: (v) { if (v != null && mounted) setState(() => _selectedWallet = v); },
                                  validator: (v) => Validators.validateWallet(v, fieldName: l10n.walletToAdjustLabel), isRequired: true, // l10n
                                ),
                                const SizedBox(height: 16),
                                CommonWidgets.buildLabel(context: context, text: l10n.actualBalanceAfterAdjustmentLabel), // l10n
                                const SizedBox(height: 8),
                                CommonWidgets.buildBalanceInputField(
                                  _balanceAfterController,
                                  validator: (v) => Validators.validateBalanceAfterAdjustment(v,), // Pass l10n if needed
                                ),
                                const SizedBox(height: 16),
                              ],

                              // --- Amount Field (chung) ---
                              if (_selectedType != 'adjustment') ...[ // Key gốc 'adjustment'
                                CommonWidgets.buildBalanceInputField( // Gọi hàm từ CommonWidgets
                                  _amountController,
                                  validator: (value) { // Validator là một lambda function (String?) -> String?
                                    // Bên trong lambda này, ta CÓ THỂ truy cập các biến của TransactionScreenState
                                    final currentBalance = _walletBalances[_selectedType == 'transfer' ? _selectedFromWallet : _selectedWallet] ?? 0.0;
                                    // Gọi hàm validator thực tế với đầy đủ tham số từ state
                                    return Validators.validateTransactionAmount(
                                      value: value,
                                      transactionType: _selectedType, // Truyền type gốc (key)
                                      walletBalance: currentBalance,
                                      l10n: l10n, // Truyền l10n từ context của build
                                    );
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return bodyContent;
            }
        ),
      ),
    );
  }
}