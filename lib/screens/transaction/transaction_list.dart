import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/utils/common_widget/app_bar_tab_bar.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
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
  String _selectedCategoryKey = 'food'; // Lưu categoryKey cố định
  String _selectedType = ''; // Chuỗi đã dịch, dùng cho UI
  String _selectedWallet = '';
  String _selectedFromWallet = '';
  String _selectedToWallet = '';

  String? _dateError;
  String? _repaymentDateError;

  List<Wallet> _allWallets = [];
  Map<String, double> _walletBalances = {};

  bool _isSaving = false;
  bool _isLoadingWallets = true;

  // Map ánh xạ giữa categoryKey và giá trị dịch
  Map<String, String> _categoryMap = {};

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
    final types = Constants.getTransactionTypes(l10n);
    _updateCategoryMap(l10n);
    if (mounted) {
      setState(() {
        _selectedCategoryKey = _categoryMap.keys.isNotEmpty ? _categoryMap.keys.first : 'food';
        _selectedType = types.isNotEmpty ? types.first : '';
        _setDefaultWallets();
      });
    }
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
  }

  void _loadWallets() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<WalletBloc>().add(LoadWallets());
    } else {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
        });
        _showLoginRequiredSnackbar(context);
      }
    }
  }

  void _showLoginRequiredSnackbar(BuildContext context) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.loginToAddTransaction)));
  }

  String _mapLocalizedTypeToKey(String localizedType, AppLocalizations l10n) {
    if (localizedType == l10n.transactionTypeExpense) return "expense";
    if (localizedType == l10n.transactionTypeIncome) return "income";
    if (localizedType == l10n.transactionTypeTransfer) return "transfer";
    if (localizedType == l10n.transactionTypeBorrow) return "borrow";
    if (localizedType == l10n.transactionTypeLend) return "lend";
    if (localizedType == l10n.transactionTypeAdjustment) return "adjustment";
    return localizedType; // Fallback
  }

  String _mapCategoryKeyToLocalized(String key, AppLocalizations l10n) {
    return _categoryMap[key] ?? key;
  }

  void _saveTransaction() {
    final l10n = AppLocalizations.of(context)!;

    if (_isSaving || _isLoadingWallets) return;

    if (mounted) {
      setState(() {
        _dateError = Validators.validateDate(_selectedDate);
        if (_selectedType == l10n.transactionTypeBorrow ||
            _selectedType == l10n.transactionTypeLend) {
          _repaymentDateError = Validators.validateRepaymentDate(
            _repaymentDate,
            _selectedDate,
          );
        } else {
          _repaymentDateError = null;
        }
      });
    }
    if (_dateError != null || _repaymentDateError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.checkDateError)));
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.userNotLoggedInError)));
        return;
      }
      final userId = authState.user.id;

      if (_selectedType == l10n.transactionTypeTransfer) {
        if (_selectedFromWallet.isEmpty || _selectedToWallet.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.selectSourceAndDestinationWalletError)),
          );
          return;
        }
        if (_allWallets.length > 1 && _selectedFromWallet == _selectedToWallet) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sourceAndDestinationWalletCannotBeSameError),
            ),
          );
          return;
        }
      } else if (_selectedType != l10n.transactionTypeIncome) {
        if (_selectedWallet.isEmpty) {
          String displayType = _selectedType;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.selectWalletForTransactionError(displayType)),
            ),
          );
          return;
        }
      }

      final amount = double.tryParse(
        _amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ??
          0.0;
      final balanceAfter = _selectedType == l10n.transactionTypeAdjustment
          ? (double.tryParse(
        _balanceAfterController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
      ) ??
          0.0)
          : null;

      String sourceWalletName = '';
      if (_selectedType == l10n.transactionTypeExpense ||
          _selectedType == l10n.transactionTypeLend) {
        sourceWalletName = _selectedWallet;
      } else if (_selectedType == l10n.transactionTypeTransfer) {
        sourceWalletName = _selectedFromWallet;
      }

      if (sourceWalletName.isNotEmpty) {
        final sourceBalance = _walletBalances[sourceWalletName] ?? 0.0;
        if (amount > sourceBalance) {
          final locale = Intl.getCurrentLocale();
          final formattedSourceBalance = NumberFormat.currency(
            locale: locale,
            symbol: '',
            decimalDigits: 0,
          ).format(sourceBalance);
          final formattedAmount = NumberFormat.currency(
            locale: locale,
            symbol: '',
            decimalDigits: 0,
          ).format(amount);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.insufficientBalanceError(
                  sourceWalletName,
                  formattedSourceBalance,
                  formattedAmount,
                ),
              ),
            ),
          );
          return;
        }
      }

      final transaction = TransactionModel(
        id: '',
        userId: userId,
        description: _descriptionController.text.trim(),
        amount: amount,
        date: _selectedDate,
        typeKey: _mapLocalizedTypeToKey(_selectedType, l10n),
        categoryKey: _selectedType == l10n.transactionTypeExpense ? _selectedCategoryKey : '',
        wallet: (_selectedType != l10n.transactionTypeTransfer) ? _selectedWallet : null,
        fromWallet: (_selectedType == l10n.transactionTypeTransfer) ? _selectedFromWallet : null,
        toWallet: (_selectedType == l10n.transactionTypeTransfer) ? _selectedToWallet : null,
        lender: (_selectedType == l10n.transactionTypeBorrow) ? _lenderController.text.trim() : null,
        borrower: (_selectedType == l10n.transactionTypeLend) ? _borrowerController.text.trim() : null,
        repaymentDate: (_selectedType == l10n.transactionTypeBorrow || _selectedType == l10n.transactionTypeLend)
            ? _repaymentDate
            : null,
        balanceAfter: balanceAfter,
      );

      if (mounted) {
        setState(() {
          _isSaving = true;
        });
      }
      context.read<TransactionBloc>().add(AddTransaction(transaction));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.checkInputError)));
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    final l10n = AppLocalizations.of(context)!;
    _updateCategoryMap(l10n);
    final types = Constants.getTransactionTypes(l10n);
    if (mounted) {
      setState(() {
        _descriptionController.clear();
        _amountController.clear();
        _balanceAfterController.clear();
        _lenderController.clear();
        _borrowerController.clear();
        _selectedDate = DateTime.now();
        _repaymentDate = null;
        _selectedCategoryKey = _categoryMap.keys.isNotEmpty ? _categoryMap.keys.first : 'food';
        _selectedType = types.isNotEmpty ? types.first : '';
        _dateError = null;
        _repaymentDateError = null;
        _setDefaultWallets();
      });
    }
  }

  void _setDefaultWallets() {
    if (!mounted) return;
    setState(() {
      if (_allWallets.isNotEmpty) {
        _selectedWallet = _allWallets.any((w) => w.name == _selectedWallet)
            ? _selectedWallet
            : _allWallets.first.name;
        _selectedFromWallet = _allWallets.any((w) => w.name == _selectedFromWallet)
            ? _selectedFromWallet
            : _allWallets.first.name;
        final availableToWallets = _allWallets.where((w) => w.name != _selectedFromWallet).toList();
        _selectedToWallet = _allWallets.any((w) => w.name == _selectedToWallet && w.name != _selectedFromWallet)
            ? _selectedToWallet
            : (availableToWallets.isNotEmpty ? availableToWallets.first.name : _allWallets.first.name);
      } else {
        _selectedWallet = '';
        _selectedFromWallet = '';
        _selectedToWallet = '';
      }
    });
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    _updateCategoryMap(l10n); // Cập nhật map khi ngôn ngữ thay đổi

    return MultiBlocListener(
      listeners: [
        BlocListener<TransactionBloc, TransactionState>(
          listener: (context, state) {
            if (state is! TransactionLoading) {
              if (mounted) {
                setState(() {
                  _isSaving = false;
                });
              }
            }
            if (state is TransactionSuccess) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message(context))));
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  context.read<WalletBloc>().add(LoadWallets());
                }
                _resetForm();
              }
            } else if (state is TransactionError) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message(context))));
              }
            }
          },
        ),
        BlocListener<WalletBloc, WalletState>(
          listener: (context, state) {
            if (mounted) {
              setState(() {
                _isLoadingWallets = false;
                _allWallets = [
                  ...state.wallets,
                  ...state.savingsWallets,
                  ...state.investmentWallets,
                ].where((w) => w.id.isNotEmpty).toList();
                _allWallets.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
                _walletBalances = Map.fromEntries(
                  _allWallets.map((w) => MapEntry(w.name, w.balance.toDouble())),
                );
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

            final List<DropdownMenuItem<String>> transactionTypeItems = Constants.getTransactionTypes(l10n)
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList();
            final List<DropdownMenuItem<String>> categoryItems = _categoryMap.entries
                .map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value)))
                .toList();
            final List<DropdownMenuItem<String>> walletDropdownItems = walletNames
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList();
            final List<DropdownMenuItem<String>> toWalletDropdownItems = walletNames
                .where((name) => name != _selectedFromWallet)
                .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                .toList();

            Widget bodyContent;
            if (_isLoadingWallets && _allWallets.isEmpty) {
              bodyContent = UtilityWidgets.buildLoadingIndicator(context: context);
            } else if (_allWallets.isEmpty && context.read<AuthBloc>().state is AuthAuthenticated) {
              bodyContent = UtilityWidgets.buildEmptyState(
                context: context,
                message: l10n.noWalletsAvailable,
                suggestion: l10n.pleaseCreateWalletFirst,
                icon: Icons.account_balance_wallet_outlined,
                actionText: l10n.goToWalletManagement,
                actionIcon: Icons.arrow_forward,
                onActionPressed: () => AppRoutes.navigateToWallet(context),
              );
            } else if (context.read<AuthBloc>().state is! AuthAuthenticated) {
              bodyContent = UtilityWidgets.buildEmptyState(
                context: context,
                message: l10n.pleaseLoginToManageTransactions,
                suggestion: null,
                onActionPressed: null,
              );
            } else {
              bodyContent = Column(
                children: [
                  AppBarTabBar.buildAppBar(
                    context: context,
                    titleWidget: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedType,
                        items: transactionTypeItems,
                        onChanged: (String? newValue) {
                          if (newValue != null && mounted) {
                            setState(() {
                              _selectedType = newValue;
                              _formKey.currentState?.reset();
                              _balanceAfterController.clear();
                              _lenderController.clear();
                              _borrowerController.clear();
                              _repaymentDate = null;
                              _repaymentDateError = null;
                              _setDefaultWallets();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _formKey.currentState?.validate();
                              });
                            });
                          }
                        },
                        style: GoogleFonts.poppins(
                          color: theme.colorScheme.onPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        iconEnabledColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                        dropdownColor: theme.colorScheme.primaryContainer,
                        selectedItemBuilder: (context) {
                          return transactionTypeItems
                              .map(
                                (item) => Align(
                              alignment: Alignment.center,
                              child: Text(
                                item.value ?? '',
                                style: GoogleFonts.poppins(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                              .toList();
                        },
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
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: theme.colorScheme.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Icon(
                            Icons.check,
                            color: theme.colorScheme.onPrimary,
                          ),
                          onPressed: _isSaving ? null : _saveTransaction,
                          tooltip: l10n.saveTransactionTooltip,
                        ),
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
                            InputFields.buildTextField(
                              controller: _descriptionController,
                              label: l10n.descriptionLabel,
                              hint: l10n.descriptionHint,
                              validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.descriptionLabel),
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            InputFields.buildDatePickerField(
                              context: context,
                              date: _selectedDate,
                              label: l10n.transactionDateLabel,
                              onTap: (picked) {
                                if (picked != null && mounted) {
                                  setState(() => _selectedDate = picked);
                                }
                              },
                              errorText: _dateError,
                              isRequired: true,
                            ),
                            const SizedBox(height: 16),
                            if (_selectedType == l10n.transactionTypeExpense) ...[
                              InputFields.buildDropdownField<String>(
                                label: l10n.expenseCategoryLabel,
                                value: _selectedCategoryKey,
                                items: categoryItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedCategoryKey = v);
                                  }
                                },
                                validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.expenseCategoryLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDropdownField<String>(
                                label: l10n.fromWalletLabel,
                                value: _selectedWallet,
                                items: walletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType == l10n.transactionTypeIncome) ...[
                              InputFields.buildDropdownField<String>(
                                label: l10n.toWalletLabel,
                                value: _selectedWallet,
                                items: walletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType == l10n.transactionTypeTransfer) ...[
                              InputFields.buildDropdownField<String>(
                                label: l10n.fromWalletSourceLabel,
                                value: _selectedFromWallet,
                                items: walletDropdownItems,
                                onChanged: (newValue) {
                                  if (newValue != null && mounted) {
                                    setState(() {
                                      _selectedFromWallet = newValue;
                                      if (_allWallets.length > 1 && _selectedToWallet == newValue) {
                                        final availableTo =
                                        _allWallets.where((w) => w.name != newValue).toList();
                                        _selectedToWallet = availableTo.isNotEmpty ? availableTo.first.name : '';
                                      }
                                    });
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletSourceLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDropdownField<String>(
                                label: l10n.toWalletDestinationLabel,
                                value: _selectedToWallet,
                                items: toWalletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedToWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(
                                    v, fieldName: l10n.toWalletDestinationLabel, checkAgainst: _selectedFromWallet),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType == l10n.transactionTypeBorrow) ...[
                              InputFields.buildTextField(
                                controller: _lenderController,
                                label: l10n.lenderLabel,
                                hint: l10n.lenderHint,
                                validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.lenderLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDropdownField<String>(
                                label: l10n.toWalletLabel,
                                value: _selectedWallet,
                                items: walletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDatePickerField(
                                context: context,
                                date: _repaymentDate,
                                label: l10n.repaymentDateOptionalLabel,
                                onTap: (picked) {
                                  if (mounted) {
                                    setState(() => _repaymentDate = picked);
                                  }
                                },
                                errorText: _repaymentDateError,
                                isRequired: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType == l10n.transactionTypeLend) ...[
                              InputFields.buildTextField(
                                controller: _borrowerController,
                                label: l10n.borrowerLabel,
                                hint: l10n.borrowerHint,
                                validator: (v) => Validators.validateNotEmpty(v, fieldName: l10n.borrowerLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDropdownField<String>(
                                label: l10n.fromWalletLabel,
                                value: _selectedWallet,
                                items: walletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              InputFields.buildDatePickerField(
                                context: context,
                                date: _repaymentDate,
                                label: l10n.repaymentDateOptionalLabel,
                                onTap: (picked) {
                                  if (mounted) {
                                    setState(() => _repaymentDate = picked);
                                  }
                                },
                                errorText: _repaymentDateError,
                                isRequired: false,
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType == l10n.transactionTypeAdjustment) ...[
                              InputFields.buildDropdownField<String>(
                                label: l10n.walletToAdjustLabel,
                                value: _selectedWallet,
                                items: walletDropdownItems,
                                onChanged: (v) {
                                  if (v != null && mounted) {
                                    setState(() => _selectedWallet = v);
                                  }
                                },
                                validator: (v) => Validators.validateWallet(v, fieldName: l10n.walletToAdjustLabel),
                                isRequired: true,
                              ),
                              const SizedBox(height: 16),
                              UtilityWidgets.buildLabel(
                                context: context,
                                text: l10n.actualBalanceAfterAdjustmentLabel,
                              ),
                              const SizedBox(height: 8),
                              InputFields.buildBalanceInputField(
                                _balanceAfterController,
                                validator: (v) => Validators.validateBalanceAfterAdjustment(v),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_selectedType != l10n.transactionTypeAdjustment) ...[
                              InputFields.buildBalanceInputField(
                                _amountController,
                                validator: (value) {
                                  final currentBalance = _walletBalances[_selectedType == l10n.transactionTypeTransfer
                                      ? _selectedFromWallet
                                      : _selectedWallet] ??
                                      0.0;
                                  return Validators.validateTransactionAmount(
                                    value: value,
                                    transactionType: _selectedType,
                                    walletBalance: currentBalance,
                                    l10n: l10n,
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
          },
        ),
      ),
    );
  }
}