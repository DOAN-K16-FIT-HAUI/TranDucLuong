import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // Đăng ký FirebaseAuth và GoogleSignIn
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Đăng ký FirebaseAuthService và AuthRepository
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepository(sl<FirebaseAuthService>()));

  // Đăng ký AuthBloc
  sl.registerFactory<AuthBloc>(() => AuthBloc(authRepository: sl<AuthRepository>()));
}