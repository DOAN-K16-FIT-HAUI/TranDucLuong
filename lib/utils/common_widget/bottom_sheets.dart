import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BottomSheets {
  /// Creates a standard bottom sheet with fixed header, scrollable content, and fixed footer
  static Future<T?> showStandardBottomSheet<T>({
    required BuildContext context,
    required Widget header,
    required Widget content,
    required Widget footer,
    double? height,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
    BorderRadius? borderRadius,
  }) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    // Default to 60% of screen height if not specified
    final effectiveHeight = height ?? screenHeight * 0.6;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true, // Always true to handle custom height
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      shape: RoundedRectangleBorder(
        borderRadius:
            borderRadius ?? BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          height: effectiveHeight,
          child: Column(
            children: [
              // Fixed header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: header,
              ),
              Divider(height: 1),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: content,
                ),
              ),

              // Fixed footer
              Container(
                padding: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 8.0,
                  bottom: 16.0 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: footer,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Creates a filter button for the app bar
  static Widget buildFilterButton({
    required BuildContext context,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(
        Icons.filter_alt_outlined,
        color: theme.colorScheme.onPrimaryContainer,
      ),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  /// Creates a sort button for the app bar
  static Widget buildSortButton({
    required BuildContext context,
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(Icons.sort, color: theme.colorScheme.onPrimaryContainer),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  /// Creates a button for the bottom of a bottom sheet
  static Widget buildBottomSheetButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    final theme = Theme.of(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        minimumSize: Size(double.infinity, 50),
      ),
      onPressed: onPressed,
      child: Text(text),
    );
  }

  /// Creates a header row with a title and optional action button
  static Widget buildHeaderRow({
    required BuildContext context,
    required String title,
    String? actionText,
    VoidCallback? onActionPressed,
    bool centerTitle = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment:
          centerTitle
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        if (actionText != null && onActionPressed != null)
          TextButton(onPressed: onActionPressed, child: Text(actionText)),
      ],
    );
  }

  /// Creates a filter chip for selected filters
  static Widget buildFilterChip({
    required BuildContext context,
    required String label,
    required VoidCallback onDeleted,
  }) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
      ),
      onDeleted: onDeleted,
      backgroundColor: theme.colorScheme.primaryContainer,
      deleteIconColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  /// Creates a multi-selection filter list
  static Widget buildMultiSelectionList<T>({
    required BuildContext context,
    required List<T> selectedItems,
    required List<MapEntry<T, String>> items,
    required Function(T, bool) onItemToggled,
  }) {
    return Column(
      children:
          items.map((entry) {
            final item = entry.key;
            final label = entry.value;

            return CheckboxListTile(
              title: Text(label),
              value: selectedItems.contains(item),
              onChanged: (bool? checked) {
                if (checked != null) {
                  onItemToggled(item, checked);
                }
              },
              controlAffinity: ListTileControlAffinity.leading,
            );
          }).toList(),
    );
  }

  /// Creates a radio selection list
  static Widget buildRadioSelectionList<T>({
    required BuildContext context,
    required T groupValue,
    required List<MapEntry<T, String>> items,
    required Function(T?) onItemSelected,
  }) {
    return Column(
      children:
          items.map((entry) {
            final value = entry.key;
            final label = entry.value;

            return RadioListTile<T>(
              title: Text(label),
              value: value,
              groupValue: groupValue,
              onChanged: onItemSelected,
            );
          }).toList(),
    );
  }
}
