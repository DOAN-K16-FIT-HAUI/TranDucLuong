import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/common_widget/dialogs.dart';
import 'package:finance_app/utils/common_widget/input_fields.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:finance_app/utils/constants.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// A reusable transaction form component for creating and editing transactions
class TransactionForm {
  /// Shows a dialog for editing a transaction
  static void showEditTransactionDialog({
    required BuildContext context,
    required TransactionModel transaction,
    required Function(TransactionModel) onSave,
    required Map<String, String> categoryMap,
    required Map<String, String> transactionTypeMap,
    required List<String> walletNames,
    required Map<String, double> walletBalances,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final formKey = GlobalKey<FormState>();

    // Controllers for form fields
    final descriptionController = TextEditingController(
      text: transaction.description,
    );
    final amountController = TextEditingController(
      text:
          Formatter.currencyInputFormatter
              .formatEditUpdate(
                const TextEditingValue(text: ''),
                TextEditingValue(text: transaction.amount.toInt().toString()),
              )
              .text,
    );
    final balanceAfterController = TextEditingController(
      text:
          transaction.balanceAfter != null
              ? Formatter.currencyInputFormatter
                  .formatEditUpdate(
                    const TextEditingValue(text: ''),
                    TextEditingValue(
                      text: transaction.balanceAfter!.toInt().toString(),
                    ),
                  )
                  .text
              : '',
    );
    final lenderController = TextEditingController(
      text: transaction.lender ?? '',
    );
    final borrowerController = TextEditingController(
      text: transaction.borrower ?? '',
    );

    // Initial values from transaction
    DateTime selectedDate = transaction.date;
    DateTime? repaymentDate = transaction.repaymentDate;
    String selectedCategoryKey = transaction.categoryKey;
    String selectedType = _getLocalizedType(context, transaction.typeKey);

    // Store original wallet paths to preserve them when saving
    final originalWalletPath = transaction.wallet;
    final originalFromWalletPath = transaction.fromWallet;
    final originalToWalletPath = transaction.toWallet;

    // Extract wallet names for UI display
    String selectedWallet =
        _extractWalletNameFromPath(transaction.wallet) ?? '';
    String selectedFromWallet =
        _extractWalletNameFromPath(transaction.fromWallet) ?? '';
    String selectedToWallet =
        _extractWalletNameFromPath(transaction.toWallet) ?? '';

    // For tracking if wallet selection has changed
    String initialSelectedWallet = selectedWallet;
    String initialFromWallet = selectedFromWallet;
    String initialToWallet = selectedToWallet;

    // Check if the extracted names exist in the available wallets list
    // If not, default to the first wallet
    if (selectedWallet.isNotEmpty && !walletNames.contains(selectedWallet)) {
      selectedWallet = walletNames.isNotEmpty ? walletNames.first : '';
    }

    if (selectedFromWallet.isNotEmpty &&
        !walletNames.contains(selectedFromWallet)) {
      selectedFromWallet = walletNames.isNotEmpty ? walletNames.first : '';
    }

    if (selectedToWallet.isNotEmpty &&
        !walletNames.contains(selectedToWallet)) {
      selectedToWallet =
          walletNames.length > 1
              ? walletNames[1]
              : (walletNames.isNotEmpty ? walletNames.first : '');
    }

    String? dateError;
    String? repaymentDateError;

    // Setup category dropdown items
    final categoryItems =
        categoryMap.entries
            .map(
              (entry) => DropdownMenuItem<String>(
                value: entry.key,
                child: Text(entry.value),
              ),
            )
            .toList();

    // Setup transaction type items
    final transactionTypes = Constants.getTransactionTypes(l10n);

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
          validator:
              (v) => Validators.validateNotEmpty(
                v,
                fieldName: l10n.descriptionLabel,
              ),
          isRequired: true,
        ),
        const SizedBox(height: 16),
        InputFields.buildDropdownField<String>(
          label: l10n.transactionTypeLabel,
          value: selectedType,
          items:
              transactionTypes
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              selectedType = newValue;
              balanceAfterController.clear();
              lenderController.clear();
              borrowerController.clear();
              repaymentDate = null;
              repaymentDateError = null;
              selectedCategoryKey =
                  selectedType == l10n.transactionTypeExpense &&
                          categoryMap.isNotEmpty
                      ? categoryMap.keys.first
                      : '';
              if (walletNames.isNotEmpty) {
                selectedWallet = walletNames.first;
                selectedFromWallet = walletNames.first;
                selectedToWallet =
                    walletNames.length > 1 ? walletNames[1] : walletNames.first;
              }
            }
          },
          validator:
              (v) => Validators.validateNotEmpty(
                v,
                fieldName: l10n.transactionTypeLabel,
              ),
          isRequired: true,
        ),
        const SizedBox(height: 16),

        // Date picker and other form fields based on transaction type
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

        // Build conditional form fields based on transaction type
        if (selectedType == l10n.transactionTypeExpense)
          ..._buildExpenseFields(
            context: context,
            l10n: l10n,
            selectedCategoryKey: selectedCategoryKey,
            categoryItems: categoryItems,
            onCategoryChanged:
                (v) => selectedCategoryKey = v ?? selectedCategoryKey,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
            onWalletChanged: (v) => selectedWallet = v ?? selectedWallet,
          ),

        if (selectedType == l10n.transactionTypeIncome)
          ..._buildIncomeFields(
            context: context,
            l10n: l10n,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
            onWalletChanged: (v) => selectedWallet = v ?? selectedWallet,
          ),

        if (selectedType == l10n.transactionTypeTransfer)
          ..._buildTransferFields(
            context: context,
            l10n: l10n,
            selectedFromWallet: selectedFromWallet,
            selectedToWallet: selectedToWallet,
            walletNames: walletNames,
            onFromWalletChanged: (newValue) {
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
            onToWalletChanged: (v) => selectedToWallet = v ?? selectedToWallet,
          ),

        if (selectedType == l10n.transactionTypeBorrow)
          ..._buildBorrowFields(
            context: context,
            l10n: l10n,
            lenderController: lenderController,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
            onWalletChanged: (v) => selectedWallet = v ?? selectedWallet,
            repaymentDate: repaymentDate,
            onRepaymentDateChanged: (picked) => repaymentDate = picked,
            repaymentDateError: repaymentDateError,
          ),

        if (selectedType == l10n.transactionTypeLend)
          ..._buildLendFields(
            context: context,
            l10n: l10n,
            borrowerController: borrowerController,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
            onWalletChanged: (v) => selectedWallet = v ?? selectedWallet,
            repaymentDate: repaymentDate,
            onRepaymentDateChanged: (picked) => repaymentDate = picked,
            repaymentDateError: repaymentDateError,
          ),

        if (selectedType == l10n.transactionTypeAdjustment)
          ..._buildAdjustmentFields(
            context: context,
            l10n: l10n,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
            onWalletChanged: (v) => selectedWallet = v ?? selectedWallet,
            balanceAfterController: balanceAfterController,
          ),

        // Show amount field for all except adjustment type
        if (selectedType != l10n.transactionTypeAdjustment) ...[
          InputFields.buildBalanceInputField(
            amountController,
            validator: (value) {
              final currentBalance =
                  walletBalances[selectedType == l10n.transactionTypeTransfer
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
        // Validate form inputs
        dateError = Validators.validateDate(selectedDate);
        if (selectedType == l10n.transactionTypeBorrow ||
            selectedType == l10n.transactionTypeLend) {
          repaymentDateError = Validators.validateRepaymentDate(
            repaymentDate,
            selectedDate,
          );
        } else {
          repaymentDateError = null;
        }

        if (dateError != null || repaymentDateError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkDateError),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            ),
          );
          return;
        }

        if (formKey.currentState!.validate()) {
          // Perform additional validations
          if (!_validateWalletSelection(
            context: context,
            l10n: l10n,
            selectedType: selectedType,
            selectedFromWallet: selectedFromWallet,
            selectedToWallet: selectedToWallet,
            selectedWallet: selectedWallet,
            walletNames: walletNames,
          )) {
            return;
          }

          // Calculate amount and verify sufficient balance
          final amount =
              Formatter.getRawCurrencyValue(amountController.text).toDouble();
          final balanceAfter =
              selectedType == l10n.transactionTypeAdjustment
                  ? Formatter.getRawCurrencyValue(
                    balanceAfterController.text,
                  ).toDouble()
                  : null;

          // Check balance for source wallet
          if (!_checkSufficientBalance(
            context: context,
            l10n: l10n,
            selectedType: selectedType,
            amount: amount,
            selectedWallet: selectedWallet,
            selectedFromWallet: selectedFromWallet,
            walletBalances: walletBalances,
          )) {
            return;
          }

          // Create a map to store wallet mappings from name to path
          final Map<String, String?> walletPathMap = {};

          // Determine which wallet paths to use - preserve original paths if wallet wasn't changed
          String? walletPath = null;
          String? fromWalletPath = null;
          String? toWalletPath = null;

          if (selectedType != l10n.transactionTypeTransfer) {
            // For non-transfer transactions, handle the main wallet
            if (selectedWallet == initialSelectedWallet &&
                originalWalletPath != null) {
              // If wallet hasn't changed, preserve original path
              walletPath = originalWalletPath;
            } else {
              // If wallet has changed, use the wallet name (repository will resolve to path)
              walletPath = selectedWallet;
            }
          } else {
            // For transfer transactions, handle fromWallet and toWallet
            if (selectedFromWallet == initialFromWallet &&
                originalFromWalletPath != null) {
              fromWalletPath = originalFromWalletPath;
            } else {
              fromWalletPath = selectedFromWallet;
            }

            if (selectedToWallet == initialToWallet &&
                originalToWalletPath != null) {
              toWalletPath = originalToWalletPath;
            } else {
              toWalletPath = selectedToWallet;
            }
          }

          // Save transaction changes
          onSave(
            TransactionModel(
              id: transaction.id,
              userId: transaction.userId,
              description: descriptionController.text.trim(),
              amount: amount,
              date: selectedDate,
              typeKey: _mapLocalizedTypeToKey(selectedType, l10n),
              categoryKey:
                  selectedType == l10n.transactionTypeExpense
                      ? selectedCategoryKey
                      : '',
              wallet:
                  selectedType != l10n.transactionTypeTransfer
                      ? walletPath
                      : null,
              fromWallet:
                  selectedType == l10n.transactionTypeTransfer
                      ? fromWalletPath
                      : null,
              toWallet:
                  selectedType == l10n.transactionTypeTransfer
                      ? toWalletPath
                      : null,
              lender:
                  selectedType == l10n.transactionTypeBorrow
                      ? lenderController.text.trim()
                      : null,
              borrower:
                  selectedType == l10n.transactionTypeLend
                      ? borrowerController.text.trim()
                      : null,
              repaymentDate:
                  (selectedType == l10n.transactionTypeBorrow ||
                          selectedType == l10n.transactionTypeLend)
                      ? repaymentDate
                      : null,
              balanceAfter: balanceAfter,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.checkInputError),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
            ),
          );
        }
      },
    );
  }

  // Helper methods for form field groups
  static List<Widget> _buildExpenseFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedCategoryKey,
    required List<DropdownMenuItem<String>> categoryItems,
    required ValueChanged<String?> onCategoryChanged,
    required String selectedWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onWalletChanged,
  }) {
    return [
      InputFields.buildDropdownField<String>(
        label: l10n.expenseCategoryLabel,
        value: selectedCategoryKey,
        items: categoryItems,
        onChanged: onCategoryChanged,
        validator:
            (v) => Validators.validateNotEmpty(
              v,
              fieldName: l10n.expenseCategoryLabel,
            ),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDropdownField<String>(
        label: l10n.fromWalletLabel,
        value: selectedWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onWalletChanged,
        validator:
            (v) =>
                Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
    ];
  }

  static List<Widget> _buildIncomeFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onWalletChanged,
  }) {
    return [
      InputFields.buildDropdownField<String>(
        label: l10n.toWalletLabel,
        value: selectedWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onWalletChanged,
        validator:
            (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
    ];
  }

  static List<Widget> _buildTransferFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedFromWallet,
    required String selectedToWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onFromWalletChanged,
    required ValueChanged<String?> onToWalletChanged,
  }) {
    return [
      InputFields.buildDropdownField<String>(
        label: l10n.fromWalletSourceLabel,
        value: selectedFromWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onFromWalletChanged,
        validator:
            (v) => Validators.validateWallet(
              v,
              fieldName: l10n.fromWalletSourceLabel,
            ),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDropdownField<String>(
        label: l10n.toWalletDestinationLabel,
        value: selectedToWallet,
        items:
            walletNames
                .where((name) => name != selectedFromWallet)
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onToWalletChanged,
        validator:
            (v) => Validators.validateWallet(
              v,
              fieldName: l10n.toWalletDestinationLabel,
              checkAgainst: selectedFromWallet,
            ),
        isRequired: true,
      ),
      const SizedBox(height: 16),
    ];
  }

  static List<Widget> _buildBorrowFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required TextEditingController lenderController,
    required String selectedWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onWalletChanged,
    required DateTime? repaymentDate,
    required Function(DateTime?) onRepaymentDateChanged,
    required String? repaymentDateError,
  }) {
    return [
      InputFields.buildTextField(
        controller: lenderController,
        label: l10n.lenderLabel,
        hint: l10n.lenderHint,
        validator:
            (v) => Validators.validateNotEmpty(v, fieldName: l10n.lenderLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDropdownField<String>(
        label: l10n.toWalletLabel,
        value: selectedWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onWalletChanged,
        validator:
            (v) => Validators.validateWallet(v, fieldName: l10n.toWalletLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDatePickerField(
        context: context,
        date: repaymentDate,
        label: l10n.repaymentDateOptionalLabel,
        onTap: onRepaymentDateChanged,
        errorText: repaymentDateError,
        isRequired: false,
      ),
      const SizedBox(height: 16),
    ];
  }

  static List<Widget> _buildLendFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required TextEditingController borrowerController,
    required String selectedWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onWalletChanged,
    required DateTime? repaymentDate,
    required Function(DateTime?) onRepaymentDateChanged,
    required String? repaymentDateError,
  }) {
    return [
      InputFields.buildTextField(
        controller: borrowerController,
        label: l10n.borrowerLabel,
        hint: l10n.borrowerHint,
        validator:
            (v) =>
                Validators.validateNotEmpty(v, fieldName: l10n.borrowerLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDropdownField<String>(
        label: l10n.fromWalletLabel,
        value: selectedWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onWalletChanged,
        validator:
            (v) =>
                Validators.validateWallet(v, fieldName: l10n.fromWalletLabel),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      InputFields.buildDatePickerField(
        context: context,
        date: repaymentDate,
        label: l10n.repaymentDateOptionalLabel,
        onTap: onRepaymentDateChanged,
        errorText: repaymentDateError,
        isRequired: false,
      ),
      const SizedBox(height: 16),
    ];
  }

  static List<Widget> _buildAdjustmentFields({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedWallet,
    required List<String> walletNames,
    required ValueChanged<String?> onWalletChanged,
    required TextEditingController balanceAfterController,
  }) {
    return [
      InputFields.buildDropdownField<String>(
        label: l10n.walletToAdjustLabel,
        value: selectedWallet,
        items:
            walletNames
                .map(
                  (name) =>
                      DropdownMenuItem<String>(value: name, child: Text(name)),
                )
                .toList(),
        onChanged: onWalletChanged,
        validator:
            (v) => Validators.validateWallet(
              v,
              fieldName: l10n.walletToAdjustLabel,
            ),
        isRequired: true,
      ),
      const SizedBox(height: 16),
      UtilityWidgets.buildLabel(
        context: context,
        text: l10n.actualBalanceAfterAdjustmentLabel,
      ),
      const SizedBox(height: 8),
      InputFields.buildBalanceInputField(
        balanceAfterController,
        validator: (v) => Validators.validateBalanceAfterAdjustment(v),
      ),
      const SizedBox(height: 16),
    ];
  }

  // Helper methods for validation
  static bool _validateWalletSelection({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedType,
    required String selectedFromWallet,
    required String selectedToWallet,
    required String selectedWallet,
    required List<String> walletNames,
  }) {
    if (selectedType == l10n.transactionTypeTransfer) {
      if (selectedFromWallet.isEmpty || selectedToWallet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectSourceAndDestinationWalletError),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
        return false;
      }
      if (walletNames.length > 1 && selectedFromWallet == selectedToWallet) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.sourceAndDestinationWalletCannotBeSameError),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
        return false;
      }
    } else if (selectedType != l10n.transactionTypeIncome) {
      if (selectedWallet.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.selectWalletForTransactionError(selectedType)),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
        return false;
      }
    }
    return true;
  }

  static bool _checkSufficientBalance({
    required BuildContext context,
    required AppLocalizations l10n,
    required String selectedType,
    required double amount,
    required String selectedWallet,
    required String selectedFromWallet,
    required Map<String, double> walletBalances,
  }) {
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
          ),
        );
        return false;
      }
    }
    return true;
  }

  // Helper method to get localized transaction type
  static String _getLocalizedType(BuildContext context, String typeKey) {
    final l10n = AppLocalizations.of(context)!;

    switch (typeKey) {
      case 'income':
        return l10n.transactionTypeIncome;
      case 'expense':
        return l10n.transactionTypeExpense;
      case 'transfer':
        return l10n.transactionTypeTransfer;
      case 'borrow':
        return l10n.transactionTypeBorrow;
      case 'lend':
        return l10n.transactionTypeLend;
      case 'adjustment':
        return l10n.transactionTypeAdjustment;
      default:
        return typeKey;
    }
  }

  // Helper method to map localized type back to key
  static String _mapLocalizedTypeToKey(
    String localizedType,
    AppLocalizations l10n,
  ) {
    if (localizedType == l10n.transactionTypeIncome) return "income";
    if (localizedType == l10n.transactionTypeExpense) return "expense";
    if (localizedType == l10n.transactionTypeTransfer) return "transfer";
    if (localizedType == l10n.transactionTypeBorrow) return "borrow";
    if (localizedType == l10n.transactionTypeLend) return "lend";
    if (localizedType == l10n.transactionTypeAdjustment) return "adjustment";
    return localizedType; // Fallback
  }

  // New helper method to extract wallet name from a Firestore path
  static String? _extractWalletNameFromPath(String? path) {
    if (path == null || path.isEmpty) {
      return null;
    }

    // Extract the last part of the path (document ID)
    final parts = path.split('/');
    if (parts.length >= 2) {
      return parts.last; // Return the document ID
    }

    // If the path doesn't look like a Firestore path, return it as is
    return path;
  }
}
