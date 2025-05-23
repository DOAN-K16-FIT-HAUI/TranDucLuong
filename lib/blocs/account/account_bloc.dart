import 'package:finance_app/blocs/account/account_event.dart';
import 'package:finance_app/blocs/account/account_state.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AccountRepository _accountRepository;
  final AuthBloc _authBloc;

  AccountBloc({
    AccountRepository? accountRepository,
    required AuthBloc authBloc,
  }) : _accountRepository = accountRepository ?? AccountRepository(),
       _authBloc = authBloc,
       super(AccountLoading()) {
    on<LoadAccountDataEvent>(_onLoadAccountData);
    on<ToggleDarkModeEvent>(_onToggleDarkMode);
    on<ChangePasswordEvent>(_onChangePassword);
    on<ChangeLanguageEvent>(_onChangeLanguage);
    on<UpdateUserInfoEvent>(_onUpdateUserInfo);
    on<DeleteAccountEvent>(_onDeleteAccount);
    on<LogoutEvent>(_onLogout);
  }

  String _mapExceptionToMessage(BuildContext context, dynamic e) {
    final l10n = AppLocalizations.of(context)!;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'requires-recent-login':
          return l10n.requiresRecentLoginError;
        case 'wrong-password':
          return l10n.wrongPasswordError;
        case 'too-many-requests':
          return l10n.tooManyRequestsError;
        case 'network-request-failed':
          return l10n.networkRequestFailedError;
        case 'email-already-in-use':
          return l10n.emailAlreadyInUseError;
        case 'invalid-email':
          return l10n.invalidEmailError;
        default:
          return l10n.genericErrorWithMessage(e.message ?? e.code);
      }
    }
    return l10n.genericErrorWithMessage(e.toString());
  }

  Future<void> _onLoadAccountData(
    LoadAccountDataEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      final user = await _accountRepository.getAccountData();
      emit(AccountLoaded(user: user));
    } catch (e) {
      emit(AccountError((context) => _mapExceptionToMessage(context, e)));
    }
  }

  Future<void> _onToggleDarkMode(
    ToggleDarkModeEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (state is AccountLoaded) {
      final currentState = state as AccountLoaded;
      try {
        await _accountRepository.saveDarkMode(event.isDarkMode);
        final updatedUser = currentState.user.copyWith(
          isDarkMode: event.isDarkMode,
        );
        emit(AccountLoaded(user: updatedUser));
      } catch (e) {
        emit(AccountError((context) => _mapExceptionToMessage(context, e)));
      }
    }
  }

  Future<void> _onChangePassword(
    ChangePasswordEvent event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());
    try {
      await _accountRepository.changePassword(
        event.oldPassword,
        event.newPassword,
      );
      emit(AccountPasswordChanged());
      add(LoadAccountDataEvent());
    } catch (e) {
      emit(AccountError((context) => _mapExceptionToMessage(context, e)));
    }
  }

  Future<void> _onChangeLanguage(
    ChangeLanguageEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (state is AccountLoaded) {
      final currentState = state as AccountLoaded;
      try {
        await _accountRepository.saveLanguage(event.language);
        final updatedUser = currentState.user.copyWith(
          language: event.language,
        );
        emit(AccountLoaded(user: updatedUser));
      } catch (e) {
        emit(AccountError((context) => _mapExceptionToMessage(context, e)));
      }
    }
  }

  Future<void> _onUpdateUserInfo(
    UpdateUserInfoEvent event,
    Emitter<AccountState> emit,
  ) async {
    if (state is AccountLoaded) {
      final currentState = state as AccountLoaded;
      try {
        await _accountRepository.updateUserInfo(
          displayName: event.displayName,
          photoUrl: event.photoUrl,
          email: event.email,
          currentPassword: event.currentPassword,
        );
        final updatedUser = currentState.user.copyWith(
          displayName: event.displayName,
          photoUrl: event.photoUrl,
          email: event.email ?? currentState.user.email,
        );
        emit(AccountLoaded(user: updatedUser));
      } catch (e) {
        emit(AccountError((context) => _mapExceptionToMessage(context, e)));
      }
    }
  }

  Future<void> _onDeleteAccount(
    DeleteAccountEvent event,
    Emitter<AccountState> emit,
  ) async {
    try {
      await _accountRepository.deleteAccount();
      _authBloc.add(SignOutRequested());
      emit(AccountDeleted());
    } catch (e) {
      emit(AccountError((context) => _mapExceptionToMessage(context, e)));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AccountState> emit) async {
    try {
      await _accountRepository.logout();
      _authBloc.add(SignOutRequested());
      emit(AccountLoggedOut());
    } catch (e) {
      emit(AccountError((context) => _mapExceptionToMessage(context, e)));
    }
  }
}
