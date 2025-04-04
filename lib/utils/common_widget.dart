import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // Apply formatter
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
        // Add currency symbol
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
                    color: AppTheme.lightTheme.colorScheme.onSurface.withValues(
                      alpha: 0.6,
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

  static Widget buildAppBar({
    required BuildContext context,
    required bool isSearching,
    required TextEditingController searchController,
    required VoidCallback onBackPressed,
    required VoidCallback onSearchPressed,
  }) {
    return Column(
      children: [
        _buildSafeArea(context),
        _buildHeader(
          context: context,
          isSearching: isSearching,
          searchController: searchController,
          onBackPressed: onBackPressed,
          onSearchPressed: onSearchPressed,
        ),
      ],
    );
  }

  static Widget _buildSafeArea(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  static Widget _buildHeader({
    required BuildContext context,
    required bool isSearching,
    required TextEditingController searchController,
    required VoidCallback onBackPressed,
    required VoidCallback onSearchPressed,
  }) {
    return Container(
      color: AppTheme.lightTheme.colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
            onPressed: onBackPressed,
          ),
          isSearching
              ? Expanded(
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                hintStyle: GoogleFonts.poppins(
                  color: AppTheme.lightTheme.colorScheme.surface.withValues(alpha: 0.6),
                ),
                border: InputBorder.none,
              ),
              style: GoogleFonts.poppins(
                color: AppTheme.lightTheme.colorScheme.surface,
              ),
              cursorColor: AppTheme.lightTheme.colorScheme.surface,
            ),
          )
              : Text(
            'Tài khoản',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
          ),
          IconButton(
            icon: Icon(
              isSearching ? Icons.close : Icons.search,
              color: AppTheme.lightTheme.colorScheme.surface,
            ),
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
}
