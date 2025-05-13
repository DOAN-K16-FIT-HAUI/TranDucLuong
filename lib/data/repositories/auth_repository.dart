import 'package:finance_app/data/models/user.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository({FirebaseAuthService? firebaseAuthService})
    : _firebaseAuthService =
          firebaseAuthService ??
          FirebaseAuthService(
            firebaseAuth: FirebaseAuth.instance,
            googleSignIn: GoogleSignIn(),
            facebookAuth: FacebookAuth.instance,
          );

  // Get current user
  User? get currentUser => _firebaseAuthService.currentUser;

  // Verify if user account is active (not disabled)
  Future<bool> isAccountActive() async {
    try {
      final user = _firebaseAuthService.currentUser;
      if (user == null) return false;

      // Force reload user metadata to get latest account status
      await user.reload();

      // Get fresh user object after reload
      final freshUser = _firebaseAuthService.currentUser;
      if (freshUser == null) return false;

      // Check disabled status via metadata
      // Note: Firebase doesn't directly expose isDisabled, but a disabled account
      // will throw an error when trying to get ID token
      try {
        await freshUser.getIdToken(true);
        return true; // Account is active
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'user-disabled') {
          return false; // Account is disabled
        }
        rethrow; // Some other error occurred
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _firebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check if account is active after sign in
      if (!await isAccountActive()) {
        await signOut(); // Sign out if account is disabled
        throw FirebaseAuthException(
          code: 'user-disabled',
          message: 'This account has been disabled.',
        );
      }

      return user;
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      return await _firebaseAuthService.signInWithGoogle();
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  Future<UserModel> signInWithFacebook() async {
    try {
      return await _firebaseAuthService.signInWithFacebook();
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuthService.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuthService.signOut();
    } catch (e) {
      rethrow; // Propagate the error to AuthBloc
    }
  }

  // Enhanced version that checks disabled status
  Future<UserModel> getCurrentUser() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      throw Exception('No authenticated user');
    }

    // Check if account is disabled
    if (!await isAccountActive()) {
      await signOut(); // Sign out the disabled user
      throw FirebaseAuthException(
        code: 'user-disabled',
        message: 'This account has been disabled.',
      );
    }

    // Chuyển đổi Firebase User thành UserModel của ứng dụng
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      // Thêm các thuộc tính khác nếu cần
    );
  }
}
