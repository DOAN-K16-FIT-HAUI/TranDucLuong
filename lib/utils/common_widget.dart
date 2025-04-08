import 'dart:ui';

import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/dimens.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CommonWidgets {
  static Widget buildEmailField({
    required TextEditingController controller,
    void Function(String)? onChanged,
  }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.emailLabel, // Dịch "Email"
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: l10n.enterEmailHint, // Dịch "Nhập email"
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          cursorColor: Theme.of(context).colorScheme.primary,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          validator: (value) => Validators.validateEmail(value, l10n), // Truyền l10n vào validator
        );
      },
    );
  }

  static Widget buildPasswordField(
      TextEditingController controller,
      bool isPasswordVisible,
      VoidCallback toggleVisibility,
      ) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.passwordLabel, // Dịch "Mật khẩu"
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: l10n.enterPasswordHint, // Dịch "Nhập mật khẩu"
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: toggleVisibility,
            ),
          ),
          cursorColor: Theme.of(context).colorScheme.primary,
          obscureText: !isPasswordVisible,
          validator: (value) => Validators.validatePassword(value, l10n), // Truyền l10n vào validator
        );
      },
    );
  }

  static Widget buildSubmitButton(String text, VoidCallback onPressed, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  static Widget buildBalanceInputField(
      TextEditingController controller, {
        String? Function(String?)? validator,
      }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [Formatter.currencyInputFormatter],
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.amountLabel, // Dịch "Số tiền"
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: l10n.enterAmountHint, // Dịch "Nhập số tiền"
            suffixText: '₫',
            suffixStyle: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          cursorColor: Theme.of(context).colorScheme.primary,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          validator: validator,
        );
      },
    );
  }

  static Future<void> showFormDialog({
    required BuildContext context,
    required GlobalKey<FormState> formKey,
    required List<Widget> formFields,
    required String title,
    required String actionButtonText,
    required Function onActionButtonPressed,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: formFields,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel, // Dịch "Hủy"
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                onActionButtonPressed();
                Navigator.pop(context);
              }
            },
            child: Text(
              actionButtonText,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.primary,
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
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.cancel, // Dịch "Hủy"
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withValues(
                  alpha: 153,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeletePressed();
            },
            child: Text(
              l10n.confirm, // Dịch "Xác nhận"
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    String title = '', // Tiêu đề mặc định sẽ được dịch trong l10n
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    IconData? backIcon,
    List<Widget>? actions,
    bool showDropdown = false,
    List<String>? dropdownItems,
    String? dropdownValue,
    ValueChanged<String?>? onDropdownChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return PreferredSize(
      preferredSize: Size.fromHeight(
        kToolbarHeight + MediaQuery.of(context).padding.top,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSafeArea(context),
          _buildHeader(
            context: context,
            title: title.isEmpty ? l10n.accountTitle : title, // Dịch "Tài khoản" nếu không có title
            onBackPressed: onBackPressed,
            showBackButton: showBackButton,
            backIcon: backIcon,
            actions: actions,
            showDropdown: showDropdown,
            dropdownItems: dropdownItems,
            dropdownValue: dropdownValue,
            onDropdownChanged: onDropdownChanged,
          ),
        ],
      ),
    );
  }

  static Widget _buildSafeArea(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: Theme.of(context).colorScheme.primary,
    );
  }

  static Widget _buildHeader({
    required BuildContext context,
    required String title,
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    IconData? backIcon,
    List<Widget>? actions,
    bool showDropdown = false,
    List<String>? dropdownItems,
    String? dropdownValue,
    ValueChanged<String?>? onDropdownChanged,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: kToolbarHeight,
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          showBackButton
              ? IconButton(
            icon: Icon(
              backIcon ?? Icons.arrow_back,
              color: Theme.of(context).colorScheme.surface,
            ),
            tooltip: l10n.backTooltip, // Dịch "Quay lại"
            onPressed: onBackPressed ?? () => Navigator.pop(context),
          )
              : const SizedBox(width: 48),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: showDropdown &&
                  dropdownItems != null &&
                  dropdownValue != null &&
                  onDropdownChanged != null
                  ? DropdownButtonFormField<String>(
                value: dropdownValue,
                onChanged: onDropdownChanged,
                items: dropdownItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: Dimens.textSizeMedium + 2,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  );
                }).toList(),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                style: GoogleFonts.poppins(
                  fontSize: Dimens.textSizeMedium + 2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
                dropdownColor: Theme.of(context).colorScheme.primary,
                iconEnabledColor: Theme.of(context).colorScheme.surface,
                iconSize: 24,
              )
                  : Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: Dimens.textSizeMedium + 2,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.surface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions ?? [const SizedBox(width: 48)],
          ),
        ],
      ),
    );
  }

  static Widget buildSocialLoginButton({
    required VoidCallback onPressed,
    required Color? color,
    required String text, required BuildContext context,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(10),
          elevation: 3,
          backgroundColor: color ?? Theme.of(context).colorScheme.primary,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            color: textColor ?? Theme.of(context).colorScheme.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget buildTabBar({
    required BuildContext context,
    required List<String> tabTitles,
    required Function(int) onTabChanged,
    TabController? controller,
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? indicatorColor,
    Color? backgroundColor,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material(
        color: backgroundColor ?? Theme.of(context).colorScheme.surface,
        child: TabBar(
          controller: controller,
          labelStyle: labelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: unselectedLabelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          labelColor: labelColor ?? Theme.of(context).colorScheme.primary,
          unselectedLabelColor: unselectedLabelColor ?? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: indicatorColor ?? Theme.of(context).colorScheme.primary,
          indicatorWeight: 2.5,
          onTap: onTabChanged,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
        ),
      ),
    );
  }

  static Widget buildTabContent<T>({
    required BuildContext context,
    required List<T> items,
    required String emptyMessage,
    required String searchQuery,
    required List<T> Function(String query, List<T> items) filterItems,
    required bool isSearching,
    required int type,
    required Widget Function(BuildContext context, T item, int type, int index) itemBuilder,
    required void Function(int type, int oldIndex, int newIndex) onReorder,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final filteredItems = filterItems(searchQuery, items);

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          isSearching ? l10n.noItemsFound : emptyMessage, // Dịch "Không tìm thấy mục phù hợp"
          style: GoogleFonts.poppins(
            fontSize: Dimens.textSizeMedium,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 204),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) => itemBuilder(context, filteredItems[index], type, index),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex -= 1;
        if (oldIndex >= 0 && oldIndex < filteredItems.length && newIndex >= 0 && newIndex <= filteredItems.length) {
          onReorder(type, oldIndex, newIndex);
        } else {
          debugPrint("Error: Reorder indices out of bounds.");
        }
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final elevation = lerpDouble(0, 8, Curves.easeInOut.transform(animation.value))!;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black.withValues(alpha: 51),
              borderRadius: BorderRadius.circular(12),
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  static Widget buildItemCard<T>({
    required BuildContext context,
    required T item,
    required Key itemKey,
    required String title,
    required double value,
    required IconData icon,
    Color? iconColor,
    String? valuePrefix,
    String? valueLocale,
    List<PopupMenuItem<String>>? menuItems,
    void Function(String)? onMenuSelected,
    Widget? subtitle,
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    Color? backgroundColor,
  }) {
    return Container(
      key: itemKey,
      margin: margin,
      decoration: boxDecoration(context).copyWith(color: backgroundColor),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: Dimens.textSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    subtitle,
                  ],
                  if (value != 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        locale: valueLocale ?? 'vi_VN',
                        symbol: valuePrefix ?? '₫',
                      ).format(value),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: value >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Theme.of(context).colorScheme.surface,
                elevation: 8,
                onSelected: onMenuSelected,
                itemBuilder: (context) => menuItems,
              ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration boxDecoration(BuildContext context,) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static Future<IconData?> showIconSelectionDialog({
    required BuildContext context,
    required IconData currentIcon,
    required List<Map<String, dynamic>> availableIcons,
    String title = '', // Tiêu đề mặc định sẽ được dịch trong l10n
    double dialogHeightFactor = 0.3,
    int crossAxisCount = 3,
    double iconSize = 28,
    Color? selectedColor,
    Color? unselectedColor,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<IconData>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          title.isEmpty ? l10n.selectIconTitle : title, // Dịch "Chọn biểu tượng"
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * dialogHeightFactor,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
            ),
            itemCount: availableIcons.length,
            itemBuilder: (context, index) {
              final iconData = availableIcons[index];
              final bool isSelected = iconData['icon'] == currentIcon;

              return GestureDetector(
                onTap: () => Navigator.pop(context, iconData['icon']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedColor ?? Theme.of(context).colorScheme.primary).withValues(alpha: 38)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? (selectedColor ?? Theme.of(context).colorScheme.primary)
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 51),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Tooltip(
                    message: iconData['name'],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData['icon'],
                          color: selectedColor ?? Theme.of(context).colorScheme.primary,
                          size: iconSize,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          iconData['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 204),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
            onPressed: () => Navigator.pop(context, null),
            child: Text(
              l10n.cancel, // Dịch "Hủy"
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 204),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<PopupMenuItem<String>> buildEditDeleteMenuItems({
    IconData editIcon = Icons.edit_outlined,
    IconData deleteIcon = Icons.delete_outline,
    String editText = '', // Sẽ được dịch trong l10n
    String deleteText = '', // Sẽ được dịch trong l10n
    Color? editIconColor,
    Color? deleteIconColor,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return [
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              editIcon,
              size: 20,
              color: editIconColor ?? Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              editText.isEmpty ? l10n.edit : editText, // Dịch "Sửa"
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
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
              color: deleteIconColor ?? Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              deleteText.isEmpty ? l10n.delete : deleteText, // Dịch "Xóa"
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
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
    required void Function(BuildContext, T) onEdit,
    required void Function(BuildContext, T) onDelete,
  }) {
    final l10n = AppLocalizations.of(context)!;
    if (action == 'edit') {
      onEdit(context, item);
    } else if (action == 'delete') {
      showDeleteDialog(
        context: context,
        title: l10n.confirmDeleteTitle, // Dịch "Xác nhận xóa"
        content: l10n.confirmDeleteContent(itemName), // Dịch "Bạn có chắc chắn muốn xóa...?"
        onDeletePressed: () => onDelete(context, item),
      );
    }
  }

  static Widget buildSearchField({
    required BuildContext context,
    required String hintText,
    required Function(String) onChanged,
    String? initialValue,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            fontSize: Dimens.textSizeMedium,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: Dimens.textSizeMedium,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        cursorColor: Theme.of(context).colorScheme.primary,
        onChanged: onChanged,
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: '$label ',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Dimens.textSizeMedium,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          cursorColor: Theme.of(context).colorScheme.primary,
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          validator: validator,
        );
      },
    );
  }

  static Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: '$label ',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: Dimens.textSizeMedium,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            ),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.expenseColor),
            ),
            errorStyle: const TextStyle(color: AppTheme.expenseColor),
          ),
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
          ),
          dropdownColor: Theme.of(context).colorScheme.surface,
          iconEnabledColor: Theme.of(context).colorScheme.onSurface,
          validator: validator ?? (value) {
            if (value == null || value.isEmpty) {
              return l10n.selectValueError; // Dịch "Vui lòng chọn một giá trị"
            }
            return null;
          },
        );
      },
    );
  }

  static Widget buildDatePickerField({
    required BuildContext context,
    required DateTime? date,
    required String label,
    required VoidCallback onTap,
    String? errorText,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            '$label: ${date != null ? DateFormat('dd/MM/yyyy').format(date) : l10n.notSelected}', // Dịch "Chưa chọn"
            style: GoogleFonts.poppins(
              fontSize: Dimens.textSizeMedium,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onTap: onTap,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12),
            child: Text(
              errorText,
              style: GoogleFonts.poppins(
                color: AppTheme.expenseColor,
                fontSize: Dimens.textSizeSmall,
              ),
            ),
          ),
      ],
    );
  }

  static Widget buildCategoryChips({
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onCategorySelected,
    required BuildContext context,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.favoriteCategories, // Dịch "Danh mục yêu thích"
          style: GoogleFonts.poppins(
            fontSize: Dimens.textSizeMedium,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: categories.map((category) {
            return ChoiceChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  color: selectedCategory == category
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              selected: selectedCategory == category,
              onSelected: (bool selected) {
                if (selected) {
                  onCategorySelected(category);
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              backgroundColor: Theme.of(context).colorScheme.surface,
              side: BorderSide(
                color: selectedCategory == category
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget buildLabel(BuildContext context,{required String text,}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: Dimens.textSizeMedium,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  static Widget buildLoadingIndicator(BuildContext context,{Color? color, double size = 50.0}) {
    return Center(
      child: SpinKitFadingCircle(
        color: color ?? Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );
  }

  static Widget buildEmptyState({
    required String message,
    required BuildContext context,
    String? suggestion,
    IconData icon = Icons.receipt_long_outlined,
    double iconSize = 80,
    VoidCallback? onActionPressed,
    String? actionText,
    IconData? actionIcon,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (suggestion != null) ...[
              const SizedBox(height: 8),
              Text(
                suggestion,
                style: GoogleFonts.poppins(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 25),
              ElevatedButton.icon(
                icon: actionIcon != null ? Icon(actionIcon) : const SizedBox.shrink(),
                label: Text(actionText),
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildErrorState({
    required String message,
    required VoidCallback onRetry,
    required BuildContext context,
    String title = '', // Sẽ được dịch trong l10n
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 60),
            const SizedBox(height: 16),
            Text(
              title.isEmpty ? l10n.errorLoadingData : title, // Dịch "Lỗi tải dữ liệu"
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry), // Dịch "Thử lại"
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildTransactionListItem({
    required BuildContext context,
    required TransactionModel transaction,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final iconData = _getTransactionIcon(transaction.type);
    final amountColor = getAmountColor(transaction.type, context);
    final formattedAmount = Formatter.formatCurrency(transaction.amount);
    final formattedDate = Formatter.formatDateTime(transaction.date);

    String subtitleText = formattedDate;
    if (transaction.type == l10n.expenseType && transaction.category.isNotEmpty) {
      subtitleText = '${transaction.category} • $formattedDate';
    } else if (transaction.type == l10n.transferType) {
      subtitleText = '${l10n.from}: ${transaction.fromWallet ?? '?'} → ${l10n.to}: ${transaction.toWallet ?? '?'} • $formattedDate';
    } else if (transaction.type == l10n.borrowType && transaction.lender != null && transaction.lender!.isNotEmpty) {
      subtitleText = '${l10n.borrowFrom}: ${transaction.lender} • $formattedDate';
    } else if (transaction.type == l10n.lendType && transaction.borrower != null && transaction.borrower!.isNotEmpty) {
      subtitleText = '${l10n.lendTo}: ${transaction.borrower} • $formattedDate';
    } else if ((transaction.type == l10n.incomeType ||
        transaction.type == l10n.balanceAdjustmentType ||
        transaction.type == l10n.borrowType ||
        transaction.type == l10n.lendType) &&
        transaction.wallet != null &&
        transaction.wallet!.isNotEmpty) {
      subtitleText = '${l10n.wallet}: ${transaction.wallet} • $formattedDate';
    } else {
      subtitleText = formattedDate;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: iconData['backgroundColor'].withAlpha(204),
                child: Icon(iconData['icon'], color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isNotEmpty
                          ? transaction.description
                          : l10n.noDescription, // Dịch "(Không có mô tả)"
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitleText,
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                getAmountPrefix(transaction.type, context) + formattedAmount,
                style: GoogleFonts.poppins(
                  color: amountColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Map<String, dynamic> _getTransactionIcon(String type) {
    switch (type) {
      case 'Thu nhập':
        return {'icon': Icons.arrow_downward, 'backgroundColor': Colors.green};
      case 'Chi tiêu':
        return {'icon': Icons.arrow_upward, 'backgroundColor': Colors.red};
      case 'Chuyển khoản':
        return {'icon': Icons.swap_horiz, 'backgroundColor': Colors.blue};
      case 'Đi vay':
        return {'icon': Icons.call_received, 'backgroundColor': Colors.purple};
      case 'Cho vay':
        return {'icon': Icons.call_made, 'backgroundColor': Colors.orange};
      case 'Điều chỉnh số dư':
        return {'icon': Icons.tune, 'backgroundColor': Colors.teal};
      default:
        return {'icon': Icons.help_outline, 'backgroundColor': Colors.grey};
    }
  }

  static Color getAmountColor(String type, BuildContext context,) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return AppTheme.incomeColor;
      case 'Chi tiêu':
      case 'Cho vay':
        return AppTheme.expenseColor;
      case 'Chuyển khoản':
      case 'Điều chỉnh số dư':
      default:
        return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8);
    }
  }

  static String getAmountPrefix(String type, BuildContext context,) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return '+ ';
      case 'Chi tiêu':
      case 'Cho vay':
        return '- ';
      default:
        return '';
    }
  }
}