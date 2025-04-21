import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors for financial app
  static const Color _primaryLight = Color(0xFF1E4B94); // Deep blue
  static const Color _primaryDark = Color(0xFF3A86FF); // Bright blue

  // Secondary colors
  static const Color _secondaryLight = Color(0xFF2A9D8F); // Teal
  static const Color _secondaryDark = Color(0xFF4ECDC4); // Light teal

  // Accent colors
  static const Color _accentLight = Color(0xFFFF9F1C); // Orange
  static const Color _accentDark = Color(0xFFFFBF69); // Light orange

  // Background colors
  static const Color _backgroundLight = Color(0xFFF8F9FA);
  static const Color _backgroundDark = Color(0xFF121212);

  // Surface colors
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceDark = Color(0xFF1E1E1E);

  // Text colors
  static const Color _textPrimaryLight = Color(0xFF212529);
  static const Color _textSecondaryLight = Color(0xFF6C757D);
  static const Color _textPrimaryDark = Color(0xFFF8F9FA);
  static const Color _textSecondaryDark = Color(0xFFADB5BD);

  // Error colors
  static const Color _errorLight = Color(0xFFD62828);
  static const Color _errorDark = Color(0xFFFF6B6B);

  // Success colors
  static const Color _successLight = Color(0xFF198754);
  static const Color _successDark = Color(0xFF2A9D8F);

  // Transaction type colors
  static const Color incomeColor = Color(0xFF198754); // Green for income
  static const Color expenseColor = Color(0xFFD62828); // Red for expense
  static const Color transferColor = Color(0xFF1E4B94); // Deep blue for transfer
  static const Color borrowColor = Color(0xFF7209B7); // Purple for borrow
  static const Color lendColor = Color(0xFFFF9F1C); // Orange for lend
  static const Color adjustmentColor = Color(0xFF2A9D8F); // Teal for adjustment

  static const List<Color> categoryColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.cyan,
    Colors.brown,
  ];

  // Light theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryLight,
    colorScheme: ColorScheme.light(
      primary: _primaryLight,
      secondary: _secondaryLight,
      tertiary: _accentLight,
      error: _errorLight,
      surface: _surfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textPrimaryLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: _primaryLight,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textPrimaryLight,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _textPrimaryLight,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimaryLight,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimaryLight,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: _textPrimaryLight,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: _textPrimaryLight,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: _textSecondaryLight,
      ),
    ),
    cardTheme: CardTheme(
      color: _surfaceLight,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _textSecondaryLight.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _textSecondaryLight.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        color: _textSecondaryLight,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: _textSecondaryLight.withValues(alpha: 0.7),
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceLight,
      selectedItemColor: _primaryLight,
      unselectedItemColor: _textSecondaryLight,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
      ),
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
      tertiary: _accentDark,
      error: _errorDark,
      surface: _surfaceDark,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: _textPrimaryDark,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: _backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: _surfaceDark,
      foregroundColor: _textPrimaryDark,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textPrimaryDark,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _textPrimaryDark,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _textPrimaryDark,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        color: _textPrimaryDark,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        color: _textPrimaryDark,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        color: _textSecondaryDark,
      ),
    ),
    cardTheme: CardTheme(
      color: _surfaceDark,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryDark,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: GoogleFonts.poppins(
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
        borderSide: BorderSide(color: _textSecondaryDark.withValues(alpha: 0.5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _textSecondaryDark.withValues(alpha: 0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.poppins(
        color: _textSecondaryDark,
        fontSize: 14,
      ),
      hintStyle: GoogleFonts.poppins(
        color: _textSecondaryDark.withValues(alpha: 0.7),
        fontSize: 14,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _surfaceDark,
      selectedItemColor: _primaryDark,
      unselectedItemColor: _textSecondaryDark,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
      ),
      type: BottomNavigationBarType.fixed,
    ),
  );
}