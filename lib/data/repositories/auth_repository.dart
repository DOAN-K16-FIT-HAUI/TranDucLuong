import 'package:finance_app/data/models/user.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository(this._firebaseAuthService);

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuthService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuthService.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuthService.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuthService.signOut();
  }
}