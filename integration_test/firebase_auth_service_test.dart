import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/firebase_option.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  late FirebaseAuthService authService;
  late String testEmail;
  const testPassword = 'testpassword';

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);

    authService = FirebaseAuthService();
  });

  setUp(() async {
    // Generate a fresh email before each test
    testEmail = "testuser${DateTime.now().millisecondsSinceEpoch}@example.com";
  });

  group('FirebaseAuthService Integration Test', () {
    test('Full Auth Flow: Sign up -> Sign in -> Reset Password -> Sign out', () async {
      // Sign up
      final userSignUp = await authService.createUserWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      expect(userSignUp.email, testEmail);
      expect(userSignUp.id.isNotEmpty, true);
      expect(userSignUp.loginMethod, 'email');

      // Sign in
      final userSignIn = await authService.signInWithEmailAndPassword(
        email: testEmail,
        password: testPassword,
      );
      expect(userSignIn.email, testEmail);
      expect(userSignIn.id.isNotEmpty, true);
      expect(userSignIn.loginMethod, 'email');

      // Send password reset email
      await authService.sendPasswordResetEmail(email: testEmail);
      expect(true, true);

      // Sign out
      await authService.signOut();
      expect(FirebaseAuth.instance.currentUser, isNull);
    });
  });
}