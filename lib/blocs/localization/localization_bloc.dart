// lib/blocs/localization/localization_bloc.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finance_app/blocs/localization/localization_event.dart';
import 'package:finance_app/blocs/localization/localization_state.dart';

class LocalizationBloc extends Bloc<LocalizationEvent, LocalizationState> {
  LocalizationBloc()
      : super(const LocalizationState(
    locale: Locale('vi', 'VN'),
    language: 'Tiếng Việt',
  )) {
    on<LoadLocalizationEvent>(_onLoadLocalization);
    on<ChangeLanguageEvent>(_onChangeLanguage);
  }

  Future<void> _onLoadLocalization(LoadLocalizationEvent event, Emitter<LocalizationState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final language = prefs.getString('language') ?? 'Tiếng Việt';
    emit(LocalizationState(
      locale: _mapLanguageToLocale(language),
      language: language,
    ));
  }

  Future<void> _onChangeLanguage(ChangeLanguageEvent event, Emitter<LocalizationState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', event.language);
    emit(LocalizationState(
      locale: _mapLanguageToLocale(event.language),
      language: event.language,
    ));
  }

  Locale _mapLanguageToLocale(String language) {
    switch (language) {
      case 'English':
        return const Locale('en', 'US');
      case '日本語':
        return const Locale('ja', 'JP');
      case 'Tiếng Việt':
      default:
        return const Locale('vi', 'VN');
    }
  }
}