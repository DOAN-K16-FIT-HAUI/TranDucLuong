import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/wallet.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class WalletRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  WalletRepository(this.firestoreService, {FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  Future<List<Wallet>> getWallets() async {
    final userId = _getUserId();
    if (userId == null) return [];
    final snapshot = await firestoreService.firestore
        .collection('users/$userId/wallets') // Đồng bộ với subcollection
        .orderBy('orderIndex')
        .get();
    return snapshot.docs.map((doc) => Wallet.fromSnapshot(doc)).toList();
  }

  Future<Wallet> addWallet(Wallet wallet) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot add wallet");

    try {
      final newDocRef = await firestoreService.addDocument('users/$userId/wallets', wallet.toJson());
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
      await firestoreService.updateDocument('users/$userId/wallets', wallet.id, wallet.toJson());
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
      await firestoreService.deleteDocument('users/$userId/wallets', walletId);
    } catch (e) {
      debugPrint("Error deleting wallet $walletId: $e");
      throw Exception("Could not delete wallet: $e");
    }
  }

  Future<void> updateWalletOrder(List<Wallet> wallets) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot update wallet order");

    final batch = firestoreService.firestore.batch();
    for (var wallet in wallets) {
      final docRef = firestoreService.firestore.collection('users/$userId/wallets').doc(wallet.id);
      batch.update(docRef, {'orderIndex': wallet.orderIndex});
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error updating wallet order: $e");
      throw Exception("Could not update wallet order: $e");
    }
  }
}