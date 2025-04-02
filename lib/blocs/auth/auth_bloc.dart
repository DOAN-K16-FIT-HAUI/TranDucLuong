import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  // Helper method to map FirebaseAuthException to custom messages
  String _mapFirebaseAuthExceptionToMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
      // Handle the generic invalid-credential error
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
      // Sign-up errors
        case 'email-already-in-use':
          return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.';
      // Other errors that are still specific
        case 'user-disabled':
          return 'Tài khoản của bạn đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      // Password reset errors
        case 'invalid-email':
          return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
      // Google sign-in errors
        case 'google-sign-in-cancelled':
          return 'Đăng nhập bằng Google đã bị hủy.';
        case 'google-sign-in-failed':
          return 'Đăng nhập bằng Google thất bại. Vui lòng thử lại.';
      // Network errors
        case 'network-request-failed':
          return 'Không thể kết nối mạng. Vui lòng kiểm tra kết nối và thử lại.';
        default:
          return 'Đã xảy ra lỗi: ${e.message}. Vui lòng thử lại.';
      }
    }
    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
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
      emit(AuthFailure(error: _mapFirebaseAuthExceptionToMessage(e)));
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
      emit(AuthFailure(error: _mapFirebaseAuthExceptionToMessage(e)));
    }
  }

  Future<void> _onSignInWithGoogleRequested(
      SignInWithGoogleRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(error: _mapFirebaseAuthExceptionToMessage(e)));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(error: _mapFirebaseAuthExceptionToMessage(e)));
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(email: event.email);
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(error: _mapFirebaseAuthExceptionToMessage(e)));
    }
  }
}