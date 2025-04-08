import 'dart:ui';

import 'package:finance_app/core/app_routes.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/utils/dimens.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CommonWidgets {
  static Widget buildEmailField({
    required TextEditingController controller,
    void Function(String)? onChanged, // Thêm onChanged
  }) {
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
      onChanged: onChanged, // Sử dụng onChanged
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

  static Widget buildBalanceInputField(
    TextEditingController controller, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [Formatter.currencyInputFormatter],
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: 'Số tiền ',
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
        hintText: 'Nhập số tiền',
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
      validator: validator,
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
      builder: (context) => AlertDialog(
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
                color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
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
              'Xác nhận',
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
    String title = 'Tài khoản', // Tiêu đề mặc định
    VoidCallback? onBackPressed, // Callback cho nút back (tùy chọn)
    bool showBackButton = true, // Hiển thị nút back hay không
    IconData? backIcon, // Icon tùy chỉnh cho nút back (mặc định là arrow_back)
    List<Widget>? actions, // Danh sách các nút hành động tùy chỉnh
    bool showDropdown = false, // Hiển thị dropdown thay vì tiêu đề text
    List<String>? dropdownItems, // Danh sách các mục trong dropdown
    String? dropdownValue, // Giá trị hiện tại của dropdown
    ValueChanged<String?>? onDropdownChanged, // Callback khi dropdown thay đổi
  }) {
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
            title: title,
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
      color: AppTheme.lightTheme.colorScheme.primary,
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
    return Container(
      height: kToolbarHeight,
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Nút Back (tùy chọn)
          showBackButton
              ? IconButton(
                icon: Icon(
                  backIcon ??
                      Icons.arrow_back, // Dùng icon tùy chỉnh hoặc mặc định
                  color: AppTheme.lightTheme.colorScheme.surface,
                ),
                tooltip: 'Quay lại',
                onPressed: onBackPressed ?? () => Navigator.pop(context),
              )
              : const SizedBox(width: 48),
          // Giữ khoảng trống nếu không có nút back
          // Tiêu đề hoặc Dropdown
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child:
                  showDropdown &&
                          dropdownItems != null &&
                          dropdownValue != null &&
                          onDropdownChanged != null
                      ? DropdownButtonFormField<String>(
                        value: dropdownValue,
                        onChanged: onDropdownChanged,
                        items:
                            dropdownItems.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: GoogleFonts.poppins(
                                    fontSize: Dimens.textSizeMedium + 2, // 18
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppTheme.lightTheme.colorScheme.surface,
                                  ),
                                ),
                              );
                            }).toList(),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: InputBorder.none,
                          // Không cần border vì ở trong app bar
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: Dimens.textSizeMedium + 2, // 18
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.surface,
                        ),
                        dropdownColor: AppTheme.lightTheme.colorScheme.primary,
                        iconEnabledColor:
                            AppTheme.lightTheme.colorScheme.surface,
                        iconSize: 24,
                      )
                      : Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: Dimens.textSizeMedium + 2, // 18
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.surface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
            ),
          ),
          // Actions (tùy chọn)
          Row(
            mainAxisSize: MainAxisSize.min,
            children:
                actions ??
                [
                  const SizedBox(width: 48),
                ], // Giữ khoảng trống nếu không có actions
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

  static PreferredSizeWidget buildTabBar({
    required BuildContext context,
    required List<String> tabTitles,
    required Function(int) onTabChanged,
    TabController? controller, // Thêm controller vào đây
    TextStyle? labelStyle,
    TextStyle? unselectedLabelStyle,
    Color? labelColor,
    Color? unselectedLabelColor,
    Color? indicatorColor,
    Color? backgroundColor, // Màu nền cho vùng TabBar (tùy chọn)
  }) {
    return PreferredSize(
      // Chiều cao tiêu chuẩn cho TabBar
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material( // Bọc trong Material để có thể set màu nền
        color: backgroundColor ?? AppTheme.lightTheme.colorScheme.surface, // Màu nền
        // elevation: 1, // Có thể thêm elevation nếu muốn
        child: TabBar(
          controller: controller, // Gán controller
          labelStyle: labelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: unselectedLabelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          labelColor: labelColor ?? AppTheme.lightTheme.colorScheme.primary,
          unselectedLabelColor: unselectedLabelColor ?? AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: indicatorColor ?? AppTheme.lightTheme.colorScheme.primary,
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
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 204,
            ),
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
      decoration: boxDecoration().copyWith(color: backgroundColor),
      child: Padding(
        padding: padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                        color:
                            value >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
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

  static BoxDecoration boxDecoration() {
    return BoxDecoration(
      color: AppTheme.lightTheme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.25),
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
                                    .withValues(alpha: 38)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isSelected
                                  ? (selectedColor ??
                                      AppTheme.lightTheme.colorScheme.primary)
                                  : AppTheme.lightTheme.colorScheme.onSurface
                                      .withValues(alpha: 51),
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
                                    .withValues(alpha: 204),
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
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 204,
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

  static Widget buildSearchField({
    required BuildContext context,
    required String hintText,
    required Function(String) onChanged,
    String? initialValue,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow.withValues(
              alpha: 0.25,
            ),
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
            color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppTheme.lightTheme.colorScheme.primary,
            size: 24,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.lightTheme.colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.lightTheme.colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        style: GoogleFonts.poppins(
          fontSize: Dimens.textSizeMedium,
          color: AppTheme.lightTheme.colorScheme.onSurface,
        ),
        cursorColor: AppTheme.lightTheme.colorScheme.primary,
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: '$label ',
            style: GoogleFonts.poppins(
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
          color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
            alpha: 0.6,
          ),
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
      validator: validator,
    );
  }

  static Widget buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items:
          items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.poppins(
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            );
          }).toList(),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: '$label ',
            style: GoogleFonts.poppins(
              color: AppTheme.lightTheme.colorScheme.onSurface,
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
      style: GoogleFonts.poppins(
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
      dropdownColor: AppTheme.lightTheme.colorScheme.surface,
      iconEnabledColor: AppTheme.lightTheme.colorScheme.onSurface,
      validator: validator,
    );
  }

  static Widget buildDatePickerField({
    required BuildContext context,
    required DateTime? date,
    required String label,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            // Sửa: Xử lý date có thể null
            '$label: ${date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Chưa chọn'}',
            style: GoogleFonts.poppins(
              fontSize: Dimens.textSizeMedium,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.calendar_today,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          onTap: onTap,
          // Thêm nút xóa nếu cần (ví dụ cho ngày hẹn trả)
          // leading: allowClear && date != null ? IconButton(...) : null,
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12),
            // Thêm padding trái
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh mục yêu thích',
          style: GoogleFonts.poppins(
            fontSize: Dimens.textSizeMedium,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children:
              categories.map((category) {
                return ChoiceChip(
                  label: Text(
                    category,
                    style: GoogleFonts.poppins(
                      color:
                          selectedCategory == category
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  selected: selectedCategory == category,
                  onSelected: (bool selected) {
                    if (selected) {
                      onCategorySelected(category);
                    }
                  },
                  selectedColor: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.1),
                  backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                  side: BorderSide(
                    color:
                        selectedCategory == category
                            ? AppTheme.lightTheme.colorScheme.primary
                            : AppTheme.lightTheme.colorScheme.onSurface
                                .withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  static Widget buildLabel({required String text}) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: Dimens.textSizeMedium,
        color: AppTheme.lightTheme.colorScheme.onSurface,
      ),
    );
  }

  static Widget buildLoadingIndicator({Color? color, double size = 50.0}) {
    return Center(
      child: SpinKitFadingCircle(
        color: color ?? AppTheme.lightTheme.colorScheme.primary,
        size: size,
      ),
    );
  }

  static Widget buildEmptyState({
    required String message,
    String? suggestion,
    IconData icon = Icons.receipt_long_outlined, // Icon mặc định
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
                icon:
                    actionIcon != null
                        ? Icon(actionIcon)
                        : const SizedBox.shrink(),
                label: Text(actionText),
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                  backgroundColor:
                      AppTheme.lightTheme.colorScheme.primary, // Màu nút
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
    String title = 'Lỗi tải dữ liệu',
    IconData icon = Icons.error_outline,
    Color iconColor = Colors.red,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 60),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message, // Hiển thị thông báo lỗi cụ thể từ state
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.grey[700]),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                foregroundColor: AppTheme.lightTheme.colorScheme.onPrimary,
                backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget để hiển thị một item giao dịch trong danh sách.
  static Widget buildTransactionListItem({
    required BuildContext context,
    required TransactionModel transaction,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final iconData = _getTransactionIcon(
      transaction.type,
    ); // Gọi helper nội bộ (hoặc static)
    final amountColor = getAmountColor(transaction.type);
    final formattedAmount = Formatter.formatCurrency(transaction.amount);
    final formattedDate = Formatter.formatDateTime(transaction.date);

    // Xây dựng subtitle
    String subtitleText = formattedDate;
    if (transaction.type == 'Chi tiêu' && transaction.category.isNotEmpty) {
      subtitleText = '${transaction.category} • $formattedDate'; // Dùng dấu •
    } else if (transaction.type == 'Chuyển khoản') {
      subtitleText =
          'Từ: ${transaction.fromWallet ?? '?'} → Đến: ${transaction.toWallet ?? '?'} • $formattedDate';
    } else if (transaction.type == 'Đi vay' &&
        transaction.lender != null &&
        transaction.lender!.isNotEmpty) {
      subtitleText = 'Vay từ: ${transaction.lender} • $formattedDate';
    } else if (transaction.type == 'Cho vay' &&
        transaction.borrower != null &&
        transaction.borrower!.isNotEmpty) {
      subtitleText = 'Cho vay: ${transaction.borrower} • $formattedDate';
    } else if ((transaction.type == 'Thu nhập' ||
            transaction.type == 'Điều chỉnh số dư' ||
            transaction.type == 'Đi vay' ||
            transaction.type == 'Cho vay') &&
        transaction.wallet != null &&
        transaction.wallet!.isNotEmpty) {
      // Hiển thị ví cho các loại giao dịch đơn lẻ (nếu có)
      subtitleText = 'Ví: ${transaction.wallet} • $formattedDate';
    }
    // Chỉ hiển thị ngày nếu không có thông tin nào khác
    else {
      subtitleText = formattedDate;
    }

    return Card(
      // key: ValueKey(transaction.id), // Key quan trọng cho ReorderableListView nếu dùng
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      // Bo góc nhẹ
      child: InkWell(
        // Thêm InkWell để có hiệu ứng khi nhấn
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // Icon
              CircleAvatar(
                radius: 18, // Kích thước nhỏ hơn chút
                backgroundColor: iconData.backgroundColor.withValues(
                  alpha: 0.8,
                ),
                child: Icon(iconData.icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              // Thông tin chính
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description.isNotEmpty
                          ? transaction.description
                          : '(Không có mô tả)',
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
                      // Cho phép 2 dòng cho subtitle dài (như chuyển khoản)
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Số tiền
              Text(
                // Thêm dấu +/- cho rõ ràng (trừ Thu nhập, Điều chỉnh)
                getAmountPrefix(transaction.type) + formattedAmount,
                style: GoogleFonts.poppins(
                  color: amountColor,
                  fontWeight: FontWeight.w600, // Đậm hơn
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

  // --- Helpers nội bộ cho buildTransactionListItem ---
  // (Có thể chuyển thành static nếu muốn)

  static ({IconData icon, Color backgroundColor}) _getTransactionIcon(
    String type,
  ) {
    // ... (Giữ nguyên logic của bạn) ...
    switch (type) {
      case 'Thu nhập':
        return (icon: Icons.arrow_downward, backgroundColor: Colors.green);
      case 'Chi tiêu':
        return (icon: Icons.arrow_upward, backgroundColor: Colors.red);
      case 'Chuyển khoản':
        return (icon: Icons.swap_horiz, backgroundColor: Colors.blue);
      case 'Đi vay':
        return (icon: Icons.call_received, backgroundColor: Colors.purple);
      case 'Cho vay':
        return (icon: Icons.call_made, backgroundColor: Colors.orange);
      case 'Điều chỉnh số dư':
        return (icon: Icons.tune, backgroundColor: Colors.teal);
      default:
        return (icon: Icons.help_outline, backgroundColor: Colors.grey);
    }
  }

  static Color getAmountColor(String type) {
    // ... (Giữ nguyên logic của bạn) ...
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return AppTheme.incomeColor; // Dùng màu theme
      case 'Chi tiêu':
      case 'Cho vay':
        return AppTheme.expenseColor; // Dùng màu theme
      case 'Chuyển khoản':
      case 'Điều chỉnh số dư':
      default:
        return AppTheme.lightTheme.colorScheme.onSurface.withValues(
          alpha: 0.8,
        ); // Màu trung tính
    }
  }

  static String getAmountPrefix(String type) {
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return '+ ';
      case 'Chi tiêu':
      case 'Cho vay':
        return '- ';
      default:
        return ''; // Chuyển khoản, điều chỉnh không cần dấu
    }
  }
}
