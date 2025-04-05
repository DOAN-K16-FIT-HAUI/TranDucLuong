import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // Đăng ký FirebaseAuth và GoogleSignIn
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());

  // Đăng ký Services
  sl.registerLazySingleton<FirebaseAuthService>(() => FirebaseAuthService());
  sl.registerLazySingleton<FirebaseMessagingService>(() => FirebaseMessagingService());

  // Đăng ký Repositories
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepository(sl<FirebaseAuthService>()),
  );
  sl.registerLazySingleton<NotificationRepository>(
        () => NotificationRepository(sl<FirebaseMessagingService>()),
  );

  // Đăng ký Blocs
  sl.registerFactory<AuthBloc>(
        () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<NotificationBloc>(
        () => NotificationBloc(sl<NotificationRepository>()),
  );
}