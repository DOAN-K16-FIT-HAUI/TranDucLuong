import 'package:finance_app/data/models/user.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final FirebaseAuthService _firebaseAuthService;

  AuthRepository({
    FirebaseAuthService? firebaseAuthService,
  }) : _firebaseAuthService = firebaseAuthService ??
      FirebaseAuthService(
        firebaseAuth: FirebaseAuth.instance,
        googleSignIn: GoogleSignIn(),
        facebookAuth: FacebookAuth.instance,
      );

  // Get current user
  User? get currentUser => _firebaseAuthService.currentUser;

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
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
}