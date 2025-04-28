import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ListsCards {
  static Widget buildTabContent<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(BuildContext context, T item, int index) itemBuilder,
  }) {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
    );
  }

  static Widget buildItemCard<T>({
    required BuildContext context,
    required T item,
    required Key itemKey,
    required String title,
    double? value,
    IconData? icon,
    Color? iconColor,
    Color? amountColor,
    String? valuePrefix,
    String? valueLocale,
    List<PopupMenuItem<String>>? menuItems,
    void Function(String)? onMenuSelected,
    Widget? subtitle,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
    Color? backgroundColor,
    void Function()? onTap, // Thêm tham số onTap
  }) {
    final theme = Theme.of(context);
    final locale = valueLocale ?? Intl.getCurrentLocale();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return GestureDetector(
      onTap: onTap, // Gán sự kiện onTap
      child: Container(
        key: itemKey,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.5),
            width: 0.05,
          ),
        ),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: iconColor ?? theme.colorScheme.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.notoSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      DefaultTextStyle(
                        style: theme.textTheme.bodySmall ?? const TextStyle(),
                        child: subtitle,
                      ),
                    ],
                    if (value != null && value != 0) ...[
                      const SizedBox(height: 3),
                      Text(
                        (valuePrefix ?? '') +
                            NumberFormat.currency(
                              locale: locale,
                              symbol: currencySymbol,
                              decimalDigits: 0,
                            ).format(value),
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: amountColor ?? (value >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (menuItems != null && onMenuSelected != null)
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    size: 22,
                  ),
                  offset: const Offset(0, 35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  color: theme.colorScheme.surfaceContainerHighest,
                  elevation: 1.5,
                  onSelected: onMenuSelected,
                  itemBuilder: (context) => menuItems,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String getLocalizedType(BuildContext context, String typeKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (typeKey) {
      case "income":
        return l10n.transactionTypeIncome;
      case "expense":
        return l10n.transactionTypeExpense;
      case "transfer":
        return l10n.transactionTypeTransfer;
      case "borrow":
        return l10n.transactionTypeBorrow;
      case "lend":
        return l10n.transactionTypeLend;
      case "adjustment":
        return l10n.transactionTypeAdjustment;
      default:
        return typeKey;
    }
  }

  static String getLocalizedCategory(BuildContext context, String categoryKey) {
    final l10n = AppLocalizations.of(context)!;
    switch (categoryKey) {
      case "food":
        return l10n.categoryFood;
      case "living":
        return l10n.categoryLiving;
      case "transport":
        return l10n.categoryTransport;
      case "health":
        return l10n.categoryHealth;
      case "shopping":
        return l10n.categoryShopping;
      case "entertainment":
        return l10n.categoryEntertainment;
      case "education":
        return l10n.categoryEducation;
      case "bills":
        return l10n.categoryBills;
      case "gift":
        return l10n.categoryGift;
      case "other":
        return l10n.categoryOther;
      default:
        return categoryKey;
    }
  }

  static Widget buildTransactionListItem({
    required BuildContext context,
    required TransactionModel transaction,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    List<PopupMenuItem<String>>? menuItems,
    void Function(String)? onMenuSelected,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final iconData = ListsCards.getTransactionIcon(context, transaction.typeKey);
    final amountColor = ListsCards.getAmountColor(context, transaction.typeKey);
    final amountPrefix = ListsCards.getAmountPrefix(context, transaction.typeKey);

    final formattedAmount = transaction.typeKey == "adjustment" && transaction.balanceAfter != null
        ? Formatter.formatCurrency(transaction.balanceAfter!, locale: Localizations.localeOf(context))
        : Formatter.formatCurrency(transaction.amount, locale: Localizations.localeOf(context));
    final formattedTime = Formatter.formatTime(transaction.date, locale: Localizations.localeOf(context));

    String subtitleText = '$formattedTime • ${transaction.wallet ?? ''}';
    if (transaction.typeKey == "expense" && transaction.categoryKey.isNotEmpty) {
      subtitleText = '$formattedTime • ${getLocalizedCategory(context, transaction.categoryKey)}';
    } else if (transaction.typeKey == "income" && transaction.categoryKey.isNotEmpty) {
      subtitleText = '$formattedTime • ${getLocalizedCategory(context, transaction.categoryKey)}';
    } else if (transaction.typeKey == "transfer") {
      subtitleText =
      '$formattedTime • ${transaction.fromWallet ?? '?'} → ${transaction.toWallet ?? '?'}';
    } else if (transaction.typeKey == "borrow" && transaction.lender != null) {
      subtitleText = '$formattedTime • ${l10n.borrowFrom}: ${transaction.lender}';
    } else if (transaction.typeKey == "lend" && transaction.borrower != null) {
      subtitleText = '$formattedTime • ${l10n.lendTo}: ${transaction.borrower}';
    } else if (transaction.typeKey == "adjustment" && transaction.wallet != null) {
      transaction.balanceAfter != null
          ? Formatter.formatCurrency(transaction.balanceAfter!, locale: Localizations.localeOf(context))
          : '';
      subtitleText = '$formattedTime • ${transaction.wallet}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.dividerColor.withValues(alpha: 0.5),
          width: 0.05,
        ),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconData['backgroundColor']?.withValues(alpha: 0.15) ??
                    theme.colorScheme.primary.withValues(alpha: 0.15),
                child: Icon(
                  iconData['icon'],
                  color: iconData['backgroundColor'] ?? theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isNotEmpty
                          ? transaction.description
                          : l10n.noDescription,
                      style: GoogleFonts.notoSans(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: GoogleFonts.notoSans(
                        color: theme.hintColor,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  Text(
                    amountPrefix + formattedAmount,
                    style: GoogleFonts.notoSans(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.end,
                  ),
                  if (menuItems != null && onMenuSelected != null) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 22,
                      ),
                      offset: const Offset(0, 35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      color: theme.colorScheme.surfaceContainerHighest,
                      elevation: 1.5,
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => menuItems,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> getTransactionIcon(BuildContext context, String typeKey) {
    switch (typeKey) {
      case "income":
        return {
          'icon': Icons.arrow_downward,
          'backgroundColor': AppTheme.incomeColor,
        };
      case "expense":
        return {
          'icon': Icons.arrow_upward,
          'backgroundColor': AppTheme.expenseColor,
        };
      case "transfer":
        return {
          'icon': Icons.swap_horiz,
          'backgroundColor': AppTheme.transferColor,
        };
      case "borrow":
        return {
          'icon': Icons.call_received,
          'backgroundColor': AppTheme.borrowColor,
        };
      case "lend":
        return {
          'icon': Icons.call_made,
          'backgroundColor': AppTheme.lendColor,
        };
      case "adjustment":
        return {
          'icon': Icons.tune,
          'backgroundColor': AppTheme.adjustmentColor,
        };
      default:
        return {
          'icon': Icons.help_outline,
          'backgroundColor': Colors.grey,
        };
    }
  }

  static Color getAmountColor(BuildContext context, String typeKey) {
    switch (typeKey) {
      case "income":
        return AppTheme.incomeColor;
      case "expense":
        return AppTheme.expenseColor;
      case "transfer":
        return AppTheme.transferColor;
      case "borrow":
        return AppTheme.borrowColor;
      case "lend":
        return AppTheme.lendColor;
      case "adjustment":
        return AppTheme.adjustmentColor;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  static String getAmountPrefix(BuildContext context, String typeKey) {
    switch (typeKey) {
      case "income":
        return '+'; // Thu nhập thực sự
      case "expense":
      case "transfer":
        return '-'; // Chi tiêu hoặc chuyển khoản ra
      case "borrow":
        return '+'; // Nhận tiền từ vay, nhưng là nợ
      case "lend":
        return '-'; // Cho vay, giảm tiền nhưng là khoản phải thu
      case "adjustment":
        return ''; // Không có dấu, vì không phải dòng tiền
      default:
        return '';
    }
  }
}