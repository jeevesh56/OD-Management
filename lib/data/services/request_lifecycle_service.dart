import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/enums/od_status.dart';
import 'firestore_paths.dart';

class RequestLifecycleService {
  RequestLifecycleService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> checkAndExpireRequests() async {
    if (_auth.currentUser == null) return;

    try {
      final snapshot =
          await _firestore.collection(FirestorePaths.odRequests).get();

      if (_auth.currentUser == null) return;

      final now = DateTime.now();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final alreadyExpired = data['expired'] == true ||
            data['status']?.toString().toUpperCase() ==
                OdStatus.expired.value;

        if (alreadyExpired) continue;

        final eventDate =
            _parseDate(data['datetime']) ??
            _parseDate(data['start_datetime']);

        if (eventDate == null) continue;

        final fullyApproved = _isFullyApproved(data);

        if (now.isAfter(eventDate) && !fullyApproved) {
          try {
            await _firestore
                .collection(FirestorePaths.odRequests)
                .doc(doc.id)
                .update({
              'status': OdStatus.expired.value,
              'expired': true,
              'updated_at': now.toIso8601String(),
            });
          } catch (_) {
            // Ignore individual update failures.
          }
        }
      }
    } catch (e) {
      // Log failures during development.
    }
  }

  Future<void> togglePin(String id, bool current) {
    return _firestore.collection(FirestorePaths.odRequests).doc(id).update({
      'is_pinned': !current,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  bool _isFullyApproved(Map<String, dynamic> data) {
    final status = data['status']?.toString().toUpperCase() ?? '';

    if (status == OdStatus.principalApproved.value) return true;

    return data['mentor_approved'] == true &&
        data['hod_approved'] == true &&
        data['principal_approved'] == true;
  }

  DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();

    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }

    return null;
  }
}