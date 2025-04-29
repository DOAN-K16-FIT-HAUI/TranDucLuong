import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:finance_app/data/services/firebase_auth_service.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> initFirebase() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAuth.instance.useAuthEmulator('10.0.2.2', 9099);
  FirebaseFirestore.instance.useFirestoreEmulator('10.0.2.2', 8080);
}

Future<String> generateTestEmail() async {
  return "testuser${DateTime.now().millisecondsSinceEpoch}@example.com";
}

Future<void> signUpAndSignIn({
  required FirebaseAuthService authService,
  required String email,
  required String password,
}) async {
  final user = await authService.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );
  assert(user.id.isNotEmpty);

  final signedInUser = await authService.signInWithEmailAndPassword(
    email: email,
    password: password,
  );
  assert(signedInUser.id == user.id);
}

Wallet createTestWallet(String name) {
  return Wallet(
    id: '',
    name: name,
    balance: 0,
    icon: Icons.account_balance_wallet_outlined,
    type: 0,
  );
}

/// Clears Firestore data for the current user (wallets and transactions)
Future<void> clearFirestoreData() async {
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
}

/// Creates and adds a test transaction to Firestore
Future<void> createTestTransaction({
  required String userId,
  required String description,
  required double amount,
  required DateTime date,
  required String typeKey,
  required String categoryKey,
  required String wallet,
  String? fromWallet,
  String? toWallet,
  double? balanceAfter,
}) async {
  final Map<String, dynamic> transaction = {
    'userId': userId,
    'description': description,
    'amount': amount,
    'date': Timestamp.fromDate(date),
    'typeKey': typeKey,
    'categoryKey': categoryKey,
    'wallet': wallet,
  };

  if (fromWallet != null) {
    transaction['fromWallet'] = fromWallet;
  }

  if (toWallet != null) {
    transaction['toWallet'] = toWallet;
  }

  if (balanceAfter != null) {
    transaction['balanceAfter'] = balanceAfter;
  }

  await FirebaseFirestore.instance.collection('transactions').add(transaction);
}

/// Updates a wallet balance in Firestore
Future<void> updateWalletBalance({
  required String userId,
  required String walletName,
  required double balance,
}) async {
  final walletSnapshot =
      await FirebaseFirestore.instance
          .collection('users/$userId/wallets')
          .where('name', isEqualTo: walletName)
          .limit(1)
          .get();

  if (walletSnapshot.docs.isNotEmpty) {
    await walletSnapshot.docs.first.reference.update({'balance': balance});
  }
}
