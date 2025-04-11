import 'package:finance_app/blocs/theme/theme_event.dart';
import 'package:finance_app/blocs/theme/theme_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Thêm để dùng l10n
import 'package:shared_preferences/shared_preferences.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc()
      : super(ThemeState(
    themeData: AppTheme.lightTheme,
    isDarkMode: false,
  )) {
    on<LoadThemeEvent>(_onLoadTheme);
    on<ToggleThemeEvent>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(LoadThemeEvent event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      emit(ThemeState(
        themeData: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        isDarkMode: isDarkMode,
      ));
    } catch (e) {
      emit(ThemeState(
        themeData: AppTheme.lightTheme,
        isDarkMode: false,
        error: (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString()),
      ));
    }
  }

  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', event.isDarkMode);
      emit(ThemeState(
        themeData: event.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
        isDarkMode: event.isDarkMode,
      ));
    } catch (e) {
      emit(ThemeState(
        themeData: state.themeData,
        isDarkMode: state.isDarkMode,
        error: (context) => AppLocalizations.of(context)!.genericErrorWithMessage(e.toString()),
      ));
    }
  }
}