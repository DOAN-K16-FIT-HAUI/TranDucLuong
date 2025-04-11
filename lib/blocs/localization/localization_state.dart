import 'package:flutter/material.dart';

class LocalizationState {
  final Locale locale;
  final String language;
  final String Function(BuildContext)? error;

  const LocalizationState({
    required this.locale,
    required this.language,
    this.error,
  });
}