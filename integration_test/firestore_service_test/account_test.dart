import 'package:finance_app/blocs/account/account_bloc.dart';
import 'package:finance_app/blocs/account/account_event.dart';
import 'package:finance_app/blocs/account/account_state.dart';
import 'package:finance_app/blocs/auth/auth_bloc.dart';
import 'package:finance_app/data/repositories/account_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

// Mock AuthBloc
class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  late FirebaseAuthService authService;
  late AccountBloc accountBloc;
  late AccountRepository accountRepository;
  late AuthBloc authBloc;
  late String testEmail;
  const testPassword = 'testpassword';
  const testNewPassword = 'newpassword123';
  const testDisplayName = 'Test User';

  setUpAll(() async {
    // Initialize Firebase with emulators
    await initFirebase();

    // Initialize services
    authService = FirebaseAuthService();
    accountRepository = AccountRepository();
    authBloc = MockAuthBloc();
    accountBloc = AccountBloc(
      accountRepository: accountRepository,
      authBloc: authBloc,
    );

    // Setup shared preferences for tests
    SharedPreferences.setMockInitialValues({
      'isDarkMode': false,
      'language': 'Tiếng Việt',
    });
  });

  setUp(() async {
    // Create a new test email for each test
    testEmail = await generateTestEmail();

    // Ensure user is logged out
    await FirebaseAuth.instance.signOut();

    // Clear Firestore data before each test
    await clearFirestoreData();
  });

  tearDown(() {
    // Close blocs to reset state
    accountBloc.close();
    accountBloc = AccountBloc(
      accountRepository: accountRepository,
      authBloc: authBloc,
    );
  });

  group('Account Integration Test with Authentication', () {
    test('Load account data after sign in', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Update user display name
      final user = FirebaseAuth.instance.currentUser!;
      await user.updateDisplayName(testDisplayName);
      
      // Load account data
      accountBloc.add(LoadAccountDataEvent());

      // Wait and check state
      await expectLater(
        accountBloc.stream,
        emitsThrough(
          predicate<AccountState>((state) {
            debugPrint('Account state emitted: ${state.runtimeType}');
            if (state is AccountLoaded) {
              final userData = state.user;
              debugPrint('User data: name=${userData.displayName}, email=${userData.email}');
              return userData.email == testEmail && 
                     userData.displayName == testDisplayName &&
                     userData.loginMethod == 'email';
            }
            return false;
          }),
        ),
      );
    });

    test('Toggle dark mode setting', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Toggle dark mode
      accountBloc.add(const ToggleDarkModeEvent(true));
      
      // Wait and check updated state
      await expectLater(
        accountBloc.stream,
        emitsThrough(
          predicate<AccountState>((state) {
            if (state is AccountLoaded) {
              return state.user.isDarkMode == true;
            }
            return false;
          }),
        ),
      );
    });

    test('Change language setting', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Change language to English
      accountBloc.add(const ChangeLanguageEvent('English'));
      
      // Wait and check updated state
      await expectLater(
        accountBloc.stream,
        emitsThrough(
          predicate<AccountState>((state) {
            if (state is AccountLoaded) {
              debugPrint('Language changed to: ${state.user.language}');
              return state.user.language == 'English';
            }
            return false;
          }),
        ),
      );
    });

    test('Update user info', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Update display name
      const newDisplayName = 'Updated User Name';
      accountBloc.add(const UpdateUserInfoEvent(
        displayName: newDisplayName,
      ));
      
      // Wait and check updated state
      await expectLater(
        accountBloc.stream,
        emitsThrough(
          predicate<AccountState>((state) {
            if (state is AccountLoaded) {
              debugPrint('Display name updated to: ${state.user.displayName}');
              return state.user.displayName == newDisplayName;
            }
            return false;
          }),
        ),
      );
    });

    test('Change password', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Change password
      accountBloc.add(ChangePasswordEvent(
        oldPassword: testPassword,
        newPassword: testNewPassword,
      ));
      
      // Wait for password changed state
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountPasswordChanged)),
      );
      
      // Sign out
      await FirebaseAuth.instance.signOut();
      
      // Try to sign in with new password to verify it changed
      try {
        final signedInUser = await authService.signInWithEmailAndPassword(
          email: testEmail,
          password: testNewPassword,
        );
        expect(signedInUser.id.isNotEmpty, true);
      } catch (e) {
        fail('Failed to sign in with new password: $e');
      }
    });

    test('Cannot access account data without authentication', () async {
      // Ensure no user is logged in
      await FirebaseAuth.instance.signOut();
      
      // Try to load account data
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait and check for error
      await expectLater(
        accountBloc.stream,
        emitsThrough(
          predicate<AccountState>((state) {
            debugPrint('Account state emitted: ${state.runtimeType}');
            return state is AccountError;
          }),
        ),
      );
    });

    test('Logout functionality', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Logout
      accountBloc.add(LogoutEvent());
      
      // Wait for logged out state
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoggedOut)),
      );
      
      // Verify user is logged out
      expect(FirebaseAuth.instance.currentUser, isNull);
    });

    // Ideally, this test would be run separately since it deletes the account
    test('Delete account', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
    
      // Load account data first
      accountBloc.add(LoadAccountDataEvent());
      
      // Wait for data to load
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoaded)),
      );
      
      // Delete account
      accountBloc.add(DeleteAccountEvent());
      
      // Wait for logged out state
      await expectLater(
        accountBloc.stream,
        emitsThrough(predicate<AccountState>((state) => state is AccountLoggedOut)),
      );
      
      // Verify user is logged out and deleted
      expect(FirebaseAuth.instance.currentUser, isNull);
      
      // Try to login with the deleted account credentials - should fail
      try {
        await authService.signInWithEmailAndPassword(
          email: testEmail,
          password: testPassword,
        );
        fail('Should not be able to sign in with deleted account');
      } catch (e) {
        // This is expected, user should be deleted
        expect(e.toString().contains('user-not-found') || 
               e.toString().contains('no user record'), true);
      }
    });
  });
}
