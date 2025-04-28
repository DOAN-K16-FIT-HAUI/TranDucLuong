import 'package:finance_app/data/models/user.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountRepository {
  final FirebaseAuthService _authService;
  final FirebaseAuth _firebaseAuth;

  AccountRepository({
    FirebaseAuthService? authService,
    FirebaseAuth? firebaseAuth,
  })  : _authService = authService ?? FirebaseAuthService(),
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  Future<UserModel> getAccountData() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No user is currently signed in');
      }

      String loginMethod = 'email';
      if (firebaseUser.providerData.any((provider) => provider.providerId == 'google.com')) {
        loginMethod = 'google';
      } else if (firebaseUser.providerData.any((provider) => provider.providerId == 'facebook.com')) {
        loginMethod = 'facebook';
      }

      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      final language = prefs.getString('language') ?? 'Tiếng Việt';

      return UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        isDarkMode: isDarkMode,
        language: language,
        loginMethod: loginMethod,
      );
    } catch (e) {
      throw Exception('Failed to fetch user data: $e');
    }
  }

  Future<void> saveDarkMode(bool isDarkMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', isDarkMode);
    } catch (e) {
      throw Exception('Failed to save dark mode: $e');
    }
  }

  Future<void> saveLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', language);
    } catch (e) {
      throw Exception('Failed to save language: $e');
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<void> updateUserInfo({
    String? displayName,
    String? photoUrl,
    String? email,
    String? currentPassword,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (email != null && email != user.email) {
        if (currentPassword == null) {
          throw Exception('Password is required to update email');
        }
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.verifyBeforeUpdateEmail(email);
      }

      if (displayName != null) {
        await user.updateDisplayName(displayName);
      }
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
      }

      await user.reload();
    } catch (e) {
      throw Exception('Failed to update user info: $e');
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      await user.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}