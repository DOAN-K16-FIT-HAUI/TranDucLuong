import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class Dialogs {
  static Future<void> showFormDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required List<Widget> formFields,
    required String title,
    required String actionButtonText,
    required Function onActionButtonPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 15,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            title: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: formFields,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    onActionButtonPressed();
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  actionButtonText,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  static Future<void> showDeleteDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onDeletePressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onDeletePressed();
                },
                child: Text(
                  l10n.confirm,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  static Future<void> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    required String confirmText,
    required VoidCallback onConfirm,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.notoSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  onConfirm();
                },
                child: Text(
                  confirmText,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  static Future<IconData?> showIconSelectionDialog({
    required BuildContext context,
    required IconData currentIcon,
    required List<Map<String, dynamic>> availableIcons,
    String title = '',
    double dialogHeightFactor = 0.6,
    int crossAxisCount = 3,
    double iconSize = 26,
    Color? selectedColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final effectiveSelectedColor = selectedColor ?? theme.colorScheme.primary;

    return await showDialog<IconData>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: theme.colorScheme.surface,
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(
              title.isEmpty ? l10n.selectIconTitle : title,
              style: GoogleFonts.notoSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            content: SizedBox(
              width: double.maxFinite,
              height:
                  MediaQuery.of(dialogContext).size.height * dialogHeightFactor,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: availableIcons.length,
                itemBuilder: (gridContext, index) {
                  final iconMap = availableIcons[index];
                  final iconData = iconMap['icon'] as IconData;
                  final iconName = iconMap['name'] as String;
                  final bool isSelected = iconData == currentIcon;

                  return InkWell(
                    onTap: () => Navigator.pop(dialogContext, iconData),
                    borderRadius: BorderRadius.circular(8),
                    child: Tooltip(
                      message: iconName,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? effectiveSelectedColor.withValues(
                                    alpha: 0.15,
                                  )
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                isSelected
                                    ? effectiveSelectedColor
                                    : theme.dividerColor,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              iconData,
                              color: effectiveSelectedColor,
                              size: iconSize,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconName,
                              style: GoogleFonts.notoSans(
                                fontSize: 9,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, null),
                child: Text(
                  l10n.cancel,
                  style: GoogleFonts.notoSans(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}
