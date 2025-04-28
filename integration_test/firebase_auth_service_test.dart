import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:mockito/mockito.dart';
import '../test/mocks.mocks.dart';


// Mockito and Mockito are used to create mock objects for testing.
void main() {
  late FirebaseAuthService authService;
  late MockFirebaseAuth mockFirebaseAuth;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authService = FirebaseAuthService(firebaseAuth: mockFirebaseAuth);
  });

  group('FirebaseAuthService Mock Test', () {
    test('Sign up mock', () async {
      final mockUser = MockUser();
      final mockUserCredential = MockUserCredential();

      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.email).thenReturn('mockuser@example.com');
      when(mockUser.uid).thenReturn('mockuid');
      when(mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
      when(mockUserCredential.user).thenReturn(mockUser);
      when(
        mockFirebaseAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => mockUserCredential);

      final user = await authService.createUserWithEmailAndPassword(
        email: 'mockuser@example.com',
        password: '123456',
      );

      expect(user.email, 'mockuser@example.com');
      expect(user.id, 'mockuid');
      expect(user.loginMethod, 'email');
    });
  });
}


// Local emulators 
// import 'package:finance_app/firebase_option.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';

// void main() {
//   late FirebaseAuthService authService;
//   late String testEmail;
//   const testPassword = 'testpassword';

//   setUpAll(() async {
//     TestWidgetsFlutterBinding.ensureInitialized();
//     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//     await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);

//     authService = FirebaseAuthService();
//   });

//   setUp(() async {
//     // Generate a fresh email before each test
//     testEmail = "testuser${DateTime.now().millisecondsSinceEpoch}@example.com";
//   });

//   group('FirebaseAuthService Integration Test', () {
//     test('Full Auth Flow: Sign up -> Sign in -> Reset Password -> Sign out', () async {
//       // Sign up
//       final userSignUp = await authService.createUserWithEmailAndPassword(
//         email: testEmail,
//         password: testPassword,
//       );
//       expect(userSignUp.email, testEmail);
//       expect(userSignUp.id.isNotEmpty, true);
//       expect(userSignUp.loginMethod, 'email');

//       // Sign in
//       final userSignIn = await authService.signInWithEmailAndPassword(
//         email: testEmail,
//         password: testPassword,
//       );
//       expect(userSignIn.email, testEmail);
//       expect(userSignIn.id.isNotEmpty, true);
//       expect(userSignIn.loginMethod, 'email');

//       // Send password reset email
//       await authService.sendPasswordResetEmail(email: testEmail);
//       expect(true, true);

//       // Sign out
//       await authService.signOut();
//       expect(FirebaseAuth.instance.currentUser, isNull);
//     });
//   });
// }