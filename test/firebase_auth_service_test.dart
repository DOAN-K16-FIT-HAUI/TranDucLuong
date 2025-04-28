import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/models/user.dart' as app_user;
import 'package:finance_app/data/services/firebase_auth_service.dart';

void main() {
  late FirebaseAuthService authService;

  setUpAll(() async {
    // Khởi tạo Firebase
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();

    // Connect với Firebase Auth Emulator
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);

    authService = FirebaseAuthService();
  });

  group('FirebaseAuthService - Emulator Test', () {
    const testEmail = 'testuser@example.com';
    const testPassword = 'testpassword';

    test('Sign up with email and password', () async {
      final user = await authService.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      expect(user.email, testEmail);
      expect(user.id.isNotEmpty, true);
      expect(user.loginMethod, 'email');
    });

    test('Sign in with email and password', () async {
      final user = await authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );

      expect(user.email, testEmail);
      expect(user.id.isNotEmpty, true);
      expect(user.loginMethod, 'email');
    });

    test('Send password reset email', () async {
      await authService.sendPasswordResetEmail(email: testEmail);

      // Nếu không throw error thì pass test
      expect(true, true);
    });

    test('Sign out', () async {
      await authService.signOut();
      expect(FirebaseAuth.instance.currentUser, isNull);
    });
  });
}
