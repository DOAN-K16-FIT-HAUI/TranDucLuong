import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dialogs.dart';

class MenuActions {
  static List<PopupMenuItem<String>> buildEditDeleteMenuItems({
    required BuildContext context,
    IconData editIcon = Icons.edit_outlined,
    IconData deleteIcon = Icons.delete_outline,
    String editText = '',
    String deleteText = '',
    Color? editIconColor,
    Color? deleteIconColor,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return [
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              editIcon,
              size: 20,
              color: editIconColor ?? theme.colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              editText.isEmpty ? l10n.edit : editText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(
              deleteIcon,
              size: 20,
              color: deleteIconColor ?? theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Text(
              deleteText.isEmpty ? l10n.delete : deleteText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  static void handleEditDeleteActions<T>({
    required BuildContext context,
    required String action,
    required T item,
    required String itemName,
    required void Function(BuildContext context, T item) onEdit,
    required void Function(BuildContext context, T item) onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (action == 'edit') {
      onEdit(context, item);
    } else if (action == 'delete') {
      Dialogs.showDeleteDialog(
        context: context,
        title: l10n.confirmDeleteTitle,
        content: l10n.confirmDeleteContent(itemName),
        onDeletePressed: () => onDelete(context, item),
      );
    }
  }
}
