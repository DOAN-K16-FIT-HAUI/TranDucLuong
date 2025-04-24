import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:finance_app/data/models/group_note.dart';
import 'package:finance_app/data/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GroupNoteRepository {
  final FirestoreService firestoreService;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  GroupNoteRepository(this.firestoreService,
      {FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  String? _getUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("GroupNoteRepository: User is not logged in.");
    }
    return user?.uid;
  }

  Future<void> addGroupNote(GroupNoteModel note) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot add group note.');
    }
    if (note.groupId.isEmpty) {
      throw ArgumentError("Group ID is required for adding group note.");
    }

    try {
      final noteWithUser = note.copyWith(createdBy: userId);
      await _firestore
          .collection('groups')
          .doc(note.groupId)
          .collection('notes')
          .add(noteWithUser.toJson());
      debugPrint("Group note added successfully to group ${note.groupId}.");
    } catch (e) {
      debugPrint("Error adding group note: $e");
      throw Exception('Failed to add group note: $e');
    }
  }

  Future<void> updateGroupNote(GroupNoteModel note) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot update group note.');
    }
    if (note.id.isEmpty || note.groupId.isEmpty) {
      throw ArgumentError("Group note ID and group ID are required for update.");
    }

    try {
      await _firestore
          .collection('groups')
          .doc(note.groupId)
          .collection('notes')
          .doc(note.id)
          .update(note.toJson());
      debugPrint("Group note updated successfully (ID: ${note.id}).");
    } catch (e) {
      debugPrint("Error updating group note: $e");
      throw Exception('Failed to update group note: $e');
    }
  }

  Future<void> deleteGroupNote(String noteId, String groupId) async {
    if (groupId.isEmpty || noteId.isEmpty) {
      throw ArgumentError("Group ID and Note ID cannot be empty for deletion.");
    }
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot delete group note.');
    }

    try {
      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId)
          .delete();
      debugPrint("Group note deleted successfully (ID: $noteId).");
    } catch (e) {
      debugPrint("Error deleting group note: $e");
      throw Exception('Failed to delete group note: $e');
    }
  }

  Stream<List<GroupNoteModel>> getGroupNotes(String groupId) {
    if (groupId.isEmpty) {
      debugPrint("Cannot get group notes for empty groupId.");
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection('groups')
          .doc(groupId)
          .collection('notes')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          try {
            return GroupNoteModel.fromJson(doc.data(), doc.id);
          } catch (e) {
            debugPrint(
                "Error parsing group note ${doc.id}: $e. Data: ${doc.data()}");
            return null;
          }
        }).whereType<GroupNoteModel>().toList();
      }).handleError((error) {
        debugPrint("Error in getGroupNotes stream for group $groupId: $error");
        // Instead of returning empty list, let the error propagate or handle differently
        // return <GroupNoteModel>[];
        throw Exception('Failed to get group notes stream: $error');
      });
    } catch (e) {
      debugPrint("Error setting up getGroupNotes stream for group $groupId: $e");
      throw Exception('Failed to get group notes stream: $e');
    }
  }

  Future<void> addComment(
      String noteId, CommentModel comment, String groupId) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot add comment.');
    }
    if (noteId.isEmpty || groupId.isEmpty) {
      throw ArgumentError(
          "Group note ID and group ID are required for adding comment.");
    }
    if (comment.userId != userId) {
      throw Exception('Comment userId does not match logged-in user.');
    }

    try {
      final noteRef = _firestore
          .collection('groups')
          .doc(groupId)
          .collection('notes')
          .doc(noteId);

      // Use FieldValue.arrayUnion for simpler atomic addition
      await noteRef.update({
        'comments': FieldValue.arrayUnion([comment.toJson()])
      });

      debugPrint("Comment added to group note (ID: $noteId).");
    } catch (e) {
      debugPrint("Error adding comment to group note: $e");
      // Check for specific Firestore errors (e.g., not found)
      if (e is FirebaseException && e.code == 'not-found') {
        throw Exception("Group note with ID $noteId not found in group $groupId.");
      }
      throw Exception('Failed to add comment: $e');
    }
  }

  Future<void> updateGroupInfo(String groupId, Map<String, dynamic> data) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot update group.');
    }
    if (groupId.isEmpty) {
      throw ArgumentError("Group ID cannot be empty.");
    }

    try {
      // Firestore rules should enforce admin check
      await _firestore
          .collection('groups')
          .doc(groupId)
          .update(data);
      debugPrint("Group updated successfully (ID: $groupId).");
    } catch (e) {
      debugPrint("Error updating group: $e");
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw Exception('Permission denied. User might not be an admin of this group.');
      }
      throw Exception('Failed to update group: $e');
    }
  }

  Future<String> createGroup(String name, List<String> memberEmails) async {
    final userId = _getUserId();
    if (userId == null) {
      throw Exception('User not logged in. Cannot create group.');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Group name cannot be empty.');
    }

    final WriteBatch batch = _firestore.batch();

    try {
      final groupRef = _firestore.collection('groups').doc();
      batch.set(groupRef, {
        'name': name.trim(),
        'adminIds': [userId],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final creatorMemberRef = groupRef.collection('members').doc(userId);
      batch.set(creatorMemberRef, {
        'userId': userId,
        'email': _auth.currentUser?.email,
        'joinedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });

      final creatorMembershipRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('groupMemberships')
          .doc(groupRef.id);
      batch.set(creatorMembershipRef, {
        'groupId': groupRef.id,
        'joinedAt': FieldValue.serverTimestamp(),
      });

      final uniqueEmails = memberEmails.map((e) => e.trim().toLowerCase()).toSet().toList();
      final List<Future> userLookups = [];

      for (final email in uniqueEmails) {
        if (email == _auth.currentUser?.email?.toLowerCase()) continue;

        userLookups.add(
            _firestore
                .collection('users')
                .where('email', isEqualTo: email)
                .limit(1)
                .get()
                .then((userQuery) {
              if (userQuery.docs.isNotEmpty) {
                // --- THÀNH VIÊN ĐÃ TỒN TẠI (Giữ nguyên) ---
                final existingUserId = userQuery.docs.first.id;
                final memberRef = groupRef.collection('members').doc(existingUserId);
                batch.set(memberRef, { /* ... dữ liệu như cũ ... */ }, SetOptions(merge: true));
              } else {
                // --- THÀNH VIÊN CHƯA TỒN TẠI (SỬA Ở ĐÂY) ---
                // Tự động tạo ID ngẫu nhiên thay vì dùng email
                final invitedMemberRef = groupRef.collection('members').doc(); // <--- Tự tạo ID
                batch.set(invitedMemberRef, {
                  'userId': null,
                  'email': email, // <-- Lưu email vào trường này
                  'invitedAt': FieldValue.serverTimestamp(),
                  'status': 'invited',
                });
                debugPrint("Adding non-existing user $email as invited member (Doc ID: ${invitedMemberRef.id}) to group ${groupRef.id}.");
              }
            })
        );
      }

      await Future.wait(userLookups); // Wait for all email lookups to complete before batching
      await batch.commit();
      debugPrint("Group ${groupRef.id} created successfully with members.");
      return groupRef.id;

    } catch (e) {
      debugPrint("Error creating group: $e");
      throw Exception('Failed to create group: $e');
    }
  }

  Future<void> activateInvitedMember(String groupId, String userId, String email) async {
    final groupRef = _firestore.collection('groups').doc(groupId);
    final normalizedEmail = email.toLowerCase();
    final invitedMemberRef = groupRef.collection('members').doc(normalizedEmail);
    final activeMemberRef = groupRef.collection('members').doc(userId);
    final userMembershipRef = _firestore.collection('users').doc(userId).collection('groupMemberships').doc(groupId);

    try {
      await _firestore.runTransaction((transaction) async {
        final invitedDoc = await transaction.get(invitedMemberRef);
        final activeDoc = await transaction.get(activeMemberRef); // Check if already active

        if (activeDoc.exists && activeDoc.data()?['status'] == 'active'){
          debugPrint("User $userId is already an active member of group $groupId.");
          // If the invitation still exists for some reason, remove it
          if (invitedDoc.exists) {
            transaction.delete(invitedMemberRef);
          }
          return; // Already active, nothing more to do
        }

        if (invitedDoc.exists && invitedDoc.data()?['status'] == 'invited') {
          transaction.set(activeMemberRef, {
            'userId': userId,
            'email': normalizedEmail, // Store the original email used for invite
            'joinedAt': FieldValue.serverTimestamp(),
            'status': 'active',
          });

          transaction.set(userMembershipRef, {
            'groupId': groupId,
            'joinedAt': FieldValue.serverTimestamp(),
          });

          transaction.delete(invitedMemberRef);

          debugPrint("Activated member $email ($userId) for group $groupId.");
        } else {
          debugPrint("No pending invitation found for $email in group $groupId or already active.");
        }
      });
    } catch (e) {
      debugPrint("Error activating invited member $email for group $groupId: $e");
      throw Exception('Failed to activate membership: $e');
    }
  }
}