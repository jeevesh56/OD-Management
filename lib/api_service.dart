import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Shared role colors used across OD Manager screens.
const Color kBlue = Color(0xFF1565C0);
const Color kRed = Color(0xFFB71C1C);

// ── Local Flask backend URLs ─────────────────────────────────────────────────
// Chrome (web):        http://127.0.0.1:5000
// Android emulator:   http://10.0.2.2:5000
// Real phone on WiFi: http://192.168.x.x:5000  ← your PC's local IP
const String baseUrl = "http://127.0.0.1:5000";
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: baseUrl,
);

/// Backend may return file paths like `/uploads/filename.ext`.
/// Convert them into absolute URLs usable by Flutter widgets.
String getFullUrl(String path) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return '';
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.hasScheme) return trimmed;
  return Uri.parse(kBaseUrl).resolve(trimmed).toString();
}

// Enable with `--dart-define=USE_MOCK=true` when you want in-memory demo data.
const bool kUseMockApi = bool.fromEnvironment(
  'USE_MOCK',
  defaultValue: false,
);

// When false (default), backend/network failures are surfaced as errors
// instead of silently falling back to in-memory mock data.
const bool kAllowOfflineFallback = bool.fromEnvironment(
  'ALLOW_OFFLINE_FALLBACK',
  defaultValue: false,
);

void _logApiError(String endpoint, Object error) {
  debugPrint('[API ERROR] $endpoint -> $error');
}

void _logApiCall(String message) {
  debugPrint('[API] $message');
}

String _errorFromBody(dynamic body, String fallback) {
  if (body is Map) {
    final detail = body['detail']?.toString();
    if (detail != null && detail.isNotEmpty) return detail;
    final error = body['error']?.toString();
    if (error != null && error.isNotEmpty) return error;
    final message = body['message']?.toString();
    if (message != null && message.isNotEmpty) return message;
  }
  return fallback;
}

// ── Simple in-memory token store (no shared_preferences needed) ──────────────
/// Fixed prefix for registration numbers; only last 3 digits vary (from email).
const String kRegNumberPrefix = '2117240020';

class AuthStore {
  static String? token;
  static String? role;
  static String? userId;
  static String? fullName;
  static String? userDepartment;
  static Map<String, dynamic>? studentProfile;

  /// Set on student login; used to derive registration number for QR.
  static String? studentLoginEmail;

  /// Full registration number from login email: prefix "2117240020" + last 3 digits of typed number.
  /// e.g. jeevesh.240158@... → 2117240020158; 240160 → 2117240020160.
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

  /// Call when student signs in with college email (before opening StudentHomeScreen).
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
  }

  /// Simple helpers for staff names from the same email textbox.
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
    if (token != null) 'Authorization': 'Bearer $token',
  };
}

// Simple in-memory store used when kUseMockApi is true. This lets the full
// OD life cycle (student → mentor → HoD → principal) work without a backend.
class MockOdStore {
  static int _nextId = 1;
  static final List<Map<String, dynamic>> items = [];

  static Map<String, dynamic> addRequest({
    required String eventName,
    required String organiser,
    required String venue,
    required String datetime,
    required String reason,
    String? eventId,
    String? attachmentName,
    String? attachmentMime,
    String? attachmentBase64,
  }) {
    final id = (_nextId++).toString();
    final request = <String, dynamic>{
      'id': id,
      'event_name': eventName,
      'organiser': organiser,
      'venue': venue,
      'datetime': datetime,
      'reason': reason,
      'event_id': eventId,
      'attachment_name': attachmentName,
      'attachment_mime': attachmentMime,
      'attachment_base64': attachmentBase64,
      'status': 'Pending',
      'mentor_approved': false,
      'hod_approved': false,
      'principal_approved': false,
      'created_at': DateTime.now().toIso8601String(),
      'student_name': AuthStore.fullName ?? 'Student',
    };
    items.insert(0, request);
    return request;
  }

  static Map<String, dynamic>? byId(String id) {
    try {
      return items.firstWhere((r) => r['id'] == id);
    } catch (_) {
      return null;
    }
  }
}

// ── API RESULT wrapper ────────────────────────────────────────────────────────
class ApiResult<T> {
  final T? data;
  final String? error;
  bool get ok => error == null;

  ApiResult.success(this.data) : error = null;
  ApiResult.fail(this.error) : data = null;
}

// ── AUTH ──────────────────────────────────────────────────────────────────────
class AuthApi {
  static Future<ApiResult<Map>> login({
    required String emailOrId,
    required String password,
    String role = 'student',
  }) async {
    // Map register number / staff ID to email format for the backend
    // Backend uses email — students log in with reg number as email prefix
    final email = emailOrId.contains('@') ? emailOrId : '$emailOrId@rit.edu';

    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        AuthStore.token = body['access_token'];
        AuthStore.role = body['user']['role'];
        AuthStore.userId = body['user']['user_id'];
        AuthStore.fullName = body['user']['full_name'];
        AuthStore.studentProfile = body['student_profile'];
        AuthStore.studentLoginEmail = email;
        return ApiResult.success(body);
      } else {
        return ApiResult.fail(body['error'] ?? 'Login failed');
      }
    } catch (e) {
      return ApiResult.fail('Cannot connect to server. Is Flask running?');
    }
  }
}

// ── OD REQUESTS ───────────────────────────────────────────────────────────────
class OdApi {
  static Future<List<dynamic>> fetchRequests() async {
    if (kUseMockApi) {
      return List<Map<String, dynamic>>.from(MockOdStore.items);
    }

    final uri = Uri.parse(
      '$kBaseUrl/od-requests?ts=${DateTime.now().millisecondsSinceEpoch}',
    );
    final res = await http
        .get(uri, headers: AuthStore.headers)
        .timeout(const Duration(seconds: 5));
    final dynamic body = jsonDecode(res.body);
    if (res.statusCode != 200) {
      throw Exception(_errorFromBody(body, 'Failed to load requests'));
    }
    if (body is List) return body;
    if (body is Map && body['requests'] is List) return body['requests'] as List;
    return const [];
  }

  // Submit new OD request
  static Future<ApiResult<Map>> submit({
    required String eventName,
    required String datetime,
    required String venue,
    required String organizer,
    required String reason,
    String? fileUrl,
    String? attachmentBase64, // base64 encoded file
    String? attachmentMime, // e.g. application/pdf
    String? attachmentName, // original filename
  }) async {
    if (kUseMockApi) {
      final request = MockOdStore.addRequest(
        eventName: eventName,
        organiser: organizer,
        venue: venue,
        datetime: datetime,
        reason: reason,
        attachmentName: attachmentName,
        attachmentMime: attachmentMime,
        attachmentBase64: attachmentBase64,
      );
      return ApiResult.success(request);
    }

    final hasAttachment =
      attachmentBase64 != null && attachmentBase64.trim().isNotEmpty;

    try {
      _logApiCall('POST /od-request event="$eventName" venue="$venue" hasFile=$hasAttachment');
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/od-request'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'event_name': eventName,
              'organizer': organizer,
              'venue': venue,
              'datetime': datetime,
              'reason': reason,
              if (fileUrl != null && fileUrl.trim().isNotEmpty) 'file_url': fileUrl,
              'attachment_base64': ?attachmentBase64,
              'attachment_mime': ?attachmentMime,
              'attachment_name': ?attachmentName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final dynamic decoded = jsonDecode(res.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};
      _logApiCall('POST /od-request -> ${res.statusCode}');
      if (res.statusCode == 200 || res.statusCode == 201) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Submission failed'));
    } catch (e) {
      _logApiError('POST /od-request', e);
      if (kAllowOfflineFallback) {
        final request = MockOdStore.addRequest(
          eventName: eventName,
          organiser: organizer,
          venue: venue,
          datetime: datetime,
          reason: reason,
          attachmentName: attachmentName,
          attachmentMime: attachmentMime,
          attachmentBase64: attachmentBase64,
        );
        return ApiResult.success(request);
      }
      return ApiResult.fail('Backend unavailable. Request was not saved. Check http://127.0.0.1:5000 and server logs.');
    }
  }

  static Future<ApiResult<List>> events() async {
    try {
      final items = await fetchRequests();
      return ApiResult.success(items);
    } catch (e) {
      _logApiError('GET /od-requests', e);
      if (kAllowOfflineFallback) {
        return ApiResult.success(List<Map<String, dynamic>>.from(MockOdStore.items));
      }
      return ApiResult.fail('Backend unavailable. Unable to load requests.');
    }
  }

  // Get my OD history
  static Future<ApiResult<List>> myRequests() async {
    try {
      final items = await fetchRequests();
      return ApiResult.success(items);
    } catch (e) {
      _logApiError('GET /od-requests', e);
      if (kAllowOfflineFallback) {
        return ApiResult.success(
          List<Map<String, dynamic>>.from(MockOdStore.items),
        );
      }
      return ApiResult.fail('Backend unavailable. Unable to fetch requests.');
    }
  }

  static Future<ApiResult<Map>> resubmitRequest(Map<dynamic, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) {
      return ApiResult.fail('Invalid request id for resubmission.');
    }

    if (kUseMockApi) {
      final row = MockOdStore.byId(id);
      if (row == null) return ApiResult.fail('Request not found');
      row['status'] = 'Pending';
      return ApiResult.success(row);
    }

    try {
      final res = await http
          .put(
            Uri.parse('$kBaseUrl/od-request/$id/resubmit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(item),
          )
          .timeout(const Duration(seconds: 10));

      final dynamic decoded = jsonDecode(res.body);
      final body = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'data': decoded};

      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Resubmit failed'));
    } catch (e) {
      _logApiError('PUT /od-request/{id}/resubmit', e);
      if (kAllowOfflineFallback) {
        final row = MockOdStore.byId(id);
        if (row == null) return ApiResult.fail('Request not found');
        row['status'] = 'Pending';
        return ApiResult.success(row);
      }
      return ApiResult.fail('Backend unavailable. Unable to resubmit request.');
    }
  }

  // Check date overlap before submitting
  static Future<ApiResult<Map>> checkOverlap({
    required String startDate,
    required String endDate,
  }) async {
    return ApiResult.success(<String, dynamic>{'has_overlap': false});
  }

  // Active OD session
  static Future<ApiResult<Map>> activeSession() async {
    return ApiResult.success(<String, dynamic>{'has_active_session': false});
  }
}

// ── MENTOR ────────────────────────────────────────────────────────────────────
class MentorApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final items = MockOdStore.items
          .where((r) => !(r['mentor_approved'] == true) && r['status'] != 'Rejected')
          .toList();
      return ApiResult.success(items);
    }
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/od-requests/mentor'), headers: AuthStore.headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body as List);
      return ApiResult.fail(_errorFromBody(body, 'Failed to load mentor queue'));
    } catch (e) {
      _logApiError('GET /od-requests/mentor', e);
      return ApiResult.success(MockOdStore.items);
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action, // APPROVED | REJECTED
    String? reason,
    String? comment,
  }) async {
    if (kUseMockApi) {
      final r = MockOdStore.byId(requestId);
      if (r == null) {
        return ApiResult.fail('Request not found');
      }
      r['mentor_comment'] = comment ?? reason;
      if (action == 'APPROVED') {
        r['mentor_approved'] = true;
      } else {
        r['status'] = 'Rejected';
      }
      return ApiResult.success(r);
    }

    try {
      final endpoint = action == 'APPROVED'
          ? '$kBaseUrl/od-request/$requestId/approve/mentor'
          : '$kBaseUrl/od-request/$requestId/reject';
      final res = await http
          .put(
            Uri.parse(endpoint),
            headers: AuthStore.headers,
            body: action == 'APPROVED' ? null : jsonEncode({'reason': reason ?? ''}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Action failed'));
    } catch (e) {
      _logApiError('PUT /od-request/{id}/approve|reject', e);
      if (kAllowOfflineFallback) {
        final r = MockOdStore.byId(requestId);
        if (r == null) {
          return ApiResult.fail('Request not found');
        }
        r['mentor_comment'] = comment ?? reason;
        if (action == 'APPROVED') {
          r['mentor_approved'] = true;
        } else {
          r['status'] = 'Rejected';
        }
        return ApiResult.success(r);
      }
      return ApiResult.fail('Backend unavailable. Mentor action not saved.');
    }
  }

  static Future<ApiResult<List>> history() async {
    try {
      return ApiResult.success(await OdApi.fetchRequests());
    } catch (e) {
      _logApiError('GET /od-requests', e);
      return ApiResult.success(MockOdStore.items);
    }
  }
}

// ── HOD ───────────────────────────────────────────────────────────────────────
class HoDApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final items = MockOdStore.items
          .where((r) => r['mentor_approved'] == true && r['hod_approved'] != true && r['status'] != 'Rejected')
          .toList();
      return ApiResult.success(items);
    }
    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/od-requests/hod'), headers: AuthStore.headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body as List);
      return ApiResult.fail(_errorFromBody(body, 'Failed to load HoD queue'));
    } catch (e) {
      _logApiError('GET /od-requests/hod', e);
      return ApiResult.success(MockOdStore.items);
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    if (kUseMockApi) {
      final r = MockOdStore.byId(requestId);
      if (r == null) {
        return ApiResult.fail('Request not found');
      }
      r['hod_comment'] = reason;
      if (action == 'APPROVED') {
        r['hod_approved'] = true;
      } else {
        r['status'] = 'Rejected';
      }
      return ApiResult.success(r);
    }
    try {
      final endpoint = action == 'APPROVED'
          ? '$kBaseUrl/od-request/$requestId/approve/hod'
          : '$kBaseUrl/od-request/$requestId/reject';
      final res = await http
          .put(
            Uri.parse(endpoint),
            headers: AuthStore.headers,
            body: action == 'APPROVED' ? null : jsonEncode({'reason': reason ?? ''}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Action failed'));
    } catch (e) {
      _logApiError('PUT /od-request/{id}/approve|reject', e);
      if (kAllowOfflineFallback) {
        final r = MockOdStore.byId(requestId);
        if (r == null) {
          return ApiResult.fail('Request not found');
        }
        r['hod_comment'] = reason;
        if (action == 'APPROVED') {
          r['hod_approved'] = true;
        } else {
          r['status'] = 'Rejected';
        }
        return ApiResult.success(r);
      }
      return ApiResult.fail('Backend unavailable. HoD action not saved.');
    }
  }

  static Future<ApiResult<Map>> bulkAction(String eventId) async {
    return ApiResult.fail('Bulk approval moved to Principal role.');
  }

  static Future<ApiResult<Map>> analytics() async {
    final itemsRes = await OdApi.fetchRequests();
    final total = itemsRes.length;
    var approved = 0;
    var rejected = 0;
    for (final item in itemsRes) {
      final row = item as Map;
      final status = row['status']?.toString() ?? '';
      if (status == 'Approved') approved++;
      if (status == 'Rejected') rejected++;
    }
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
      return ApiResult.success(await OdApi.fetchRequests());
    } catch (e) {
      return ApiResult.success(MockOdStore.items);
    }
  }

  static Future<ApiResult<List>> activeSessions() async {
    return ApiResult.success(const []);
  }
}

// ── PRINCIPAL ────────────────────────────────────────────────────────────────
class PrincipalApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final items = MockOdStore.items
          .where((r) => r['hod_approved'] == true && r['principal_approved'] != true && r['status'] != 'Rejected')
          .toList();
      return ApiResult.success(items);
    }

    try {
      final res = await http
          .get(Uri.parse('$kBaseUrl/od-requests/principal'), headers: AuthStore.headers)
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body as List);
      return ApiResult.fail(_errorFromBody(body, 'Failed to load principal queue'));
    } catch (e) {
      _logApiError('GET /od-requests/principal', e);
      return ApiResult.success(MockOdStore.items);
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    if (kUseMockApi) {
      final r = MockOdStore.byId(requestId);
      if (r == null) return ApiResult.fail('Request not found');
      r['principal_comment'] = reason;
      if (action == 'APPROVED') {
        r['principal_approved'] = true;
        r['status'] = 'Approved';
      } else {
        r['status'] = 'Rejected';
      }
      return ApiResult.success(r);
    }

    try {
      final endpoint = action == 'APPROVED'
          ? '$kBaseUrl/od-request/$requestId/approve/principal'
          : '$kBaseUrl/od-request/$requestId/reject';
      final res = await http
          .put(
            Uri.parse(endpoint),
            headers: AuthStore.headers,
            body: action == 'APPROVED' ? null : jsonEncode({'reason': reason ?? ''}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Action failed'));
    } catch (e) {
      _logApiError('PUT /od-request/{id}/approve/principal|reject', e);
      return ApiResult.fail('Backend unavailable. Principal action not saved.');
    }
  }

  static Future<ApiResult<Map>> bulkApprove(List<String> ids) async {
    if (ids.isEmpty) {
      return ApiResult.success({'message': 'Bulk approved', 'count': 0});
    }

    if (kUseMockApi) {
      var count = 0;
      final selected = ids.toSet();
      for (final r in MockOdStore.items) {
        final requestId = r['id']?.toString() ?? '';
        if (selected.contains(requestId) &&
            r['hod_approved'] == true &&
            r['principal_approved'] != true &&
            r['status'] != 'Rejected') {
          r['principal_approved'] = true;
          r['status'] = 'Approved';
          count++;
        }
      }
      return ApiResult.success({'message': '$count requests approved', 'count': count});
    }

    try {
      final res = await http
          .put(
            Uri.parse('$kBaseUrl/bulk-approve'),
            headers: AuthStore.headers,
            body: jsonEncode({'ids': ids}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Bulk approve failed'));
    } catch (e) {
      _logApiError('PUT /bulk-approve', e);
      return ApiResult.fail('Backend unavailable. Principal bulk approve failed.');
    }
  }
}

// ── VERIFY ────────────────────────────────────────────────────────────────────
class VerifyApi {
  static Future<ApiResult<Map>> scan(String uniqueId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/verify/$uniqueId'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(_errorFromBody(body, 'Scan failed'));
    } catch (e) {
      if (kUseMockApi) {
        return ApiResult.fail('Invalid QR (mock mode) or offline');
      }
      return ApiResult.fail('Network error: $e');
    }
  }
}
