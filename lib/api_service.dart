import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'data/services/firestore_paths.dart';

// Shared role colors used across OD Manager screens.

// Shared role colors used across OD Manager screens.
const Color kBlue = Color(0xFF1565C0);
const Color kRed = Color(0xFFB71C1C);

String getFullUrl(String path) => path.trim();

// All data, auth, and Firestore logic is now handled by repository/services layer.
class ApiResult<T> {
  ApiResult.success(this.data) : ok = true, error = null;
  ApiResult.fail(this.error) : ok = false, data = null;

  final bool ok;
  final T? data;
  final String? error;
}

class AuthStore {
  static String role = 'student';
  static String? fullName;
  static Map<String, dynamic>? studentProfile;
  static String? _loginEmail;

  static void setLoginEmail(String? email) => _loginEmail = email;

  static String registrationFromLoginEmail() {
    final email = _loginEmail?.trim().toLowerCase() ?? '';
    if (email.isEmpty || !email.contains('@')) return '';
    return email.split('@').first;
  }

  static void clear() {
    role = 'student';
    fullName = null;
    studentProfile = null;
    _loginEmail = null;
  }
}

class _FirestoreApi {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static CollectionReference<Map<String, dynamic>> get odRequests =>
      _db.collection(FirestorePaths.odRequests);
  static CollectionReference<Map<String, dynamic>> get notifications =>
      _db.collection(FirestorePaths.notifications);

  static Future<List<Map<String, dynamic>>> allRequests() async {
    final snap = await odRequests.orderBy('updated_at', descending: true).get();
    return snap.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
  }

  static Future<Map<String, dynamic>?> requestById(String id) async {
    final doc = await odRequests.doc(id).get();
    if (!doc.exists) return null;
    return <String, dynamic>{'id': doc.id, ...?doc.data()};
  }

  static Future<void> sendRoleNotification({
    required String role,
    required String title,
    required String body,
    String? requestId,
  }) async {
    await notifications.add({
      'role': role,
      'title': title,
      'message': body,
      'request_id': requestId,
      'seen': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

class OdApi {
  static Future<ApiResult<List>> myRequests() async {
    try {
      return ApiResult.success(await _FirestoreApi.allRequests());
    } catch (e) {
      return ApiResult.fail('Failed to load requests: $e');
    }
  }

  static Future<ApiResult<Map>> activeSession() async {
    return ApiResult.success({'has_active_session': false});
  }

  static Future<ApiResult<Map>> resubmitRequest(Map item) async {
    try {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return ApiResult.fail('Missing request id');
      await _FirestoreApi.odRequests.doc(id).update({
        'rejected': false,
        'status': 'Pending',
        'updated_at': FieldValue.serverTimestamp(),
      });
      final updated = await _FirestoreApi.requestById(id);
      if (updated == null) return ApiResult.fail('Request not found');
      return ApiResult.success(updated);
    } catch (e) {
      return ApiResult.fail('Resubmit failed: $e');
    }
  }
}

class MentorApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final all = await _FirestoreApi.allRequests();
      final rows = all
          .where(
            (r) =>
                r['mentor_approved'] != true &&
                r['rejected'] != true &&
                r['status'] != 'Rejected' &&
                r['status'] != 'Approved',
          )
          .toList();
      return ApiResult.success(rows);
    } catch (e) {
      return ApiResult.fail('Failed to load mentor queue: $e');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
    String? comment,
  }) async {
    try {
      if (action == 'APPROVED') {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'mentor_approved': true,
          'rejected': false,
          'mentor_comment': comment ?? reason,
          'status': 'Pending',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'hod',
          title: 'OD Approved by Mentor',
          body: 'Request moved to HOD',
          requestId: requestId,
        );
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'mentor_comment': comment ?? reason,
          'rejected': true,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'student',
          title: 'OD Rejected',
          body: 'Your OD was rejected',
          requestId: requestId,
        );
      }

      final row = await _FirestoreApi.requestById(requestId);
      if (row == null) return ApiResult.fail('Request not found');
      return ApiResult.success(row);
    } catch (e) {
      return ApiResult.fail('Mentor action failed: $e');
    }
  }

  static Future<ApiResult<List>> history() async {
    try {
      return ApiResult.success(await _FirestoreApi.allRequests());
    } catch (e) {
      return ApiResult.fail('Failed to load history: $e');
    }
  }
}

class HoDApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final all = await _FirestoreApi.allRequests();
      final rows = all
          .where(
            (r) =>
                r['mentor_approved'] == true &&
                r['hod_approved'] != true &&
                r['rejected'] != true &&
                r['status'] != 'Rejected' &&
                r['status'] != 'Approved',
          )
          .toList();
      return ApiResult.success(rows);
    } catch (e) {
      return ApiResult.fail('Failed to load HoD queue: $e');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    try {
      if (action == 'APPROVED') {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'hod_approved': true,
          'rejected': false,
          'hod_comment': reason,
          'status': 'Pending',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'principal',
          title: 'OD Approved by HOD',
          body: 'Request moved to Principal',
          requestId: requestId,
        );
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'hod_comment': reason,
          'rejected': true,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'student',
          title: 'OD Rejected',
          body: 'Your OD was rejected',
          requestId: requestId,
        );
      }

      final row = await _FirestoreApi.requestById(requestId);
      if (row == null) return ApiResult.fail('Request not found');
      return ApiResult.success(row);
    } catch (e) {
      return ApiResult.fail('HoD action failed: $e');
    }
  }

  static Future<ApiResult<Map>> bulkAction(String eventId) async {
    return ApiResult.fail('Bulk approval moved to Principal role.');
  }

  static Future<ApiResult<Map>> analytics() async {
    final items = await _FirestoreApi.allRequests();
    final total = items.length;
    final approved = items
        .where((e) => (e['status']?.toString() ?? '') == 'Approved')
        .length;
    final rejected = items
        .where((e) => (e['status']?.toString() ?? '') == 'Rejected')
        .length;

    return ApiResult.success({
      'total': total,
      'approved': approved,
      'pending': total - approved - rejected,
      'rejected': rejected,
      'active_now': 0,
    });
  }

  static Future<ApiResult<List>> history() async {
    try {
      return ApiResult.success(await _FirestoreApi.allRequests());
    } catch (e) {
      return ApiResult.fail('Failed to load history: $e');
    }
  }

  static Future<ApiResult<List>> activeSessions() async {
    return ApiResult.success(const []);
  }
}

class PrincipalApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final all = await _FirestoreApi.allRequests();
      final rows = all
          .where(
            (r) =>
                r['hod_approved'] == true &&
                r['principal_approved'] != true &&
                r['rejected'] != true &&
                r['status'] != 'Rejected' &&
                r['status'] != 'Approved',
          )
          .toList();
      return ApiResult.success(rows);
    } catch (e) {
      return ApiResult.fail('Failed to load principal queue: $e');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    try {
      if (action == 'APPROVED') {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'principal_approved': true,
          'rejected': false,
          'principal_comment': reason,
          'status': 'Approved',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'student',
          title: 'OD Approved',
          body: 'Your OD is approved',
          requestId: requestId,
        );
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'principal_comment': reason,
          'rejected': true,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _FirestoreApi.sendRoleNotification(
          role: 'student',
          title: 'OD Rejected',
          body: 'Your OD was rejected',
          requestId: requestId,
        );
      }

      final row = await _FirestoreApi.requestById(requestId);
      if (row == null) return ApiResult.fail('Request not found');
      return ApiResult.success(row);
    } catch (e) {
      return ApiResult.fail('Principal action failed: $e');
    }
  }

  static Future<ApiResult<Map>> bulkApprove(List<String> ids) async {
    if (ids.isEmpty) {
      return ApiResult.success({'message': 'Bulk approved', 'count': 0});
    }

    var count = 0;
    for (final id in ids) {
      try {
        final row = await _FirestoreApi.requestById(id);
        if (row == null) continue;
        final eligible =
            row['hod_approved'] == true &&
            row['principal_approved'] != true &&
            row['rejected'] != true &&
            row['status'] != 'Rejected';
        if (!eligible) continue;

        await _FirestoreApi.odRequests.doc(id).update({
          'principal_approved': true,
          'rejected': false,
          'status': 'Approved',
          'updated_at': FieldValue.serverTimestamp(),
        });
        count++;
      } catch (_) {
        // Continue bulk processing even if one document update fails.
      }
    }

    return ApiResult.success({
      'message': '$count requests approved',
      'count': count,
    });
  }

  static Future<ApiResult<List>> history() async {
    try {
      return ApiResult.success(await _FirestoreApi.allRequests());
    } catch (e) {
      return ApiResult.fail('Failed to load history: $e');
    }
  }
}

class VerifyApi {
  static Future<ApiResult<Map>> scan(String uniqueId) async {
    return ApiResult.fail(
      'QR verification backend removed; use Firebase flow.',
    );
  }
}
