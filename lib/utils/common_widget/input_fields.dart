import 'package:finance_app/core/app_theme.dart';
import 'package:finance_app/utils/formatter.dart';
import 'package:finance_app/utils/validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class InputFields {
  static Widget buildEmailField({
    required TextEditingController controller,
    void Function(String)? onChanged,
  }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.emailLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
            hintText: l10n.enterEmailHint,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.expenseColor,
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          cursorColor: theme.colorScheme.primary,
          keyboardType: TextInputType.emailAddress,
          onChanged: onChanged,
          validator: (value) => Validators.validateEmail(value, l10n),
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
        final theme = Theme.of(context);
        return TextFormField(
          controller: controller,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.passwordLabel,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
            hintText: l10n.enterPasswordHint,
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.expenseColor,
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: toggleVisibility,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          cursorColor: theme.colorScheme.primary,
          obscureText: !isPasswordVisible,
          validator: (value) => Validators.validatePassword(value, l10n),
        );
      },
    );
  }

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
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            label: isRequired
                ? RichText(
              text: TextSpan(
                text: '$label ',
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            )
                : Text(
              label,
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.expenseColor,
              fontSize: 11,
            ),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          cursorColor: theme.colorScheme.primary,
          style: GoogleFonts.poppins(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
          validator: validator,
        );
      },
    );
  }

  static String _getCurrencySymbol(Locale locale) {
    switch (locale.languageCode) {
      case 'vi':
        return '₫';
      case 'ja':
        return '¥';
      case 'en':
      default:
        return '\$';
    }
  }

  static Widget buildBalanceInputField(
      TextEditingController controller, {
        String? Function(String?)? validator,
      }) {
    return Builder(
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final locale = Localizations.localeOf(context); // Lấy locale từ context

        return TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [Formatter.currencyInputFormatter],
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: l10n.amountLabel,
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
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
            hintText: l10n.enterAmountHint,
            suffixText: _getCurrencySymbol(locale), // Sử dụng locale từ context
            suffixStyle: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.expenseColor,
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 12,
            ),
          ),
          cursorColor: theme.colorScheme.primary,
          style: GoogleFonts.poppins(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
          validator: validator,
        );
      },
    );
  }

  static Widget buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? Function(T?)? validator,
    String? hint,
    bool isRequired = true,
  }) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final l10n = AppLocalizations.of(context)!;
        return DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: InputDecoration(
            label: isRequired
                ? RichText(
              text: TextSpan(
                text: '$label ',
                style: GoogleFonts.poppins(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 16,
                ),
                children: const [
                  TextSpan(
                    text: '*',
                    style: TextStyle(color: AppTheme.expenseColor),
                  ),
                ],
              ),
            )
                : Text(
              label,
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
              ),
            ),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: theme.dividerColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
              borderSide: BorderSide(color: AppTheme.expenseColor, width: 1.5),
            ),
            errorStyle: const TextStyle(
              color: AppTheme.expenseColor,
              fontSize: 11,
            ),
            contentPadding:
            const EdgeInsets.symmetric(vertical: 0, horizontal: 12).copyWith(right: 0),
          ),
          style: GoogleFonts.poppins(
            color: theme.colorScheme.onSurface,
            fontSize: 16,
          ),
          dropdownColor: theme.colorScheme.surfaceContainerHighest,
          iconEnabledColor: theme.colorScheme.onSurfaceVariant,
          validator: validator ??
                  (value) => isRequired && value == null ? l10n.selectValueError : null,
          isExpanded: true,
          alignment: AlignmentDirectional.centerStart,
        );
      },
    );
  }

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
        context: context,
        initialDate: date ?? DateTime.now(),
        firstDate: firstDate ?? DateTime(2000),
        lastDate: lastDate ?? DateTime(2101),
        builder: (context, child) => Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: theme.colorScheme.primary,
              onPrimary: theme.colorScheme.onPrimary,
              surface: theme.colorScheme.surface,
              onSurface: theme.colorScheme.onSurface,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
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
          child: isRequired
              ? RichText(
            text: TextSpan(
              text: '$label ',
              style: GoogleFonts.poppins(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 16,
              ),
              children: const [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: AppTheme.expenseColor),
                ),
              ],
            ),
          )
              : Text(
            label,
            style: GoogleFonts.poppins(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ),
        InkWell(
          onTap: handleTap,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: theme.dividerColor, width: 1),
              ),
              errorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppTheme.expenseColor, width: 1),
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(
                  color: AppTheme.expenseColor,
                  width: 1.5,
                ),
              ),
              errorText: errorText,
              errorStyle: const TextStyle(
                color: AppTheme.expenseColor,
                fontSize: 11,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              suffixIcon: Icon(
                Icons.calendar_today,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            child: Text(
              date != null ? displayFormat.format(date) : l10n.notSelected,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: date != null
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}