import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_paths.dart';

class NotificationService {
  NotificationService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> sendNotification(
    String role,
    String message, {
    String? requestId,
    String? stage,
    String? dedupeKey,
  }) async {
    final data = <String, dynamic>{
      'user_role': role,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'seen': false,
      if (requestId != null && requestId.isNotEmpty) 'request_id': requestId,
      if (stage != null && stage.isNotEmpty) 'stage': stage,
    };

    if (dedupeKey != null && dedupeKey.isNotEmpty) {
      await _firestore
          .collection(FirestorePaths.notifications)
          .doc(dedupeKey)
          .set(data, SetOptions(merge: true));
      return;
    }

    await _firestore.collection(FirestorePaths.notifications).add(data);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchByRole(String role) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .where('user_role', isEqualTo: role)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Future<void> markSeen(String notificationId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .doc(notificationId)
        .update({'seen': true});
  }
}
