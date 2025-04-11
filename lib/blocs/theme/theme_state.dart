import 'package:flutter/material.dart';

class ThemeState {
  final ThemeData themeData;
  final bool isDarkMode;
  final String Function(BuildContext)? error;

  ThemeState({
    required this.themeData,
    required this.isDarkMode,
    this.error,
  });

  ThemeState copyWith({
    ThemeData? themeData,
    bool? isDarkMode,
    String Function(BuildContext)? error,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      error: error ?? this.error,
    );
  }
}