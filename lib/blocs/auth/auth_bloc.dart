import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  Future<void> _onSignInRequested(
      SignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthInitial()); // Quay lại trạng thái ban đầu sau khi gửi email
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }
}