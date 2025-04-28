import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:local_auth/local_auth.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({
    required this.authRepository,
  }) : super(AuthInitial()) {
    // Đăng ký các sự kiện
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithFacebookRequested>(_onSignInWithFacebookRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    
    // Kích hoạt kiểm tra trạng thái xác thực ngay khi khởi tạo
    add(const CheckAuthStatus());
  }

  String _mapFirebaseAuthExceptionToMessage(BuildContext context, dynamic e) {
    final l10n = AppLocalizations.of(context)!;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
          return l10n.invalidCredentialError;
        case 'email-already-in-use':
          return l10n.emailAlreadyInUseError;
        case 'weak-password':
          return l10n.weakPasswordError;
        case 'user-disabled':
          return l10n.userDisabledError;
        case 'too-many-requests':
          return l10n.tooManyRequestsError;
        case 'invalid-email':
          return l10n.invalidEmailError;
        case 'user-not-found':
          return l10n.userNotFoundError;
        case 'google-sign-in-cancelled':
          return l10n.googleSignInCancelledError;
        case 'google-sign-in-failed':
          return l10n.googleSignInFailedError;
        case 'facebook-login-cancelled':
          return l10n.facebookLoginCancelledError;
        case 'facebook-token-null':
          return l10n.facebookTokenNullError;
        case 'account-exists-with-different-credential':
          return l10n.accountExistsWithDifferentCredentialError;
        case 'operation-not-allowed':
          return l10n.operationNotAllowedError;
        case 'network-request-failed':
          return l10n.networkRequestFailedError;
        default:
          return l10n.genericErrorWithMessage(e.message ?? e.code);
      }
    }
    return l10n.genericErrorWithMessage(e.toString());
  }

  Future<void> _onCheckAuthStatus(
      CheckAuthStatus event, Emitter<AuthState> emit) async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Kiểm tra token còn hợp lệ
        final idTokenResult = await firebaseUser.getIdTokenResult(true);
        if (idTokenResult.token != null) {
          final user = await authRepository.getCurrentUser();
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignInWithBiometricsRequested(
      SignInWithBiometricsRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final localAuth = LocalAuthentication();
      bool canCheckBiometrics = await localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        emit(AuthFailure(
            error: (context) =>
            AppLocalizations.of(context)!.biometricsNotAvailable));
        return;
      }

      bool authenticated = await localAuth.authenticate(
        localizedReason: AppLocalizations.of(event.context)!.biometricsReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Kiểm tra trạng thái Firebase Authentication
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          final user = await authRepository.getCurrentUser();
          emit(AuthAuthenticated(user: user));
        } else {
          emit(AuthFailure(
              error: (context) =>
              AppLocalizations.of(context)!.noSavedCredentials));
        }
      } else {
        emit(AuthFailure(
            error: (context) => AppLocalizations.of(context)!.biometricsError));
      }
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
      SignInWithGoogleRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignInWithFacebookRequested(
      SignInWithFacebookRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithFacebook();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(
          error: (context) => _mapFirebaseAuthExceptionToMessage(context, e)));
    }
  }
}