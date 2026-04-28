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

  Future<void> delete(String notificationId) {
    return _firestore
        .collection(FirestorePaths.notifications)
        .doc(notificationId)
        .delete();
  }

  Stream<List<NotificationItem>> watchForRoleItems(String role) {
    return watchByRole(role).map((snap) => snap.docs.map((d) {
          final data = d.data();
          return NotificationItem(
            id: d.id,
            role: data['user_role'] as String? ?? role,
            message: data['message'] as String? ?? '',
            timestamp: (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate()
                : DateTime.now(),
            seen: data['seen'] as bool? ?? false,
            requestId: data['request_id'] as String?,
            stage: data['stage'] as String?,
          );
        }).toList());
  }

      /// Watch notifications for multiple role scopes using `whereIn`.
      Stream<List<NotificationItem>> watchForRolesItems(List<String> roles) {
        return _firestore
            .collection(FirestorePaths.notifications)
            .where('user_role', whereIn: roles)
            .orderBy('timestamp', descending: true)
            .snapshots()
            .map((snap) => snap.docs.map((d) {
                  final data = d.data();
                  return NotificationItem(
                    id: d.id,
                    role: data['user_role'] as String? ?? '',
                    message: data['message'] as String? ?? '',
                    timestamp: (data['timestamp'] is Timestamp)
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now(),
                    seen: data['seen'] as bool? ?? false,
                    requestId: data['request_id'] as String?,
                    stage: data['stage'] as String?,
                  );
                }).toList());
      }
}

class NotificationItem {
  NotificationItem({
    required this.id,
    required this.role,
    required this.message,
    required this.timestamp,
    this.seen = false,
    this.requestId,
    this.stage,
  });

  final String id;
  final String role;
  final String message;
  final DateTime timestamp;
  final bool seen;
  final String? requestId;
  final String? stage;
}
