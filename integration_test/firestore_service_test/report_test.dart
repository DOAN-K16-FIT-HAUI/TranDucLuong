import 'package:finance_app/blocs/report/report_bloc.dart';
import 'package:finance_app/blocs/report/report_event.dart';
import 'package:finance_app/blocs/report/report_state.dart';
import 'package:finance_app/blocs/wallet/wallet_bloc.dart';
import 'package:finance_app/blocs/wallet/wallet_event.dart';
import 'package:finance_app/blocs/wallet/wallet_state.dart';
import 'package:finance_app/data/repositories/report_repository.dart';
import 'package:finance_app/data/repositories/wallet_repository.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_helpers.dart';

void main() {
  late FirebaseAuthService authService;
  late ReportBloc reportBloc;
  late ReportRepository reportRepository;
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
    reportRepository = ReportRepository(firestoreService);
    walletRepository = WalletRepository(firestoreService);
    reportBloc = ReportBloc(reportRepository);
    walletBloc = WalletBloc(walletRepository: walletRepository);
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
    reportBloc.close();
    walletBloc.close();
    reportBloc = ReportBloc(reportRepository);
    walletBloc = WalletBloc(walletRepository: walletRepository);
  });

  group('Report Integration Test with Authentication and Firestore', () {
    test('Load report data after sign in with various transactions', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Create wallet
      final wallet = createTestWallet('Main Wallet');
      walletBloc.add(AddWallet(wallet));
      await expectLater(
        walletBloc.stream,
        emitsThrough(
          predicate<WalletState>((state) {
            debugPrint(
              'Wallet state emitted: wallets=${state.wallets.map((w) => w.name).toList()}',
            );
            return state.wallets.any((w) => w.name == 'Main Wallet');
          }),
        ),
      );

      // Add transactions directly to Firestore
      final startDate = DateTime(2025, 4, 1);
      final endDate = DateTime(2025, 4, 30);

      // Create test transactions using helper function
      await createTestTransaction(
        userId: userId,
        description: 'Salary',
        amount: 1000.0,
        date: DateTime(2025, 4, 1),
        typeKey: 'income',
        categoryKey: 'Salary',
        wallet: 'Main Wallet',
      );

      await createTestTransaction(
        userId: userId,
        description: 'Groceries',
        amount: 200.0,
        date: DateTime(2025, 4, 2),
        typeKey: 'expense',
        categoryKey: 'Food',
        wallet: 'Main Wallet',
      );

      await createTestTransaction(
        userId: userId,
        description: 'Loan',
        amount: 500.0,
        date: DateTime(2025, 4, 3),
        typeKey: 'borrow',
        categoryKey: 'Loan',
        wallet: 'Main Wallet',
      );

      await createTestTransaction(
        userId: userId,
        description: 'Balance Adjustment',
        amount: 0.0,
        date: DateTime(2025, 4, 4),
        typeKey: 'adjustment',
        categoryKey: 'Adjustment',
        wallet: 'Main Wallet',
        balanceAfter: 2000.0,
      );

      // Update wallet balance
      await updateWalletBalance(
        userId: userId,
        walletName: 'Main Wallet',
        balance: 2000.0,
      );

      // Load report data
      reportBloc.add(
        LoadReportData(userId: userId, startDate: startDate, endDate: endDate),
      );

      // Wait and check state
      await expectLater(
        reportBloc.stream,
        emitsThrough(
          predicate<ReportState>((state) {
            if (state is ReportLoaded) {
              debugPrint(
                'Report state emitted: categoryExpenses=${state.categoryExpenses}, '
                'dailyBalances=${state.dailyBalances}, '
                'transactionTypeTotals=${state.transactionTypeTotals}',
              );

              // Check that we have at least the essential transaction types
              bool transactionTypesValid =
                  state.transactionTypeTotals.containsKey('income') &&
                  state.transactionTypeTotals['income']!['amount'] == 1000.0 &&
                  state.transactionTypeTotals.containsKey('expense') &&
                  state.transactionTypeTotals['expense']!['amount'] == 200.0 &&
                  state.transactionTypeTotals.containsKey('borrow') &&
                  state.transactionTypeTotals['borrow']!['amount'] == 500.0;

              // Check optional transaction types if they exist
              if (state.transactionTypeTotals.containsKey('adjustment')) {
                transactionTypesValid =
                    transactionTypesValid &&
                    state.transactionTypeTotals['adjustment']!['amount'] == 0.0;
              }

              return state.categoryExpenses['Food'] == 200.0 &&
                  state.categoryExpenses.length == 1 &&
                  // Check daily balances
                  state.dailyBalances[DateTime(2025, 4, 1)] == 1000.0 &&
                  state.dailyBalances[DateTime(2025, 4, 2)] == 800.0 &&
                  state.dailyBalances[DateTime(2025, 4, 3)] == 1300.0 &&
                  state.dailyBalances[DateTime(2025, 4, 4)] == 2000.0 &&
                  // Check transaction type totals
                  transactionTypesValid &&
                  state.transactionTypeTotals.length >=
                      3; // At least income, expense, and borrow
            }
            return false;
          }),
        ),
      );
    });

    test('Cannot load report data without authentication', () async {
      // Ensure no user is logged in
      await FirebaseAuth.instance.signOut();

      // Try to load report data
      reportBloc.add(
        LoadReportData(
          userId: '',
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        ),
      );

      // Wait and check for error
      await expectLater(
        reportBloc.stream,
        emitsThrough(
          predicate<ReportState>((state) {
            debugPrint('Report state emitted: ${state.runtimeType}');
            return state is ReportError;
          }),
        ),
      );
    });

    test('Load report data with no transactions', () async {
      // Sign up and sign in
      await signUpAndSignIn(
        authService: authService,
        email: testEmail,
        password: testPassword,
      );
      final userId = FirebaseAuth.instance.currentUser!.uid;

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

      // Load report data
      reportBloc.add(
        LoadReportData(
          userId: userId,
          startDate: DateTime(2025, 4, 1),
          endDate: DateTime(2025, 4, 30),
        ),
      );

      // Wait and check state
      await expectLater(
        reportBloc.stream,
        emitsThrough(
          predicate<ReportState>((state) {
            debugPrint('Report state emitted: ${state.runtimeType}');
            return state is ReportLoaded &&
                state.categoryExpenses.isEmpty &&
                state.dailyBalances.values.every((balance) => balance == 0.0) &&
                state.transactionTypeTotals.isEmpty;
          }),
        ),
      );
    });
  });
}
