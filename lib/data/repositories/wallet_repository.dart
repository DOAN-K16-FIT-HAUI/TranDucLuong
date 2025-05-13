import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  WalletRepository(this.firestoreService, {FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  // Check account status and return userId
  Future<String> _getVerifiedUserId() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw SecurityException("User not logged in");
    }

    // Reload user to get latest state
    await user.reload();
    final freshUser = _auth.currentUser; // Get fresh user data after reload

    if (freshUser == null) {
      throw SecurityException("User session expired");
    }

    // Check for disabled account
    try {
      await freshUser.getIdToken(true); // Will fail if account is disabled
    } catch (e) {
      if (e is FirebaseAuthException && e.code == 'user-disabled') {
        throw SecurityException("This account has been disabled");
      }
      rethrow;
    }

    // Check account status - could add more checks here
    if (!freshUser.emailVerified) {
      debugPrint("WARNING: User ${freshUser.uid} email is not verified");
      // Uncomment to enforce email verification
      // throw SecurityException("Email verification required");
    }

    return freshUser.uid;
  }

  // Read operations can use cached user ID
  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  Future<List<Wallet>> getWallets() async {
    final userId = _getUserId();
    if (userId == null) return [];

    final snapshot =
        await firestoreService.firestore
            .collection('users/$userId/wallets')
            .get();

    return snapshot.docs.map((doc) => Wallet.fromSnapshot(doc)).toList();
  }

  Future<Wallet> addWallet(Wallet wallet) async {
    // Get verified user ID
    final userId = await _getVerifiedUserId();

    // Validate wallet data
    Wallet.validateWallet(wallet);

    try {
      final newDocRef = await firestoreService.addDocument(
        'users/$userId/wallets',
        wallet.toJson(),
      );
      final newDocSnapshot = await newDocRef.get();
      return Wallet.fromSnapshot(newDocSnapshot);
    } catch (e) {
      debugPrint("Error adding wallet: $e");
      if (e is ArgumentError) {
        throw ValidationException(e.message);
      }
      throw Exception("Could not add wallet: $e");
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    // Get verified user ID
    final userId = await _getVerifiedUserId();

    if (wallet.id.isEmpty) {
      throw ValidationException("Wallet ID is required for update");
    }

    // Validate wallet data
    Wallet.validateWallet(wallet);

    try {
      await firestoreService.updateDocument(
        'users/$userId/wallets',
        wallet.id,
        wallet.toJson(),
      );
    } catch (e) {
      debugPrint("Error updating wallet ${wallet.id}: $e");
      if (e is ArgumentError) {
        throw ValidationException(e.message);
      }
      throw Exception("Could not update wallet: $e");
    }
  }

  Future<void> deleteWallet(String walletId) async {
    // Get verified user ID
    final userId = await _getVerifiedUserId();

    if (walletId.isEmpty) {
      throw ValidationException("Wallet ID is required for delete");
    }

    try {
      // Check if there are any transactions using this wallet
      final transactionsUsingWallet =
          await firestoreService.firestore
              .collection('users/$userId/transactions')
              .where('wallet', isEqualTo: 'users/$userId/wallets/$walletId')
              .limit(1)
              .get();

      final transactionsAsFromWallet =
          await firestoreService.firestore
              .collection('users/$userId/transactions')
              .where('fromWallet', isEqualTo: 'users/$userId/wallets/$walletId')
              .limit(1)
              .get();

      final transactionsAsToWallet =
          await firestoreService.firestore
              .collection('users/$userId/transactions')
              .where('toWallet', isEqualTo: 'users/$userId/wallets/$walletId')
              .limit(1)
              .get();

      if (transactionsUsingWallet.docs.isNotEmpty ||
          transactionsAsFromWallet.docs.isNotEmpty ||
          transactionsAsToWallet.docs.isNotEmpty) {
        throw ValidationException(
          "Cannot delete wallet that is used in transactions. "
          "Please reassign or delete those transactions first.",
        );
      }

      // Safe to delete
      await firestoreService.deleteDocument('users/$userId/wallets', walletId);
    } catch (e) {
      debugPrint("Error deleting wallet $walletId: $e");
      if (e is ValidationException) rethrow;
      throw Exception("Could not delete wallet: $e");
    }
  }
}

// Custom exceptions for better error handling
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
