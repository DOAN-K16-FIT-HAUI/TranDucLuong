import 'package:finance_app/blocs/theme/theme_event.dart';
import 'package:finance_app/blocs/theme/theme_state.dart';
import 'package:finance_app/core/app_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    emit(ThemeState(
      themeData: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDarkMode: isDarkMode,
    ));
  }

  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', event.isDarkMode);
    emit(ThemeState(
      themeData: event.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      isDarkMode: event.isDarkMode,
    ));
  }
}