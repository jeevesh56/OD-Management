import 'package:firebase_messaging/firebase_messaging.dart';

import 'document_store.dart';
import 'firestore_paths.dart';

class FcmService {
  FcmService({
    required FirebaseMessaging messaging,
    required DocumentStore store,
  })  : _messaging = messaging,
        _store = store;

  final FirebaseMessaging _messaging;
  final DocumentStore _store;

  Future<void> registerTokenForUser(String userId) async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _store.set(
      collection: 'fcm_tokens',
      id: '${userId}_$token',
      data: {
        'user_id': userId,
        'token': token,
        'platform': 'flutter',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      merge: true,
    );
  }

  Future<void> createInAppNotification({
    required String toUserId,
    required String type,
    required String title,
    required String body,
    String? requestId,
  }) {
    final id = '${toUserId}_${DateTime.now().millisecondsSinceEpoch}';
    return _store.set(
      collection: FirestorePaths.notifications,
      id: id,
      data: {
        'notification_id': id,
        'to_user_id': toUserId,
        'type': type,
        'title': title,
        'body': body,
        'request_id': requestId,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      },
      merge: false,
    );
  }
}
