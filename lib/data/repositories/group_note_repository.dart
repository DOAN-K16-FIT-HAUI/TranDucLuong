import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupNoteRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;

  GroupNoteRepository(this.firestoreService, {FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  String? _getUserId() {
    return _auth.currentUser?.uid;
  }

  Future<List<GroupNoteModel>> getGroupNotes() async {
    final userId = _getUserId();
    if (userId == null) {
      debugPrint("No user logged in, returning empty group notes list");
      return [];
    }
    try {
      final snapshot = await firestoreService.firestore
          .collection('users/$userId/group_notes')
          .orderBy('start_date')
          .get();
      final notes = snapshot.docs.map((doc) => GroupNoteModel.fromFirestore(doc)).toList();
      if (notes.isEmpty && snapshot.docs.isNotEmpty) {
        throw Exception("Firestore returned empty notes despite non-empty snapshot");
      }
      return notes;
    } catch (e) {
      debugPrint("Error fetching group notes: $e");
      throw Exception("Failed to fetch group notes: $e");
    }
  }

  Future<GroupNoteModel> addGroupNote(GroupNoteModel note) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot add group note");

    try {
      final newDocRef = await firestoreService.addDocument(
          'users/$userId/group_notes', note.toFirestore());
      final newDocSnapshot = await newDocRef.get();
      return GroupNoteModel.fromFirestore(newDocSnapshot);
    } catch (e) {
      debugPrint("Error adding group note: $e");
      throw Exception("Could not add group note: $e");
    }
  }

  Future<void> updateGroupNote(GroupNoteModel note) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot update group note");
    if (note.id.isEmpty) throw Exception("Group note ID is required for update");

    try {
      await firestoreService.updateDocument(
          'users/$userId/group_notes', note.id, note.toFirestore());
    } catch (e) {
      debugPrint("Error updating group note ${note.id}: $e");
      throw Exception("Could not update group note: $e");
    }
  }

  Future<void> deleteGroupNote(String noteId) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot delete group note");
    if (noteId.isEmpty) throw Exception("Group note ID is required for delete");

    try {
      await firestoreService.deleteDocument('users/$userId/group_notes', noteId);
    } catch (e) {
      debugPrint("Error deleting group note $noteId: $e");
      throw Exception("Could not delete group note: $e");
    }
  }

  Future<void> updateGroupNoteOrder(List<GroupNoteModel> notes) async {
    final userId = _getUserId();
    if (userId == null) throw Exception("User not logged in, cannot update group note order");

    final batch = firestoreService.firestore.batch();
    for (var note in notes) {
      final docRef = firestoreService.firestore
          .collection('users/$userId/group_notes')
          .doc(note.id);
      batch.update(docRef, note.toFirestore());
    }

    try {
      await batch.commit();
    } catch (e) {
      debugPrint("Error updating group note order: $e");
      throw Exception("Could not update group note order: $e");
    }
  }
}