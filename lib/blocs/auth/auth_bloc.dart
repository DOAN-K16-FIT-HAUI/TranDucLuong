import 'package:finance_app/blocs/auth/auth_event.dart';
import 'package:finance_app/blocs/auth/auth_state.dart';
import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({
    required this.authRepository,
  }) : super(AuthInitial()) {
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInWithGoogleRequested>(_onSignInWithGoogleRequested);
    on<SignInWithFacebookRequested>(_onSignInWithFacebookRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PasswordResetRequested>(_onPasswordResetRequested);
  }

  String _mapFirebaseAuthExceptionToMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
          return 'Email hoặc mật khẩu không đúng. Vui lòng kiểm tra lại.';
        case 'email-already-in-use':
          return 'Email này đã được sử dụng. Vui lòng dùng email khác.';
        case 'weak-password':
          return 'Mật khẩu quá yếu. Vui lòng sử dụng mật khẩu mạnh hơn.';
        case 'user-disabled':
          return 'Tài khoản của bạn đã bị vô hiệu hóa.';
        case 'too-many-requests':
          return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
        case 'invalid-email':
          return 'Email không hợp lệ. Vui lòng kiểm tra lại.';
        case 'user-not-found':
          return 'Không tìm thấy tài khoản với email này.';
        case 'google-sign-in-cancelled':
          return 'Đăng nhập bằng Google đã bị hủy.';
        case 'google-sign-in-failed':
          return 'Đăng nhập bằng Google thất bại. Vui lòng thử lại.';
        case 'facebook-login-cancelled':
          return 'Đăng nhập bằng Facebook đã bị hủy.';
        case 'facebook-token-null':
          return 'Không nhận được token từ Facebook. Vui lòng thử lại.';
        case 'account-exists-with-different-credential':
          return 'Tài khoản đã tồn tại với thông tin đăng nhập khác.';
        case 'operation-not-allowed':
          return 'Đăng nhập bằng Facebook chưa được kích hoạt trong Firebase.';
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

  Future<void> _onSignInWithFacebookRequested(
      SignInWithFacebookRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithFacebook();
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