import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Buttons {
  static Widget buildSubmitButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    Color? backgroundColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  static Widget buildSocialLoginButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Color? color,
    required String text,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(12),
          elevation: 2,
          backgroundColor: color ?? theme.colorScheme.surface,
          foregroundColor: textColor ?? theme.colorScheme.primary,
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor ?? theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
