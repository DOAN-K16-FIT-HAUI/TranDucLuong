import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  late FirebaseAuthService authService;
  late WalletBloc walletBloc;
  late WalletRepository walletRepository;
  late FirestoreService firestoreService;
  late String testEmail;
  const testPassword = 'testpassword';

  setUpAll(() async {
    // Initialize Firebase with emulators
    await initFirebase();

    // Initialize services
    authService = FirebaseAuthService();
    firestoreService = FirestoreService();
    walletRepository = WalletRepository(firestoreService);
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  setUp(() async {
    // Create a new test email for each test
    testEmail = await generateTestEmail();

    // Ensure user is logged out
    await FirebaseAuth.instance.signOut();

    // Clear Firestore data before each test
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final walletsCollection = FirebaseFirestore.instance.collection(
        'users/$userId/wallets',
      );
      final wallets = await walletsCollection.get();
      for (var doc in wallets.docs) {
        await doc.reference.delete();
      }
    }
  });

  tearDown(() {
    // Close WalletBloc to reset state
    walletBloc.close();
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  group('Wallet Integration Test with Authentication and Firestore', () {
    test(
      'Full Wallet Flow: Sign up -> Sign in -> Add Wallet -> Edit Wallet -> Delete Wallet -> Sign out',
      () async {
        // Sign up and sign in
        await signUpAndSignIn(
          authService: authService,
          email: testEmail,
          password: testPassword,
        );

        // Create wallet
        final newWallet = createTestWallet('Test Wallet');
        walletBloc.add(AddWallet(newWallet));

        // Wait and check state after adding wallet
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>((state) {
              return state.wallets.isNotEmpty &&
                  state.wallets.any(
                    (w) => w.name == 'Test Wallet' && w.balance == 0,
                  );
            }),
          ),
        );

        // Get the created wallet
        final addedWallet = walletBloc.state.wallets.first;

        // Edit wallet
        final updatedWallet = addedWallet.copyWith(
          name: 'Updated Wallet',
          balance: 2000,
        );
        walletBloc.add(EditWallet(updatedWallet));

        // Wait and check state after editing
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>((state) {
              return state.wallets.isNotEmpty &&
                  state.wallets.any(
                    (w) => w.name == 'Updated Wallet' && w.balance == 2000,
                  );
            }),
          ),
        );

        // Delete wallet
        walletBloc.add(DeleteWallet(addedWallet.id, addedWallet.type));

        // Wait and check state after deleting
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>((state) {
              return state.wallets.isEmpty;
            }),
          ),
        );

        // Sign out
        await authService.signOut();
        expect(FirebaseAuth.instance.currentUser, isNull);
      },
    );

    test('Cannot interact with wallets without authentication', () async {
      // Ensure no user is logged in
      await FirebaseAuth.instance.signOut();

      // Try to add wallet when not logged in
      final newWallet = createTestWallet('Unauthorized Wallet');
      walletBloc.add(AddWallet(newWallet));

      // Wait and check for error
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.error != null && state.wallets.isEmpty;
          }),
        ),
      );
    });

    test('Load wallets after sign in', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Add wallet directly to Firestore
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users/$userId/wallets').add({
        'name': 'Preloaded Wallet',
        'balance': 3000,
        'icon_code_point': Icons.account_balance_wallet_outlined.codePoint,
        'icon_font_family': 'MaterialIcons',
        'type': 0,
      });

      // Load wallets
      walletBloc.add(LoadWallets());

      // Wait and check state
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            return state.wallets.isNotEmpty &&
                state.wallets.any(
                  (w) => w.name == 'Preloaded Wallet' && w.balance == 3000,
                );
          }),
        ),
      );
    });
  });
}
