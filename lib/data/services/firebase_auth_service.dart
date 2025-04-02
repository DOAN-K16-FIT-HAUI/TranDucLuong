import 'package:finance_app/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  // Sign in with email and password
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Không tìm thấy người dùng.',
        );
      }
      return UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw e; // Propagate the FirebaseAuthException
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Đã xảy ra lỗi không xác định khi đăng nhập: $e',
      );
    }
  }

  // Sign up with email and password
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-created',
          message: 'Không thể tạo người dùng.',
        );
      }
      return UserModel(
        id: credential.user!.uid,
        email: credential.user!.email ?? '',
        displayName: credential.user!.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw e; // Propagate the FirebaseAuthException
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Đã xảy ra lỗi không xác định khi đăng ký: $e',
      );
    }
  }

  // Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Đăng nhập bằng Google đã bị hủy.',
        );
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Không tìm thấy người dùng sau khi đăng nhập bằng Google.',
        );
      }
      return UserModel(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        displayName: userCredential.user!.displayName,
      );
    } on FirebaseAuthException catch (e) {
      throw e; // Propagate the FirebaseAuthException
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Đăng nhập bằng Google thất bại: $e',
      );
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // Sign out from Google if signed in
      await _firebaseAuth.signOut(); // Sign out from Firebase
    } on FirebaseAuthException catch (e) {
      throw e; // Propagate the FirebaseAuthException
    } catch (e) {
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Đăng xuất thất bại: $e',
      );
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e; // Propagate the FirebaseAuthException
    } catch (e) {
      throw FirebaseAuthException(
        code: 'password-reset-failed',
        message: 'Gửi email đặt lại mật khẩu thất bại: $e',
      );
    }
  }
}