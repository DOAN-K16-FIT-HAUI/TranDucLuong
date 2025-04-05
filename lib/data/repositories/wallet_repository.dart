import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final _auth = FirebaseAuth.instance;

  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  Future<List<Wallet>> getWallets() async {
    final userId = _getUserId();
    if (userId == null) return [];

    try {
      final snapshot = await _firestoreService.getOrderedCollection('users/$userId/wallets', 'orderIndex');
      return snapshot.docs.map((doc) => Wallet.fromSnapshot(doc)).toList();
    } catch (e) {
      debugPrint("Error getting wallets: $e");
      throw Exception("Could not fetch wallets: $e");
    }
  }

  Future<Wallet> addWallet(Wallet wallet) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot add wallet");

    try {
      final newDocRef = await _firestoreService.addDocument('users/$userId/wallets', wallet.toJson());
      final newDocSnapshot = await newDocRef.get();
      return Wallet.fromSnapshot(newDocSnapshot);
    } catch (e) {
      debugPrint("Error adding wallet: $e");
      throw Exception("Could not add wallet: $e");
    }
  }

  Future<void> updateWallet(Wallet wallet) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot update wallet");
    if (wallet.id.isEmpty) throw Exception("Wallet ID is required for update");

    try {
      await _firestoreService.updateDocument('users/$userId/wallets', wallet.id, wallet.toJson());
    } catch (e) {
      debugPrint("Error updating wallet ${wallet.id}: $e");
      throw Exception("Could not update wallet: $e");
    }
  }

  Future<void> deleteWallet(String walletId) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot delete wallet");
    if (walletId.isEmpty) throw Exception("Wallet ID is required for delete");

    try {
      await _firestoreService.deleteDocument('users/$userId/wallets', walletId);
    } catch (e) {
      debugPrint("Error deleting wallet $walletId: $e");
      throw Exception("Could not delete wallet: $e");
    }
  }

  Future<void> updateWalletOrder(List<Wallet> wallets) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot update wallet order");

    final batch = _firestoreService.firestore.batch();
    for (var wallet in wallets) {
      final docRef = _firestoreService.firestore.collection('users/$userId/wallets').doc(wallet.id);
      batch.update(docRef, {'orderIndex': wallet.orderIndex}); // Sử dụng orderIndex
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error updating wallet order: $e");
      throw Exception("Could not update wallet order: $e");
    }
  }
}