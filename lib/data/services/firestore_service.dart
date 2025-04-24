import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) {
    return firestore.collection(collectionPath).add(data);
  }

  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data, {bool merge = false}) {
    return firestore.collection(collectionPath).doc(documentId).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) {
    return firestore.collection(collectionPath).doc(documentId).update(data);
  }

  Future<void> deleteDocument(String collectionPath, String documentId) {
    return firestore.collection(collectionPath).doc(documentId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDocument(String collectionPath, String documentId) {
    return firestore.collection(collectionPath).doc(documentId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getCollectionStream(String collectionPath, {String? orderByField, bool descending = false}) {
    Query<Map<String, dynamic>> query = firestore.collection(collectionPath);
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    return query.snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCollection(String collectionPath, {String? orderByField, bool descending = false}) {
    Query<Map<String, dynamic>> query = firestore.collection(collectionPath);
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    return query.get();
  }

  // Example of a more specific query if needed elsewhere
  Future<QuerySnapshot<Map<String, dynamic>>> getDocumentsWhere(
      String collectionPath, String field, dynamic isEqualTo) {
    return firestore.collection(collectionPath).where(field, isEqualTo: isEqualTo).get();
  }

  // Migration function - keep separate or remove if not actively needed
  Future<void> migrateGroupMemberships() async {
    debugPrint('Starting group membership migration...');
    final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (final userDoc in usersSnapshot.docs) {
      final userId = userDoc.id;
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members.$userId.status', isEqualTo: 'active') // Check active members specifically
          .get();

      for (final groupDoc in groupsSnapshot.docs) {
        final groupId = groupDoc.id;
        final membershipRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('groupMemberships')
            .doc(groupId);

        // Check if membership already exists before adding to batch
        final membershipDoc = await membershipRef.get();
        if (!membershipDoc.exists) {
          debugPrint('Adding membership for user $userId to group $groupId');
          batch.set(membershipRef, {
            'groupId': groupId,
            'joinedAt': groupDoc.data()['members'][userId]['joinedAt'] ?? FieldValue.serverTimestamp(), // Try to get original join date
          });
          count++;
          // Commit batch periodically to avoid exceeding limits
          if (count % 400 == 0) {
            debugPrint('Committing batch...');
            await batch.commit();
            batch = FirebaseFirestore.instance.batch(); // Start a new batch
          }
        } else {
          debugPrint('Membership already exists for user $userId in group $groupId');
        }
      }
    }
    // Commit any remaining operations
    if (count % 400 != 0) {
      debugPrint('Committing final batch...');
      await batch.commit();
    }
    debugPrint('Group membership migration completed. $count memberships processed.');
  }
}