import 'package:finance_app/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FacebookAuth _facebookAuth;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
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
        displayName: userCredential.user!.displayName,
        photoUrl: userCredential.user!.photoURL,
        loginMethod: 'email',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Đã xảy ra lỗi không xác định khi đăng nhập: $e',
      );
    }
  }

  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
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
        photoUrl: credential.user!.photoURL,
        loginMethod: 'email',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Đã xảy ra lỗi không xác định khi đăng ký: $e',
      );
    }
  }

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
        photoUrl: userCredential.user!.photoURL,
        loginMethod: 'google',
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'google-sign-in-failed',
        message: 'Đăng nhập bằng Google thất bại: $e',
      );
    }
  }

  Future<UserModel> signInWithFacebook() async {
    try {
      final LoginResult loginResult = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (loginResult.status == LoginStatus.success) {
        if (loginResult.accessToken == null) {
          throw FirebaseAuthException(
            code: 'facebook-token-null',
            message: 'Không nhận được token từ Facebook.',
          );
        }

        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(loginResult.accessToken!.token);

        final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(facebookAuthCredential);

        final user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Không tìm thấy người dùng sau khi đăng nhập bằng Facebook.',
          );
        }

        return UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          loginMethod: 'facebook',
        );
      } else {
        throw FirebaseAuthException(
          code: 'facebook-login-cancelled',
          message: 'Đăng nhập bằng Facebook đã bị hủy: ${loginResult.message}',
        );
      }
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'facebook-sign-in-failed',
        message: 'Đăng nhập bằng Facebook thất bại: $e',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _facebookAuth.logOut();
      await _firebaseAuth.signOut();
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'Đăng xuất thất bại: $e',
      );
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'password-reset-failed',
        message: 'Gửi email đặt lại mật khẩu thất bại: $e',
      );
    }
  }
}