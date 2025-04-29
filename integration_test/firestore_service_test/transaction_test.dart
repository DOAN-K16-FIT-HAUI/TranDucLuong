import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/blocs/transaction/transaction_bloc.dart';
import 'package:finance_app/blocs/transaction/transaction_event.dart';
import 'package:finance_app/blocs/transaction/transaction_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/data/models/transaction.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/repositories/transaction_repository.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../test_helpers.dart';

void main() {
  late FirebaseAuthService authService;
  late TransactionBloc transactionBloc;
  late TransactionRepository transactionRepository;
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
    transactionRepository = TransactionRepository(firestoreService);
    walletRepository = WalletRepository(firestoreService);
    transactionBloc = TransactionBloc(
      transactionRepository: transactionRepository,
    );
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
      // Clear wallets
      final walletsCollection = FirebaseFirestore.instance.collection(
        'users/$userId/wallets',
      );
      final wallets = await walletsCollection.get();
      for (var doc in wallets.docs) {
        await doc.reference.delete();
      }
      // Clear transactions
      final transactionsCollection = FirebaseFirestore.instance.collection(
        'transactions',
      );
      final transactions =
          await transactionsCollection.where('userId', isEqualTo: userId).get();
      for (var doc in transactions.docs) {
        await doc.reference.delete();
      }
    }
  });

  tearDown(() {
    // Close blocs to reset state
    transactionBloc.close();
    walletBloc.close();
    transactionBloc = TransactionBloc(
      transactionRepository: transactionRepository,
    );
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  group('Transaction Integration Test with Authentication and Firestore', () {
    test(
      'Full Transaction Flow: Sign up -> Sign in -> Add Income Transaction -> Update Transaction -> Delete Transaction -> Sign out',
      () async {
        // Sign up and sign in
        await signUpAndSignIn(
          authService: authService,
          email: testEmail,
          password: testPassword,
        );

        // Create wallet
        final wallet = createTestWallet('Main Wallet');
        walletBloc.add(AddWallet(wallet));
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>(
              (state) => state.wallets.any((w) => w.name == 'Main Wallet'),
            ),
          ),
        );

        // Add income transaction
        final transaction = TransactionModel(
          id: '',
          userId: FirebaseAuth.instance.currentUser!.uid,
          description: 'Salary',
          amount: 1000,
          date: DateTime.now(),
          typeKey: 'Thu nhập',
          categoryKey: 'Salary',
          wallet: 'Main Wallet',
        );
        transactionBloc.add(AddTransaction(transaction));

        // Wait and check state after adding transaction
        await expectLater(
          transactionBloc.stream,
          emitsThrough(
            predicate<TransactionState>((state) => state is TransactionSuccess),
          ),
        );

        // Check wallet balance update
        walletBloc.add(LoadWallets());
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>(
              (state) => state.wallets.any(
                (w) => w.name == 'Main Wallet' && w.balance == 1000,
              ),
            ),
          ),
        );

        // Get added transaction
        final transactionsStream = transactionRepository.getUserTransactions(
          FirebaseAuth.instance.currentUser!.uid,
        );
        final transactions = await transactionsStream.first;
        final addedTransaction = transactions.first;

        // Update transaction
        final updatedTransaction = TransactionModel(
          id: addedTransaction.id,
          userId: addedTransaction.userId,
          description: 'Updated Salary',
          amount: 1500,
          date: addedTransaction.date,
          typeKey: 'Thu nhập',
          categoryKey: 'Salary',
          wallet: 'Main Wallet',
        );
        transactionBloc.add(UpdateTransaction(updatedTransaction));

        // Wait and check state after updating
        await expectLater(
          transactionBloc.stream,
          emitsThrough(
            predicate<TransactionState>((state) => state is TransactionSuccess),
          ),
        );

        // Check wallet balance update (1000 - 1000 + 1500 = 1500)
        walletBloc.add(LoadWallets());
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>(
              (state) => state.wallets.any(
                (w) => w.name == 'Main Wallet' && w.balance == 1500,
              ),
            ),
          ),
        );

        // Delete transaction
        transactionBloc.add(DeleteTransaction(addedTransaction.id));

        // Wait and check state after deleting
        await expectLater(
          transactionBloc.stream,
          emitsThrough(
            predicate<TransactionState>((state) => state is TransactionSuccess),
          ),
        );

        // Check wallet balance back to 0
        walletBloc.add(LoadWallets());
        await expectLater(
          walletBloc.stream,
          emitsThrough(
            predicate<WalletState>(
              (state) => state.wallets.any(
                (w) => w.name == 'Main Wallet' && w.balance == 0,
              ),
            ),
          ),
        );

        // Sign out
        await authService.signOut();
        expect(FirebaseAuth.instance.currentUser, isNull);
      },
    );

    test('Cannot add transaction without authentication', () async {
      // Ensure no user is logged in
      await FirebaseAuth.instance.signOut();

      // Try to add transaction when not logged in
      final transaction = TransactionModel(
        id: '',
        userId: '',
        description: 'Unauthorized Transaction',
        amount: 500,
        date: DateTime.now(),
        typeKey: 'Thu nhập',
        categoryKey: 'Other',
        wallet: 'Main Wallet',
      );
      transactionBloc.add(AddTransaction(transaction));

      // Wait and check for error
      await expectLater(
        transactionBloc.stream,
        emitsThrough(
          predicate<TransactionState>((state) => state is TransactionError),
        ),
      );
    });

    test('Transfer Transaction: Add transfer between two wallets', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Create two wallets
      final wallet1 = Wallet(
        id: '',
        name: 'Wallet 1',
        balance: 5000,
        icon: Icons.account_balance_wallet_outlined,
        type: 0,
      );
      final wallet2 = Wallet(
        id: '',
        name: 'Wallet 2',
        balance: 0,
        icon: Icons.account_balance_wallet_outlined,
        type: 0,
      );
      walletBloc.add(AddWallet(wallet1));
      walletBloc.add(AddWallet(wallet2));
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) => state.wallets.length == 2),
        ),
      );

      // Add transfer transaction
      final transferTransaction = TransactionModel(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid,
        description: 'Transfer',
        amount: 2000,
        date: DateTime.now(),
        typeKey: 'Chuyển khoản',
        categoryKey: 'Transfer',
        fromWallet: 'Wallet 1',
        toWallet: 'Wallet 2',
      );
      transactionBloc.add(AddTransaction(transferTransaction));

      // Wait and check state after adding transaction
      await expectLater(
        transactionBloc.stream,
        emitsThrough(
          predicate<TransactionState>((state) => state is TransactionSuccess),
        ),
      );

      // Check wallet balances
      walletBloc.add(LoadWallets());
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>(
            (state) =>
                state.wallets.any(
                  (w) => w.name == 'Wallet 1' && w.balance == 3000,
                ) &&
                state.wallets.any(
                  (w) => w.name == 'Wallet 2' && w.balance == 2000,
                ),
          ),
        ),
      );
    });

    test('Balance Adjustment Transaction: Adjust wallet balance', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );

      // Create wallet
      final wallet = createTestWallet('Main Wallet');
      walletBloc.add(AddWallet(wallet));
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>(
            (state) => state.wallets.any((w) => w.name == 'Main Wallet'),
          ),
        ),
      );

      // Add balance adjustment transaction
      final adjustmentTransaction = TransactionModel(
        id: '',
        userId: FirebaseAuth.instance.currentUser!.uid,
        description: 'Balance Adjustment',
        amount: 0,
        date: DateTime.now(),
        typeKey: 'Điều chỉnh số dư',
        categoryKey: 'Adjustment',
        wallet: 'Main Wallet',
        balanceAfter: 5000,
      );
      transactionBloc.add(AddTransaction(adjustmentTransaction));

      // Wait and check state after adding transaction
      await expectLater(
        transactionBloc.stream,
        emitsThrough(
          predicate<TransactionState>((state) => state is TransactionSuccess),
        ),
      );

      // Check wallet balance
      walletBloc.add(LoadWallets());
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>(
            (state) => state.wallets.any(
              (w) => w.name == 'Main Wallet' && w.balance == 5000,
            ),
          ),
        ),
      );
    });
  });
}
