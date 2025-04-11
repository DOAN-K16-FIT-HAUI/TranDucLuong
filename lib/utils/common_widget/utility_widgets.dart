import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/common_widget/decorations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';

class UtilityWidgets {
  static Widget buildSearchField({
    required BuildContext context,
    required String hintText,
    required Function(String) onChanged,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: Decorations.boxDecoration(
        context,
      ).copyWith(borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: 15,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            size: 22,
          ),
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 20,
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: 15,
          color: theme.colorScheme.onSurface,
        ),
        cursorColor: theme.colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  static Widget buildCategoryChips({
    required BuildContext context,
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onCategorySelected,
    String? title,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children:
              categories.map((category) {
                final bool isSelected = selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color:
                        isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                  ),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) onCategorySelected(category);
                  },
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.12,
                  ),
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color:
                          isSelected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                      width: isSelected ? 1.0 : 0.8,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  showCheckmark: false,
                );
              }).toList(),
        ),
      ],
    );
  }

  static Widget buildLabel({
    required BuildContext context,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  static Widget buildLoadingIndicator({
    required BuildContext context,
    Color? color,
    double size = 40.0,
  }) {
    return Center(
      child: SpinKitFadingCircle(
        color: color ?? Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );
  }

  static Widget buildEmptyState({
    required BuildContext context,
    required String message,
    String? suggestion,
    IconData icon = Icons.inbox_outlined,
    double iconSize = 60,
    VoidCallback? onActionPressed,
    String? actionText,
    IconData? actionIcon,
  }) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: theme.disabledColor),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 17,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 10),
              Text(
                suggestion,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: theme.hintColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon:
                    actionIcon != null
                        ? Icon(actionIcon, size: 18)
                        : const SizedBox.shrink(),
                label: Text(actionText),
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState({
    required BuildContext context,
    required String Function(BuildContext) message, // Thay String bằng String Function(BuildContext)
    required VoidCallback onRetry,
    String title = '',
    IconData icon = Icons.error_outline_rounded,
    Color iconColor = AppTheme.expenseColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final effectiveTitle = title.isEmpty ? l10n.errorLoadingData : title;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 50),
            const SizedBox(height: 16),
            Text(
              effectiveTitle,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message(context), // Gọi hàm message với context hiện tại
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showCustomSnackBar({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 2),
    SnackBarBehavior behavior = SnackBarBehavior.fixed,
    Color? backgroundColor,
    TextStyle? textStyle,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
        duration: duration,
        behavior: behavior,
        // margin: margin,
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
        action: action,
      ),
    );
  }
}
