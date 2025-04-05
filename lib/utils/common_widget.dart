import 'dart:ui';

import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/dimens.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CommonWidgets {
  static Widget buildEmailField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'Email ',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
        hintText: 'Nhập email',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.primary,
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
      cursorColor: AppTheme.lightTheme.colorScheme.primary,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.validateEmail,
    );
  }

  static Widget buildPasswordField(
    TextEditingController controller,
    bool isPasswordVisible,
    VoidCallback toggleVisibility,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'Mật khẩu ',
            style: TextStyle(
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
        hintText: 'Nhập mật khẩu',
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.primary,
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
      cursorColor: AppTheme.lightTheme.colorScheme.primary,
      obscureText: !isPasswordVisible,
      validator: Validators.validatePassword,
    );
  }

  static Widget buildSubmitButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: AppTheme.lightTheme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  static Widget buildBalanceInputField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [Formatter.currencyInputFormatter],
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'Số dư ',
            style: GoogleFonts.poppins(
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
        hintText: 'Nhập số dư',
        suffixText: '₫',
        suffixStyle: GoogleFonts.poppins(
          color: AppTheme.lightTheme.colorScheme.onSurface,
          fontSize: 16,
        ),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: AppTheme.lightTheme.colorScheme.primary,
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
      cursorColor: AppTheme.lightTheme.colorScheme.primary,
      style: GoogleFonts.poppins(
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
      validator: Validators.validateBalance,
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
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
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
                  'Hủy',
                  style: GoogleFonts.poppins(
                    color: AppTheme.lightTheme.colorScheme.onSurface,
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
                    color: AppTheme.lightTheme.colorScheme.primary,
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
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
            content: Text(
              content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Hủy',
                  style: GoogleFonts.poppins(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(
                      153,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  onDeletePressed();
                  Navigator.pop(context);
                },
                child: Text(
                  'Xóa',
                  style: GoogleFonts.poppins(
                    color: AppTheme.lightTheme.colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required bool isSearching,
    required TextEditingController searchController,
    required VoidCallback onBackPressed,
    required VoidCallback onSearchPressed,
    ValueChanged<String>? onSearchTextChanged,
    String title = 'Tài khoản',
  }) {
    return PreferredSize(
      preferredSize: Size.fromHeight(
        kToolbarHeight + MediaQuery.of(context).padding.top,
      ),
      child: Column(
        children: [
          _buildSafeArea(context),
          _buildHeader(
            context: context,
            isSearching: isSearching,
            searchController: searchController,
            onBackPressed: onBackPressed,
            onSearchPressed: onSearchPressed,
            onSearchTextChanged: onSearchTextChanged,
            title: title,
          ),
        ],
      ),
    );
  }

  static Widget _buildSafeArea(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: AppTheme.lightTheme.colorScheme.primary,
    );
  }

  static Widget _buildHeader({
    required BuildContext context,
    required bool isSearching,
    required TextEditingController searchController,
    required VoidCallback onBackPressed,
    required VoidCallback onSearchPressed,
    ValueChanged<String>? onSearchTextChanged,
    required String title,
  }) {
    return Container(
      height: kToolbarHeight,
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              isSearching && searchController.text.isNotEmpty
                  ? Icons.clear
                  : Icons.arrow_back,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
            tooltip:
                isSearching && searchController.text.isNotEmpty
                    ? 'Xóa tìm kiếm'
                    : 'Quay lại',
            onPressed: () {
              if (isSearching && searchController.text.isNotEmpty) {
                searchController.clear();
                onSearchTextChanged?.call('');
              } else {
                onBackPressed();
              }
            },
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child:
                  isSearching
                      ? Container(
                        key: const ValueKey('searchField'),
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm ví...',
                            hintStyle: GoogleFonts.poppins(
                              color: AppTheme.lightTheme.colorScheme.surface
                                  .withAlpha(179),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.poppins(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            fontSize: 16,
                          ),
                          cursorColor: AppTheme.lightTheme.colorScheme.surface,
                          onChanged: onSearchTextChanged,
                        ),
                      )
                      : Container(
                        key: const ValueKey('title'),
                        alignment: Alignment.center,
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.surface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
            ),
          ),
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
            tooltip: isSearching ? 'Đóng tìm kiếm' : 'Tìm kiếm',
            onPressed: onSearchPressed,
          ),
        ],
      ),
    );
  }

  static Widget buildSocialLoginButton({
    required VoidCallback onPressed,
    required Color? color,
    required String text,
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
          backgroundColor: color ?? AppTheme.lightTheme.colorScheme.primary,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            color: textColor ?? AppTheme.lightTheme.colorScheme.surface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Widget buildTabBar({
    required BuildContext context,
    required List<String> tabTitles,
    required Function(int) onTabChanged,
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? indicatorColor,
  }) {
    return TabBar(
      labelStyle:
          labelStyle ??
          GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          unselectedLabelStyle ??
          GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      labelColor: labelColor ?? AppTheme.lightTheme.colorScheme.primary,
      unselectedLabelColor:
          unselectedLabelColor ??
          AppTheme.lightTheme.colorScheme.onSurface.withAlpha(153),
      indicatorColor: indicatorColor ?? AppTheme.lightTheme.colorScheme.primary,
      onTap: onTabChanged,
      tabs: tabTitles.map((title) => Tab(text: title)).toList(),
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
    required Widget Function(BuildContext context, T item, int type, int index)
    itemBuilder,
    required void Function(int type, int oldIndex, int newIndex) onReorder,
  }) {
    final filteredItems = filterItems(searchQuery, items);

    if (filteredItems.isEmpty) {
      return Center(
        child: Text(
          isSearching ? 'Không tìm thấy mục phù hợp' : emptyMessage,
          style: GoogleFonts.poppins(
            fontSize: Dimens.textSizeMedium,
            color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(204),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 80),
      itemCount: filteredItems.length,
      itemBuilder:
          (context, index) =>
              itemBuilder(context, filteredItems[index], type, index),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex -= 1;
        if (oldIndex >= 0 &&
            oldIndex < filteredItems.length &&
            newIndex >= 0 &&
            newIndex <= filteredItems.length) {
          onReorder(type, oldIndex, newIndex);
        } else {
          debugPrint("Error: Reorder indices out of bounds.");
        }
      },
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final elevation =
                lerpDouble(0, 8, Curves.easeInOut.transform(animation.value))!;
            return Material(
              elevation: elevation,
              color: Colors.transparent,
              shadowColor: Colors.black.withAlpha(51),
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
    EdgeInsetsGeometry margin = const EdgeInsets.only(top: 16),
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      key: itemKey,
      margin: margin,
      decoration: _boxDecoration(),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: iconColor ?? AppTheme.lightTheme.colorScheme.primary,
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
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    NumberFormat.currency(
                      locale: valueLocale ?? 'vi_VN',
                      symbol: valuePrefix ?? '₫',
                    ).format(value),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color:
                          value >= 0
                              ? AppTheme.incomeColor
                              : AppTheme.expenseColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (menuItems != null && onMenuSelected != null)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(
                    153,
                  ),
                ),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: AppTheme.lightTheme.colorScheme.surface,
                elevation: 8,
                onSelected: onMenuSelected,
                itemBuilder: (context) => menuItems,
              ),
          ],
        ),
      ),
    );
  }

  static BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.lightTheme.colorScheme.shadow.withAlpha(25),
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
    String title = 'Chọn biểu tượng',
    double dialogHeightFactor = 0.3,
    int crossAxisCount = 3,
    double iconSize = 28,
    Color? selectedColor,
    Color? unselectedColor,
  }) async {
    return await showDialog<IconData>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: AppTheme.lightTheme.colorScheme.surface,
            title: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.primary,
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
                        color:
                            isSelected
                                ? (selectedColor ??
                                        AppTheme.lightTheme.colorScheme.primary)
                                    .withAlpha(38)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? (selectedColor ??
                                      AppTheme.lightTheme.colorScheme.primary)
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                      .withAlpha(51),
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
                              color:
                                  selectedColor ??
                                  AppTheme.lightTheme.colorScheme.primary,
                              size: iconSize,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconData['name'],
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppTheme.lightTheme.colorScheme.onSurface
                                    .withAlpha(204),
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
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Hủy',
                  style: GoogleFonts.poppins(
                    color: AppTheme.lightTheme.colorScheme.onSurface.withAlpha(
                      204,
                    ),
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
    String editText = 'Sửa',
    String deleteText = 'Xóa',
    Color? editIconColor,
    Color? deleteIconColor,
  }) {
    return [
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            Icon(
              editIcon,
              size: 20,
              color: editIconColor ?? AppTheme.lightTheme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              editText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface,
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
              color: deleteIconColor ?? AppTheme.lightTheme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Text(
              deleteText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.lightTheme.colorScheme.onSurface,
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
    if (action == 'edit') {
      onEdit(context, item);
    } else if (action == 'delete') {
      showDeleteDialog(
        context: context,
        title: 'Xác nhận xóa',
        content:
            'Bạn có chắc chắn muốn xóa "$itemName" không? Hành động này không thể hoàn tác.',
        onDeletePressed: () => onDelete(context, item),
      );
    }
  }
}
