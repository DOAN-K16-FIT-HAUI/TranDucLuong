import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<DocumentReference> addDocument(String collectionPath, Map<String, dynamic> data) {
    return firestore.collection(collectionPath).add(data);
  }

  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) {
    return firestore.collection(collectionPath).doc(documentId).update(data);
  }

  Future<void> deleteDocument(String collectionPath, String documentId) {
    return firestore.collection(collectionPath).doc(documentId).delete();
  }

  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId) {
    return firestore.collection(collectionPath).doc(documentId).get();
  }

  Stream<QuerySnapshot> getCollectionStream(String collectionPath) {
    return firestore.collection(collectionPath).snapshots();
  }

  Future<QuerySnapshot> getOrderedCollection(String collectionPath, String orderByField) {
    return firestore.collection(collectionPath).orderBy(orderByField).get();
  }
}