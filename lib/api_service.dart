import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Shared role colors used across OD Manager screens.
const Color kBlue = Color(0xFF1565C0);
const Color kRed = Color(0xFFB71C1C);

String getFullUrl(String path) {
  return path.trim();
}

const String kRegNumberPrefix = '2117240020';

class AuthStore {
  static String? token;
  static String? role;
  static String? userId;
  static String? fullName;
  static String? userDepartment;
  static Map<String, dynamic>? studentProfile;
  static String? studentLoginEmail;

  static String registrationFromLoginEmail([String? email]) {
    final e = (email ?? studentLoginEmail ?? '').trim();
    if (e.isEmpty) return '';
    final at = e.indexOf('@');
    final local = at > 0 ? e.substring(0, at) : e;
    final typed = local.contains('.') ? local.split('.').last : local;
    final last3 = typed.length >= 3 ? typed.substring(typed.length - 3) : typed;
    return kRegNumberPrefix + last3;
  }

  static String displayNameFromStudentEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Student';
    final i = trimmed.indexOf('@');
    if (i <= 0) return 'Student';
    final prefix = trimmed.substring(0, i);
    if (prefix.isEmpty) return 'Student';
    final firstPart = prefix.contains('.') ? prefix.split('.').first : prefix;
    if (firstPart.isEmpty) return 'Student';
    return firstPart[0].toUpperCase() + firstPart.substring(1).toLowerCase();
  }

  static bool isValidRoleEmail(String email) {
    final e = email.trim().toLowerCase();
    return RegExp(r'^[a-zA-Z]+@[a-zA-Z]+\.ritchennai\.edu\.in$').hasMatch(e);
  }

  static String roleNameFromEmail(String email) {
    final e = email.trim();
    final at = e.indexOf('@');
    if (at <= 0) return 'User';
    final raw = e.substring(0, at);
    if (raw.isEmpty) return 'User';
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }

  static String roleDepartmentFromEmail(String email) {
    final e = email.trim();
    final at = e.indexOf('@');
    if (at <= 0) return 'Department';
    final domain = e.substring(at + 1);
    final parts = domain.split('.');
    final raw = parts.isNotEmpty ? parts.first : '';
    if (raw.isEmpty) return 'Department';
    return raw.toUpperCase();
  }

  static void applyStudentLogin(String email) {
    studentLoginEmail = email.trim();
    fullName = displayNameFromStudentEmail(email);
    userDepartment = 'CSE';
    userId = registrationFromLoginEmail(email);
    studentProfile = {
      'register_number': registrationFromLoginEmail(email),
      'department': 'CSE',
      'section': 'A',
      'semester': '4',
      'batch': '2024',
      'attendance_percent': '85',
    };
    role = 'student';
  }

  static void applyMentorLogin(String input) {
    final email = input.trim();
    fullName = email.contains('@') ? roleNameFromEmail(email) : 'Mentor';
    userDepartment = email.contains('@')
        ? roleDepartmentFromEmail(email)
        : 'Department';
    role = 'mentor';
  }

  static void applyHodLogin(String input) {
    final email = input.trim();
    fullName = email.contains('@') ? roleNameFromEmail(email) : 'HoD';
    userDepartment = email.contains('@')
        ? roleDepartmentFromEmail(email)
        : 'Department';
    role = 'hod';
  }

  static void applyPrincipalLogin(String input) {
    final email = input.trim();
    fullName = email.contains('@') ? roleNameFromEmail(email) : 'Principal';
    userDepartment = email.contains('@')
        ? roleDepartmentFromEmail(email)
        : 'Department';
    role = 'principal';
  }

  static void clear() {
    token = null;
    role = null;
    userId = null;
    fullName = null;
    userDepartment = null;
    studentProfile = null;
    studentLoginEmail = null;
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
  };
}

class ApiResult<T> {
  final T? data;
  final String? error;
  bool get ok => error == null;

  ApiResult.success(this.data) : error = null;
  ApiResult.fail(this.error) : data = null;
}

class _FirestoreApi {
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get odRequests =>
      db.collection('od_requests');

  static String normalizeStatus(Map<String, dynamic> row) {
    final raw = row['status']?.toString().trim() ?? '';
    final upper = raw.toUpperCase();
    final fullyApproved =
        row['mentor_approved'] == true &&
        row['hod_approved'] == true &&
        row['principal_approved'] == true;

    if (upper == 'APPROVED' ||
        upper == 'PRINCIPAL_APPROVED' ||
        row['principal_approved'] == true ||
        fullyApproved) {
      return 'Approved';
    }
    if (upper == 'REJECTED' || upper.contains('REJECTED')) {
      return 'Rejected';
    }
    if (upper == 'EXPIRED' || row['expired'] == true) {
      return 'Expired';
    }
    return 'Pending';
  }

  static Map<String, dynamic> normalizeDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    final out = <String, dynamic>{'id': id, ...data};

    final datetime = out['datetime']?.toString().trim();
    if (datetime == null || datetime.isEmpty) {
      out['datetime'] = out['start_datetime']?.toString() ?? '';
    }

    if ((out['organizer']?.toString().trim().isEmpty ?? true) &&
        out['organiser'] != null) {
      out['organizer'] = out['organiser'];
    }

    out['mentor_approved'] = out['mentor_approved'] == true;
    out['hod_approved'] = out['hod_approved'] == true;
    out['principal_approved'] = out['principal_approved'] == true;
    out['status'] = normalizeStatus(out);
    out['expired'] = out['status'] == 'Expired';
    out['is_pinned'] = out['is_pinned'] == true;

    return out;
  }

  static Future<List<Map<String, dynamic>>> allRequests() async {
    final snap = await odRequests.orderBy('created_at', descending: true).get();
    return snap.docs.map((d) => normalizeDoc(d.id, d.data())).toList();
  }

  static Future<Map<String, dynamic>?> requestById(String id) async {
    final doc = await odRequests.doc(id).get();
    if (!doc.exists) return null;
    return normalizeDoc(doc.id, doc.data() ?? <String, dynamic>{});
  }
}

class AuthApi {
  static Future<ApiResult<Map>> login({
    required String emailOrId,
    required String password,
    String role = 'student',
  }) async {
    if (password.trim().isEmpty) {
      return ApiResult.fail('Password cannot be empty');
    }

    if (role == 'student') {
      AuthStore.applyStudentLogin(emailOrId);
    } else if (role == 'mentor') {
      AuthStore.applyMentorLogin(emailOrId);
    } else if (role == 'hod') {
      AuthStore.applyHodLogin(emailOrId);
    } else if (role == 'principal') {
      AuthStore.applyPrincipalLogin(emailOrId);
    }

    return ApiResult.success(<String, dynamic>{
      'role': AuthStore.role,
      'user_id': AuthStore.userId,
      'full_name': AuthStore.fullName,
    });
  }
}

class OdApi {
  static Future<List<dynamic>> fetchRequests() async {
    final rows = await _FirestoreApi.allRequests();
    return rows;
  }

  static Future<ApiResult<Map>> submit({
    required String eventName,
    required String datetime,
    required String venue,
    required String organizer,
    required String reason,
    String? fileUrl,
    String? attachmentBase64,
    String? attachmentMime,
    String? attachmentName,
  }) async {
    try {
      final docRef = await _FirestoreApi.odRequests.add({
        'event_name': eventName,
        'organizer': organizer,
        'organiser': organizer,
        'venue': venue,
        'datetime': datetime,
        'start_datetime': datetime,
        'reason': reason,
        'file_url': fileUrl,
        'attachment_base64': attachmentBase64,
        'attachment_mime': attachmentMime,
        'attachment_name': attachmentName,
        'status': 'Pending',
        'mentor_approved': false,
        'hod_approved': false,
        'principal_approved': false,
        'expired': false,
        'is_pinned': false,
        'created_at': FieldValue.serverTimestamp(),
        'student_name': AuthStore.fullName ?? 'Student',
        'student_id': AuthStore.userId ?? '',
      });

      final row = await _FirestoreApi.requestById(docRef.id);
      return ApiResult.success(row ?? <String, dynamic>{'id': docRef.id});
    } catch (e) {
      return ApiResult.fail('Failed to submit request: $e');
    }
  }

  static Future<ApiResult<List>> events() async {
    try {
      return ApiResult.success(await fetchRequests());
    } catch (e) {
      return ApiResult.fail('Failed to load requests: $e');
    }
  }

  static Future<ApiResult<List>> myRequests() async {
    try {
      final rows = await fetchRequests();
      return ApiResult.success(rows);
    } catch (e) {
      return ApiResult.fail('Failed to fetch requests: $e');
    }
  }

  static Future<ApiResult<Map>> resubmitRequest(
    Map<dynamic, dynamic> item,
  ) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) {
      return ApiResult.fail('Invalid request id for resubmission.');
    }

    try {
      await _FirestoreApi.odRequests.doc(id).update({
        'status': 'Pending',
        'mentor_approved': false,
        'hod_approved': false,
        'principal_approved': false,
        'expired': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
      final row = await _FirestoreApi.requestById(id);
      if (row == null) return ApiResult.fail('Request not found');
      return ApiResult.success(row);
    } catch (e) {
      return ApiResult.fail('Failed to resubmit request: $e');
    }
  }

  static Future<ApiResult<Map>> checkOverlap({
    required String startDate,
    required String endDate,
  }) async {
    return ApiResult.success(<String, dynamic>{'has_overlap': false});
  }

  static Future<ApiResult<Map>> activeSession() async {
    return ApiResult.success(<String, dynamic>{'has_active_session': false});
  }

  static Stream<List<Map<String, dynamic>>> getODRequests() {
    return _FirestoreApi.odRequests
        .orderBy('created_at', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _FirestoreApi.normalizeDoc(doc.id, doc.data()))
              .toList(),
        );
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
          'mentor_comment': comment ?? reason,
          'status': 'Pending',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'mentor_comment': comment ?? reason,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
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
          'hod_comment': reason,
          'status': 'Pending',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'hod_comment': reason,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
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
          'principal_comment': reason,
          'status': 'Approved',
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        await _FirestoreApi.odRequests.doc(requestId).update({
          'principal_comment': reason,
          'status': 'Rejected',
          'updated_at': FieldValue.serverTimestamp(),
        });
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
            row['status'] != 'Rejected';
        if (!eligible) continue;

        await _FirestoreApi.odRequests.doc(id).update({
          'principal_approved': true,
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
