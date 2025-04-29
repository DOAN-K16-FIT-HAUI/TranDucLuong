import 'package:flutter_test/flutter_test.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:mockito/mockito.dart';
import '../../test/mocks.mocks.dart';

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