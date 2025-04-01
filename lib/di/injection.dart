import 'package:finance_app/data/repositories/auth_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton(() => FirebaseAuthService());
  sl.registerLazySingleton(() => AuthRepository(sl()));
}