import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Buttons {
  static Widget buildSubmitButton(
    BuildContext context,
    String text,
    VoidCallback onPressed, {
    Color? backgroundColor,
    Color? textColor,
    double borderRadius = 8.0,
    EdgeInsets padding = const EdgeInsets.symmetric(vertical: 15),
    double elevation = 2,
    double? minWidth,
    Key? key, // Thêm tham số key
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      width: minWidth == null ? double.infinity : null,
      child: ElevatedButton(
        key: key, // Truyền key vào ElevatedButton
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          padding: padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
          elevation: elevation,
          minimumSize: minWidth != null ? Size(minWidth, padding.vertical + 30) : null,
        ),
        child: Text(
          text,
          style: GoogleFonts.notoSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textColor ?? theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  static Widget buildIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    double size = 24.0, // Default icon size
    double padding = 8.0,
    double borderRadius = 12.0,
  }) {
    final theme = Theme.of(context);
    return IconButton(
      icon: Icon(icon, size: size),
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: backgroundColor ?? theme.colorScheme.primary,
        foregroundColor: foregroundColor ?? theme.colorScheme.onPrimary,
        padding: EdgeInsets.all(padding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
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
    Key? key, // Thêm tham số key
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: ElevatedButton(
        key: key, // Truyền key vào ElevatedButton
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
          style: GoogleFonts.notoSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor ?? theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}