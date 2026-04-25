import 'package:cloud_firestore/cloud_firestore.dart';

import 'document_store.dart';

class FirebaseDocumentStore implements DocumentStore {
  FirebaseDocumentStore(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> get({
    required String collection,
    required String id,
  }) async {
    final snap = await _firestore.collection(collection).doc(id).get();
    if (!snap.exists) return null;
    return {'id': snap.id, ...(snap.data() ?? <String, dynamic>{})};
  }

  @override
  Future<List<Map<String, dynamic>>> query({
    required String collection,
    required String field,
    required dynamic isEqualTo,
  }) async {
    final snaps = await _firestore
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .get();
    return snaps.docs
        .map((doc) => {'id': doc.id, ...(doc.data())})
        .toList(growable: false);
  }

  @override
  Future<void> set({
    required String collection,
    required String id,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    await _firestore
        .collection(collection)
        .doc(id)
        .set(data, SetOptions(merge: merge));
  }

  @override
  Stream<Map<String, dynamic>?> watchDocument({
    required String collection,
    required String id,
  }) {
    return _firestore.collection(collection).doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      return {'id': snap.id, ...(snap.data() ?? <String, dynamic>{})};
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> watchQuery({
    required String collection,
    required String field,
    required dynamic isEqualTo,
  }) {
    return _firestore
        .collection(collection)
        .where(field, isEqualTo: isEqualTo)
        .snapshots()
        .map(
          (snaps) => snaps.docs
              .map((doc) => {'id': doc.id, ...(doc.data())})
              .toList(growable: false),
        );
  }
}
