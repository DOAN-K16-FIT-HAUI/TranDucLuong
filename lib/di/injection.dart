import 'package:finance_app/blocs/app_notification/notification_bloc.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/blocs/localization/localization_bloc.dart';
import 'package:finance_app/blocs/theme/theme_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:finance_app/data/repositories/notification_repository.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firebase_messaging_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  // Đăng ký FirebaseAuth, GoogleSignIn, và FacebookAuth
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  sl.registerLazySingleton<FacebookAuth>(() => FacebookAuth.instance);

  // Đăng ký Services
  sl.registerLazySingleton<FirebaseAuthService>(
    () => FirebaseAuthService(
      firebaseAuth: sl<FirebaseAuth>(),
      googleSignIn: sl<GoogleSignIn>(),
      facebookAuth: sl<FacebookAuth>(),
    ),
  );
  sl.registerLazySingleton<FirebaseMessagingService>(
    () => FirebaseMessagingService(),
  );
  sl.registerLazySingleton<FirestoreService>(() => FirestoreService());

  // Đăng ký Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepository(firebaseAuthService: sl<FirebaseAuthService>()),
  );
  sl.registerLazySingleton<AccountRepository>(
    () => AccountRepository(),
  );
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepository(sl<FirebaseMessagingService>()),
  );
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(sl<FirestoreService>()),
  );
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepository(sl<FirestoreService>()),
  );

  // Đăng ký Blocs
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<NotificationBloc>(
    () => NotificationBloc(sl<NotificationRepository>()),
  );
  sl.registerFactory<TransactionBloc>(
    () => TransactionBloc(transactionRepository: sl<TransactionRepository>()),
  );
  sl.registerFactory<WalletBloc>(
    () => WalletBloc(walletRepository: sl<WalletRepository>()),
  );
  sl.registerFactory<ThemeBloc>(() => ThemeBloc());
  sl.registerFactory<LocalizationBloc>(() => LocalizationBloc());
}
