// lib/blocs/localization/localization_event.dart
import 'package:equatable/equatable.dart';

abstract class LocalizationEvent extends Equatable {
  const LocalizationEvent();

  @override
  List<Object?> get props => [];
}

class LoadLocalizationEvent extends LocalizationEvent {}

class ChangeLanguageEvent extends LocalizationEvent {
  final String language;

  const ChangeLanguageEvent(this.language);

  @override
  List<Object?> get props => [language];
}