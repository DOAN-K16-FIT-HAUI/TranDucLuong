import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/common_widget/bottom_sheets.dart';
import 'package:finance_app/utils/common_widget/lists_cards.dart';
import 'package:finance_app/utils/common_widget/menu_actions.dart';
import 'package:finance_app/utils/common_widget/utility_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// Widget utilities specific to transactions
class TransactionWidgets {
  /// Builds a grouped transaction list view
  static Widget buildGroupedListView({
    required BuildContext context,
    required Map<String, List<TransactionModel>> groupedData,
    required AppLocalizations l10n,
    required Locale locale,
    required Function(BuildContext, String, TransactionModel) onMenuAction,
    bool isSearching = false,
  }) {
    if (groupedData.isEmpty) {
      return UtilityWidgets.buildEmptyState(
        context: context,
        message:
            isSearching ? l10n.noMatchingTransactions : l10n.noTransactionsYet,
        suggestion: isSearching ? null : l10n.addFirstTransactionHint,
        onActionPressed:
            isSearching ? null : () => AppRoutes.navigateToTransaction(context),
        actionText: isSearching ? null : l10n.addTransactionButton,
      );
    }

    final groupKeys = groupedData.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ).copyWith(bottom: 80),
      itemCount: groupKeys.length,
      itemBuilder: (context, index) {
        final groupKey = groupKeys[index];
        final groupTransactions = groupedData[groupKey]!;
        final theme = Theme.of(context);

        double groupIncome = groupTransactions
            .where((t) => t.typeKey == 'income' || t.typeKey == 'borrow')
            .fold(0.0, (sum, t) => sum + t.amount);
        double groupExpense = groupTransactions
            .where(
              (t) =>
                  t.typeKey == 'expense' ||
                  t.typeKey == 'lend' ||
                  t.typeKey == 'transfer',
            )
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
                    symbol: getCurrencySymbol(locale),
                    decimalDigits: 0,
                  ).format(groupNet),
                  style: GoogleFonts.notoSans(
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
            const SizedBox(height: 8),
            ...groupTransactions.map(
              (t) => ListsCards.buildTransactionListItem(
                context: context,
                transaction: t,
                menuItems: MenuActions.buildEditDeleteMenuItems(
                  context: context,
                ),
                onMenuSelected: (result) => onMenuAction(context, result, t),
              ),
            ),
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

  /// Groups transactions by day, month, or year
  static Map<String, List<TransactionModel>> groupTransactions({
    required List<TransactionModel> transactions,
    required int groupType, // 0=day, 1=month, 2=year
    required Locale locale,
  }) {
    final grouped = <String, List<TransactionModel>>{};
    for (final transaction in transactions) {
      String key;
      switch (groupType) {
        case 0: // Day
          key = DateFormat.yMMMMd(locale.toString()).format(transaction.date);
          break;
        case 1: // Month
          key = DateFormat.yMMMM(locale.toString()).format(transaction.date);
          break;
        case 2: // Year
          key = DateFormat.y(locale.toString()).format(transaction.date);
          break;
        default:
          key = DateFormat.yMMMMd(locale.toString()).format(transaction.date);
      }
      (grouped[key] ??= []).add(transaction);
    }
    return grouped;
  }

  /// Filters transactions by search query
  static List<TransactionModel> filterTransactionsByQuery({
    required String query,
    required List<TransactionModel> transactions,
    required BuildContext context,
    required Map<String, String> categoryMap,
  }) {
    if (query.isEmpty) return transactions;
    return transactions.where((t) {
      final queryLower = query.toLowerCase();
      final categoryDisplay =
          t.categoryKey.isNotEmpty
              ? mapCategoryKeyToLocalized(t.categoryKey, categoryMap)
              : '';
      return t.description.toLowerCase().contains(queryLower) ||
          t.typeKey.toLowerCase().contains(queryLower) ||
          (t.categoryKey.isNotEmpty &&
              categoryDisplay.toLowerCase().contains(queryLower)) ||
          (t.wallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.fromWallet?.toLowerCase().contains(queryLower) ?? false) ||
          (t.toWallet?.toLowerCase().contains(queryLower) ?? false);
    }).toList();
  }

  /// Filter transactions by multiple types
  static List<TransactionModel> filterTransactionsByType({
    required List<TransactionModel> transactions,
    required List<String> typeFilters,
  }) {
    if (typeFilters.isEmpty) return transactions;
    return transactions.where((t) => typeFilters.contains(t.typeKey)).toList();
  }

  /// Sort transactions by different criteria
  static List<TransactionModel> sortTransactions({
    required List<TransactionModel> transactions,
    required String sortOrder,
  }) {
    switch (sortOrder) {
      case 'newest':
        return transactions..sort((a, b) => b.date.compareTo(a.date));
      case 'oldest':
        return transactions..sort((a, b) => a.date.compareTo(b.date));
      case 'highest':
        return transactions..sort((a, b) => b.amount.compareTo(a.amount));
      case 'lowest':
        return transactions..sort((a, b) => a.amount.compareTo(b.amount));
      default:
        return transactions..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  /// Shows filter bottom sheet for transaction types
  static void showFilterBottomSheet({
    required BuildContext context,
    required Map<String, String> transactionTypeMap,
    required List<String> selectedTypeFilters,
    required Function(List<String>) onFiltersChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    final typeItems =
        transactionTypeMap.entries
            .map((entry) => MapEntry(entry.key, entry.value))
            .toList();

    List<String> tempSelectedFilters = List.from(selectedTypeFilters);

    // Use the fixed height bottom sheet
    BottomSheets.showStandardBottomSheet(
      context: context,
      height: screenHeight * 0.7, // Set to 70% of screen height
      header: BottomSheets.buildHeaderRow(
        context: context,
        title: l10n.filterByType,
        actionText: l10n.resetFilters,
        onActionPressed: () {
          tempSelectedFilters = [];
          Navigator.pop(context);
          onFiltersChanged(tempSelectedFilters);
        },
      ),
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return BottomSheets.buildMultiSelectionList<String>(
            context: context,
            selectedItems: tempSelectedFilters,
            items: typeItems,
            onItemToggled: (item, checked) {
              setModalState(() {
                if (checked) {
                  if (!tempSelectedFilters.contains(item)) {
                    tempSelectedFilters.add(item);
                  }
                } else {
                  tempSelectedFilters.remove(item);
                }
              });
            },
          );
        },
      ),
      footer: BottomSheets.buildBottomSheetButton(
        context: context,
        text: l10n.applyFilter,
        onPressed: () {
          Navigator.pop(context);
          onFiltersChanged(tempSelectedFilters);
        },
      ),
    );
  }

  /// Shows sort bottom sheet for transactions
  static void showSortBottomSheet({
    required BuildContext context,
    required String currentSortOrder,
    required Function(String) onSortOrderChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final screenHeight = MediaQuery.of(context).size.height;

    String tempSortOrder = currentSortOrder;

    final sortOptions = [
      MapEntry('newest', l10n.newest),
      MapEntry('oldest', l10n.oldest),
      MapEntry('highest', l10n.highestAmount),
      MapEntry('lowest', l10n.lowestAmount),
    ];

    // Use the fixed height bottom sheet
    BottomSheets.showStandardBottomSheet(
      context: context,
      height: screenHeight * 0.5, // Set to 50% of screen height
      header: BottomSheets.buildHeaderRow(
        context: context,
        title: l10n.sortBy,
        centerTitle: true,
      ),
      content: StatefulBuilder(
        builder: (context, setModalState) {
          return BottomSheets.buildRadioSelectionList<String>(
            context: context,
            groupValue: tempSortOrder,
            items: sortOptions,
            onItemSelected: (value) {
              if (value != null) {
                setModalState(() {
                  tempSortOrder = value;
                });
              }
            },
          );
        },
      ),
      footer: BottomSheets.buildBottomSheetButton(
        context: context,
        text: l10n.applySort,
        onPressed: () {
          Navigator.pop(context);
          onSortOrderChanged(tempSortOrder);
        },
      ),
    );
  }

  /// Helper method to get currency symbol based on locale
  static String getCurrencySymbol(Locale locale) {
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

  /// Helper method to map category key to localized string
  static String mapCategoryKeyToLocalized(
    String key,
    Map<String, String> categoryMap,
  ) {
    return categoryMap[key] ?? key;
  }
}
