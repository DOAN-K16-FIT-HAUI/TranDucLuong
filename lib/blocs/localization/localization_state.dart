// lib/blocs/localization/localization_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class LocalizationState extends Equatable {
  final Locale locale;
  final String language;

  const LocalizationState({
    required this.locale,
    required this.language,
  });

  @override
  List<Object?> get props => [locale, language];
}