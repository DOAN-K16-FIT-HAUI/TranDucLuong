import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors for financial app
  static const Color _primaryLight = Color(0xFF1E4B94); // Deep blue
  static const Color _primaryDark = Color(0xFF3A86FF); // Bright blue

  // Secondary colors
  static const Color _secondaryLight = Color(0xFF2A9D8F); // Teal
  static const Color _secondaryDark = Color(0xFF4ECDC4); // Light teal

  // Success colors
  static const Color _successLight = Color(0xFF198754); // Green for success
  static const Color _successDark = Color(0xFF2A9D8F); // Teal for success

  // Background colors
  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color _surfaceLight = Color(0xFFFFFFFF); // White
  static const Color _surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color _textPrimaryLight = Color(0xFF212529);
  static const Color _textSecondaryLight = Color(0xFF6C757D);
  static const Color _textPrimaryDark = Color(0xFFF8F9FA);
  static const Color _textSecondaryDark = Color(0xFFADB5BD);

  // Error colors
  static const Color _errorLight = Color(0xFFD62828);
  static const Color _errorDark = Color(0xFFFF6B6B);

  // Basic colors
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  // Transaction type colors
  static const Color incomeColor = Color(0xFF198754); // Green for income
  static const Color expenseColor = Color(0xFFD62828); // Red for expense
  static const Color transferColor = Color(
    0xFF1E4B94,
  ); // Deep blue for transfer
  static const Color borrowColor = Color(0xFF7209B7); // Purple for borrow
  static const Color lendColor = Color(0xFFFF9F1C); // Orange for lend
  static const Color adjustmentColor = Color(0xFF2A9D8F); // Teal for adjustment

  // Notification type colors
  static const Color notificationInfoColor = Color(0xFF0D6EFD); // Blue for info
  static const Color notificationSuccessColor = Color(
    0xFF198754,
  ); // Green for success
  static const Color notificationWarningColor = Color(
    0xFFFFC107,
  ); // Yellow for warning
  static const Color notificationErrorColor = Color(
    0xFFD62828,
  ); // Red for error

  // Category colors for pie charts and listings
  static const List<Color> categoryColors = [
    Color(0xFF0D6EFD), // Blue
    Color(0xFFD62828), // Red
    Color(0xFF198754), // Green
    Color(0xFFFFC107), // Yellow
    Color(0xFF7209B7), // Purple
    Color(0xFFFF9F1C), // Orange
    Color(0xFF2A9D8F), // Teal
    Color(0xFFE83E8C), // Pink
    Color(0xFF17A2B8), // Cyan
    Color(0xFF795548), // Brown
  ];

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryLight,
    colorScheme: ColorScheme.light(
      primary: _primaryLight,
      secondary: _secondaryLight,
      tertiary: _successLight,
      error: _errorLight,
      surface: _surfaceLight,
      onPrimary: _white,
      onSecondary: _white,
      onTertiary: _white,
      onSurface: _textPrimaryLight,
      onError: _white,
    ),
    scaffoldBackgroundColor: _backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryLight,
      foregroundColor: _white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textPrimaryLight,
      ),
      displayMedium: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _textPrimaryLight,
      ),
      displaySmall: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimaryLight,
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimaryLight,
      ),
      bodyLarge: GoogleFonts.notoSans(fontSize: 16, color: _textPrimaryLight),
      bodyMedium: GoogleFonts.notoSans(fontSize: 14, color: _textPrimaryLight),
      bodySmall: GoogleFonts.notoSans(fontSize: 12, color: _textSecondaryLight),
    ),
    cardTheme: CardTheme(
      color: _surfaceLight,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: _white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryLight,
        side: BorderSide(color: _primaryLight),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _textSecondaryLight.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _textSecondaryLight.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.notoSans(
        color: _textSecondaryLight,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.notoSans(
        color: _textSecondaryLight.withValues(alpha: 0.7),
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceLight,
      selectedItemColor: _primaryLight,
      unselectedItemColor: _textSecondaryLight,
      selectedLabelStyle: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
  );

  // Dark theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primaryDark,
    colorScheme: ColorScheme.dark(
      primary: _primaryDark,
      secondary: _secondaryDark,
      tertiary: _successDark,
      error: _errorDark,
      surface: _surfaceDark,
      onPrimary: _black,
      onSecondary: _black,
      onTertiary: _black,
      onSurface: _textPrimaryDark,
      onError: _black,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      foregroundColor: _textPrimaryDark,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.notoSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textPrimaryDark,
      ),
      displayMedium: GoogleFonts.notoSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _textPrimaryDark,
      ),
      displaySmall: GoogleFonts.notoSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
      headlineMedium: GoogleFonts.notoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
      bodyLarge: GoogleFonts.notoSans(fontSize: 16, color: _textPrimaryDark),
      bodyMedium: GoogleFonts.notoSans(fontSize: 14, color: _textPrimaryDark),
      bodySmall: GoogleFonts.notoSans(fontSize: 12, color: _textSecondaryDark),
    ),
    cardTheme: CardTheme(
      color: _surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDark,
        foregroundColor: _black,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryDark,
        side: BorderSide(color: _primaryDark),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.notoSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceDark,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _textSecondaryDark.withValues(alpha: 0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: _textSecondaryDark.withValues(alpha: 0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.notoSans(color: _textSecondaryDark, fontSize: 14),
      hintStyle: GoogleFonts.notoSans(
        color: _textSecondaryDark.withValues(alpha: 0.7),
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceDark,
      selectedItemColor: _primaryDark,
      unselectedItemColor: _textSecondaryDark,
      selectedLabelStyle: GoogleFonts.notoSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.notoSans(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
  );
}
