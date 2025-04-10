import 'dart:ui';

import 'package:finance_app/core/app_theme.dart'; // Vẫn cần cho income/expense color
import 'package:finance_app/data/models/transaction.dart';
// import 'package:finance_app/utils/dimens.dart'; // Dimens không được dùng trong file này
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CommonWidgets {
  // Giữ nguyên Builder vì lấy l10n cho validator
  static Widget buildEmailField({
    required TextEditingController controller,
    void Function(String)? onChanged,
  }) {
    return Builder(
      builder: (context) { // context này hợp lệ
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context); // Lấy theme từ context hợp lệ
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.emailLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8), // Dùng theme
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor)),
                ],
              ),
            ),
            hintText: l10n.enterEmailHint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
            focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
            errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          cursorColor: theme.colorScheme.primary, // Dùng theme
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          validator: (value) => Validators.validateEmail(value, l10n),
        );
      },
    );
  }

  // Giữ nguyên Builder vì lấy l10n cho validator
  static Widget buildPasswordField(
      TextEditingController controller,
      bool isPasswordVisible,
      VoidCallback toggleVisibility,
      ) {
    return Builder(
      builder: (context) { // context này hợp lệ
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context); // Lấy theme từ context hợp lệ
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.passwordLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8), // Dùng theme
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor)),
                ],
              ),
            ),
            hintText: l10n.enterPasswordHint,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
            focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
            errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            suffixIcon: IconButton(
              icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
              onPressed: toggleVisibility,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6), // Thêm màu cho icon
            ),
          ),
          cursorColor: theme.colorScheme.primary, // Dùng theme
          obscureText: !isPasswordVisible,
          validator: (value) => Validators.validatePassword(value, l10n),
        );
      },
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildSubmitButton(BuildContext context, String text, VoidCallback onPressed) {
    final theme = Theme.of(context); // Lấy theme
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary, // Dùng theme
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Thêm bo góc
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins( // Dùng GoogleFonts
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onPrimary, // Dùng theme
          ),
        ),
      ),
    );
  }

  // Giữ nguyên Builder vì lấy l10n cho label/hint
  static Widget buildBalanceInputField(
      TextEditingController controller, {
        String? Function(String?)? validator,
      }) {
    return Builder(
      builder: (context) { // context này hợp lệ
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context); // Lấy theme từ context hợp lệ
        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [Formatter.currencyInputFormatter],
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.amountLabel,
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8), // Dùng theme
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor)),
                ],
              ),
            ),
            hintText: l10n.enterAmountHint,
            // Nên dùng NumberFormat để lấy currency symbol dựa trên locale
            // suffixText: NumberFormat.simpleCurrency(locale: Intl.getCurrentLocale()).currencySymbol,
            suffixText: '₫', // Hoặc giữ nguyên nếu chỉ dùng VND
            suffixStyle: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface, // Dùng theme
              fontSize: 16,
            ),
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
            focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
            errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
            focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
            errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
          cursorColor: theme.colorScheme.primary, // Dùng theme
          style: GoogleFonts.poppins(
            color: theme.colorScheme.onSurface, // Dùng theme
            fontSize: 16,
          ),
          validator: validator,
        );
      },
    );
  }

  // context đã được yêu cầu
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: formFields),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
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
              style: GoogleFonts.poppins(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // context đã được yêu cầu
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
        ),
        content: Text(
          content,
          style: GoogleFonts.poppins(fontSize: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              l10n.cancel,
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              onDeletePressed();
            },
            child: Text(
              l10n.confirm,
              style: GoogleFonts.poppins(color: theme.colorScheme.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // context đã được yêu cầu
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    String title = '',
    Widget? titleWidget,
    VoidCallback? onBackPressed,
    bool showBackButton = true,
    IconData? backIcon,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    // Bỏ các tham số dropdown
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final effectiveBackgroundColor = backgroundColor ?? theme.colorScheme.primary;
    final effectiveForegroundColor = foregroundColor ?? theme.colorScheme.onPrimary;
    final effectiveTitle = title.isEmpty ? l10n.appTitle : title; // Sử dụng appTitle làm mặc định

    return AppBar(
      backgroundColor: effectiveBackgroundColor,
      foregroundColor: effectiveForegroundColor,
      elevation: elevation ?? 1.0,
      scrolledUnderElevation: 1.0, // Thêm để có hiệu ứng đổ bóng nhẹ khi cuộn dưới
      leading: showBackButton
          ? IconButton(
        icon: Icon(backIcon ?? Icons.arrow_back),
        tooltip: l10n.backTooltip,
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      )
          : null,
      title: titleWidget ?? Text(
        effectiveTitle, // Sử dụng tiêu đề hiệu quả
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: actions,
      bottom: bottom,
    );
  }

  // --- Các hàm _buildSafeArea, _buildHeader không cần thiết nữa ---

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildSocialLoginButton({
    required BuildContext context, // Thêm context
    required VoidCallback onPressed,
    required Color? color,
    required String text, // Chữ cái
    Color? textColor,
  }) {
    final theme = Theme.of(context); // Lấy theme
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
          elevation: 2,
          backgroundColor: color ?? theme.colorScheme.surface, // Nền là surface
          foregroundColor: textColor ?? theme.colorScheme.primary, // Chữ/Icon là primary
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor ?? theme.colorScheme.primary, // Màu chữ
          ),
        ),
      ),
    );
  }

  // context đã được yêu cầu
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
    final theme = Theme.of(context);
    return PreferredSize(
      preferredSize: const Size.fromHeight(kTextTabBarHeight),
      child: Material(
        color: backgroundColor ?? theme.colorScheme.surface, // Dùng theme
        // elevation: 1, // Bỏ elevation ở đây nếu AppBar đã có
        child: TabBar(
          controller: controller,
          labelStyle: labelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: unselectedLabelStyle ?? GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          labelColor: labelColor ?? theme.colorScheme.primary, // Dùng theme
          unselectedLabelColor: unselectedLabelColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.7), // Dùng theme
          indicatorColor: indicatorColor ?? theme.colorScheme.primary, // Dùng theme
          indicatorWeight: 2.5,
          onTap: onTabChanged,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          tabAlignment: TabAlignment.fill,
          dividerColor: theme.dividerColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // context đã được yêu cầu
  static Widget buildTabContent<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(BuildContext context, T item, int index) itemBuilder,
    required void Function(int oldIndex, int newIndex) onReorder,
    // Bỏ các tham số không cần thiết
  }) {
    // final l10n = AppLocalizations.of(context)!; // Không cần l10n
    // Việc kiểm tra empty xử lý bên ngoài

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
      onReorder: (oldIndex, newIndex) {
        if (oldIndex < newIndex) newIndex -= 1;
        if (oldIndex >= 0 && oldIndex < items.length && newIndex >= 0 && newIndex < items.length) {
          onReorder(oldIndex, newIndex);
        } else {
          debugPrint("ReorderableListView: Invalid indices ($oldIndex, $newIndex) for list length ${items.length}");
        }
      },
      proxyDecorator: (Widget child, int index, Animation<double> animation) {
        final theme = Theme.of(context); // Lấy theme
        return AnimatedBuilder(
          animation: animation,
          builder: (BuildContext context, Widget? _) {
            final double elevation = lerpDouble(1.0, 6.0, animation.value)!;
            return Material(
              borderRadius: BorderRadius.circular(10),
              elevation: elevation,
              color: theme.colorScheme.surface, // Dùng theme
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3), // Dùng theme
              child: child,
            );
          },
          child: child,
        );
      },
    );
  }

  // context đã được yêu cầu
  static Widget buildItemCard<T>({
    required BuildContext context,
    required T item,
    required Key itemKey,
    required String title,
    double? value,
    IconData? icon,
    Color? iconColor,
    Color? amountColor, // Thêm tham số amountColor
    String? valuePrefix,
    String? valueLocale,
    List<PopupMenuItem<String>>? menuItems,
    void Function(String)? onMenuSelected,
    Widget? subtitle,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    final locale = valueLocale ?? Intl.getCurrentLocale();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return Container(
      key: itemKey,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.cardColor,
        borderRadius: BorderRadius.circular(10), // Giả sử bạn dùng boxDecoration với radius 10
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 2),
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
                    style: GoogleFonts.poppins(
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
                    Text(valuePrefix.toString() +
                      NumberFormat.currency(locale: locale, symbol: currencySymbol, decimalDigits: 0).format(value),
                      style: GoogleFonts.poppins(
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                color: theme.colorScheme.surfaceContainerHighest,
                elevation: 4,
                onSelected: onMenuSelected,
                itemBuilder: (context) => menuItems,
              ),
          ],
        ),
      ),
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static BoxDecoration boxDecoration(BuildContext context) {
    final theme = Theme.of(context);
    return BoxDecoration(
      color: theme.cardColor, // Dùng theme cardColor
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: 10, offset: const Offset(0, 3), // Giảm offset Y
        ),
      ],
      // Bỏ border ở đây để linh hoạt hơn, có thể thêm ở nơi gọi hoặc trong buildItemCard
      // border: Border.all(...)
    );
  }

  // context đã được yêu cầu
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.colorScheme.surface,
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          title.isEmpty ? l10n.selectIconTitle : title, // l10n
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.primary), // theme
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(dialogContext).size.height * dialogHeightFactor,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.0,
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
                      color: isSelected ? effectiveSelectedColor.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? effectiveSelectedColor : theme.dividerColor, width: isSelected ? 1.5 : 1.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconData, color: effectiveSelectedColor, size: iconSize),
                        const SizedBox(height: 4),
                        Text(
                          iconName,
                          style: GoogleFonts.poppins(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400), // theme
                          textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
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
            child: Text(l10n.cancel, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500)), // l10n, theme
          ),
        ],
      ),
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static List<PopupMenuItem<String>> buildEditDeleteMenuItems({
    required BuildContext context, // Thêm context
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
            Icon(editIcon, size: 20, color: editIconColor ?? theme.colorScheme.primary), // theme
            const SizedBox(width: 12),
            Text(editText.isEmpty ? l10n.edit : editText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)), // l10n, theme
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            Icon(deleteIcon, size: 20, color: deleteIconColor ?? theme.colorScheme.error), // theme
            const SizedBox(width: 12),
            Text(deleteText.isEmpty ? l10n.delete : deleteText, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)), // l10n, theme
          ],
        ),
      ),
    ];
  }

  // context đã được yêu cầu
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
      showDeleteDialog(
        context: context,
        title: l10n.confirmDeleteTitle, // l10n
        content: l10n.confirmDeleteContent(itemName), // l10n placeholder
        onDeletePressed: () => onDelete(context, item),
      );
    }
  }

  // context đã được yêu cầu
  static Widget buildSearchField({
    required BuildContext context,
    required String hintText,
    required Function(String) onChanged,
    TextEditingController? controller,
    FocusNode? focusNode,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: boxDecoration(context).copyWith(borderRadius: BorderRadius.circular(30)), // Dùng boxDecoration
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(fontSize: 15, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)), // theme
          prefixIcon: Icon(Icons.search, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), size: 22), // theme
          border: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
        style: GoogleFonts.poppins(fontSize: 15, color: theme.colorScheme.onSurface), // theme
        cursorColor: theme.colorScheme.primary, // theme
        onChanged: onChanged,
      ),
    );
  }

  // Giữ Builder vì cần l10n cho validator nếu có
  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int? maxLines = 1,
    FocusNode? focusNode,
    bool isRequired = true,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      // final l10n = AppLocalizations.of(context)!; // Chỉ lấy nếu validator cần

      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: maxLines,
        decoration: InputDecoration(
          label: isRequired ? RichText(
            text: TextSpan(
              text: '$label ',
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16),
              children: const [TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor))],
            ),
          ) : Text(label, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16)),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
          errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
          focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
          errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        ),
        cursorColor: theme.colorScheme.primary,
        style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 16),
        validator: validator,
      );
    });
  }

  // Giữ Builder vì cần l10n cho validator nếu có
  static Widget buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    String? hint,
    bool isRequired = true,
  }) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final l10n = AppLocalizations.of(context)!;

      return DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          label: isRequired ? RichText(
            text: TextSpan(
              text: '$label ',
              style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16),
              children: const [TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor))],
            ),
          ) : Text(label, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16)),
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5)),
          errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
          focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
          errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12).copyWith(right: 0),
        ),
        style: GoogleFonts.poppins(color: theme.colorScheme.onSurface, fontSize: 16),
        dropdownColor: theme.colorScheme.surfaceContainerHighest,
        iconEnabledColor: theme.colorScheme.onSurfaceVariant,
        validator: validator ?? (value) {
          if (isRequired && value == null) return l10n.selectValueError;
          return null;
        },
        isExpanded: true,
        alignment: AlignmentDirectional.centerStart,
      );
    });
  }

  // context đã được yêu cầu
  static Widget buildDatePickerField({
    required BuildContext context,
    required DateTime? date,
    required String label,
    required ValueChanged<DateTime?> onTap,
    String? errorText,
    DateTime? firstDate,
    DateTime? lastDate,
    bool isRequired = true,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayFormat = DateFormat('dd/MM/yyyy');

    Future<void> handleTap() async {
      final DateTime? picked = await showDatePicker(
        context: context, initialDate: date ?? DateTime.now(),
        firstDate: firstDate ?? DateTime(2000), lastDate: lastDate ?? DateTime(2101),
        builder: (context, child) => Theme(
          data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(primary: theme.colorScheme.primary, onPrimary: theme.colorScheme.onPrimary, surface: theme.colorScheme.surface, onSurface: theme.colorScheme.onSurface),
              textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary)), dialogTheme: DialogThemeData(backgroundColor: theme.colorScheme.surface)),
          child: child!,
        ),
      );
      onTap(picked);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0),
          child: isRequired ? RichText(
            text: TextSpan(
              text: '$label ', style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16),
              children: const [TextSpan(text: '*', style: TextStyle(color: AppTheme.expenseColor))],
            ),
          ) : Text(label, style: GoogleFonts.poppins(color: theme.colorScheme.onSurface.withValues(alpha: 0.8), fontSize: 16)),
        ),
        InkWell(
          onTap: handleTap, borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(width: 1)),
              enabledBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
              focusedBorder: OutlineInputBorder(borderRadius: const BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: theme.dividerColor, width: 1)),
              errorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1)),
              focusedErrorBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8)), borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5)),
              errorText: errorText, errorStyle: const TextStyle(color: AppTheme.expenseColor, fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              suffixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ),
            child: Text(
              date != null ? displayFormat.format(date) : l10n.notSelected, // l10n
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: date != null ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withValues(alpha: 0.5), // theme
              ),
            ),
          ),
        ),
      ],
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildCategoryChips({
    required BuildContext context, // Thêm context
    required List<String> categories,
    required String selectedCategory,
    required ValueChanged<String> onCategorySelected,
    String? title,
  }) {
    // final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface.withValues(alpha: 0.8))),
          ),
        Wrap(
          spacing: 8.0, runSpacing: 4.0,
          children: categories.map((category) {
            final bool isSelected = selectedCategory == category;
            return ChoiceChip(
              label: Text(category),
              labelStyle: GoogleFonts.poppins(fontSize: 13, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.8)), // theme
              selected: isSelected,
              onSelected: (bool selected) { if (selected) onCategorySelected(category); },
              selectedColor: theme.colorScheme.primary.withValues(alpha: 0.12), // theme
              backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5), // theme
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.dividerColor, width: isSelected ? 1.0 : 0.8)), // theme
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildLabel({required BuildContext context, required String text}) { // Thêm context
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8))), // theme
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildLoadingIndicator({required BuildContext context, Color? color, double size = 40.0}) { // Thêm context
    return Center(
      child: SpinKitFadingCircle(
        color: color ?? Theme.of(context).colorScheme.primary, // theme
        size: size,
      ),
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildEmptyState({
    required BuildContext context, // Thêm context
    required String message,
    String? suggestion,
    IconData icon = Icons.inbox_outlined,
    double iconSize = 60,
    VoidCallback? onActionPressed,
    String? actionText,
    IconData? actionIcon,
  }) {
    final theme = Theme.of(context); // Lấy theme
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: iconSize, color: theme.disabledColor), // theme
            const SizedBox(height: 20),
            Text(message, style: GoogleFonts.poppins(fontSize: 17, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)), textAlign: TextAlign.center), // theme
            if (suggestion != null) ...[
              const SizedBox(height: 10),
              Text(suggestion, style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor), textAlign: TextAlign.center), // theme
            ],
            if (onActionPressed != null && actionText != null) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: actionIcon != null ? Icon(actionIcon, size: 18) : const SizedBox.shrink(),
                label: Text(actionText),
                onPressed: onActionPressed,
                style: ElevatedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onPrimary, // theme
                  backgroundColor: theme.colorScheme.primary, // theme
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // *** SỬA: Thêm BuildContext context ***
  static Widget buildErrorState({
    required BuildContext context, // Thêm context
    required String message,
    required VoidCallback onRetry,
    String title = '',
    IconData icon = Icons.error_outline_rounded,
    Color iconColor = AppTheme.expenseColor, // Giữ màu đỏ
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final effectiveTitle = title.isEmpty ? l10n.errorLoadingData : title; // l10n

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 50),
            const SizedBox(height: 16),
            Text(effectiveTitle, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: iconColor), textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 14, color: theme.hintColor)), // theme
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.retry), // l10n
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary, // theme
                backgroundColor: theme.colorScheme.primary, // theme
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // context đã được yêu cầu
  static Widget buildTransactionListItem({
    required BuildContext context,
    required TransactionModel transaction,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // !! Logic icon/màu/prefix cần dựa trên type gốc !!
    final iconData = getTransactionIcon(transaction.type); // Dùng type gốc
    final amountColor = getAmountColor(context, transaction.type); // Dùng type gốc
    final amountPrefix = getAmountPrefix(context, transaction.type); // Dùng type gốc

    final formattedAmount = Formatter.formatCurrency(transaction.amount);
    final formattedTime = Formatter.formatTime(transaction.date);

    // --- Subtitle ---
    String subtitleText = '$formattedTime • ${transaction.wallet ?? ''}';
    // !! So sánh type gốc !!
    if (transaction.type == 'expense' && transaction.category.isNotEmpty) { subtitleText = '$formattedTime • ${transaction.category}'; }
    else if (transaction.type == 'transfer') { subtitleText = '$formattedTime • ${l10n.from}: ${transaction.fromWallet ?? '?'} → ${l10n.to}: ${transaction.toWallet ?? '?'}'; }
    else if (transaction.type == 'borrow' && transaction.lender != null) { subtitleText = '$formattedTime • ${l10n.borrowFrom}: ${transaction.lender}'; }
    else if (transaction.type == 'lend' && transaction.borrower != null) { subtitleText = '$formattedTime • ${l10n.lendTo}: ${transaction.borrower}'; }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 3.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.5), width: 1.5)),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap, onLongPress: onLongPress, borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              CircleAvatar(radius: 18, backgroundColor: iconData['backgroundColor']?.withValues(alpha: 0.15) ?? theme.colorScheme.primary.withValues(alpha: 0.15), child: Icon(iconData['icon'], color: iconData['backgroundColor'] ?? theme.colorScheme.primary, size: 18)),
              const SizedBox(width: 12),
              Expanded(
                child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(transaction.description.isNotEmpty ? transaction.description : l10n.noDescription, style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14.5, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis), // theme
                  const SizedBox(height: 3),
                  Text(subtitleText, style: GoogleFonts.poppins(color: theme.hintColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis), // theme
                ],
                ),
              ),
              const SizedBox(width: 8),
              Text(amountPrefix + formattedAmount, style: GoogleFonts.poppins(color: amountColor, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.end),
            ],
          ),
        ),
      ),
    );
  }

  // --- Các hàm helper nội bộ (Giữ nguyên logic key gốc) ---
  static Map<String, dynamic> getTransactionIcon(String typeKey) {
    switch (typeKey) {
      case 'income': return {'icon': Icons.arrow_downward, 'backgroundColor': Colors.green};
      case 'expense': return {'icon': Icons.arrow_upward, 'backgroundColor': Colors.red};
      case 'transfer': return {'icon': Icons.swap_horiz, 'backgroundColor': Colors.blue};
      case 'borrow': return {'icon': Icons.call_received, 'backgroundColor': Colors.purple};
      case 'lend': return {'icon': Icons.call_made, 'backgroundColor': Colors.orange};
      case 'adjustment': return {'icon': Icons.tune, 'backgroundColor': Colors.teal};
      default: return {'icon': Icons.help_outline, 'backgroundColor': Colors.grey};
    }
  }

  // Hàm hỗ trợ lấy màu dựa trên type (giữ nguyên từ code hiện tại của bạn)
  static Color getAmountColor(BuildContext context, String type) {
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return AppTheme.incomeColor;
      case 'Chi tiêu':
      case 'Cho vay':
      case 'Chuyển khoản':
        return AppTheme.expenseColor;
      case 'Điều chỉnh số dư':
        return Theme.of(context).colorScheme.onSurface; // Màu trung tính cho điều chỉnh
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  // Hàm hỗ trợ lấy prefix dựa trên type (giữ nguyên từ code hiện tại của bạn)
  static String getAmountPrefix(BuildContext context, String type) {
    switch (type) {
      case 'Thu nhập':
      case 'Đi vay':
        return '';
      case 'Chi tiêu':
      case 'Cho vay':
      case 'Chuyển khoản':
        return '-';
      case 'Điều chỉnh số dư':
        return '';
      default:
        return '';
    }
  }
}