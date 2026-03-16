import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Shared role colors used across OD Manager screens.
const Color kBlue = Color(0xFF1565C0);
const Color kRed = Color(0xFFB71C1C);

// ── Change this to your Flask server IP ──────────────────────────────────────
// Chrome (web):        http://localhost:5000
// Android emulator:   http://10.0.2.2:5000
// Real phone on WiFi: http://192.168.x.x:5000  ← your PC's local IP
const String kBaseUrl = 'http://localhost:5000';

// When true, all OD-related APIs return mock data instead of calling backend.
const bool kUseMockApi = true;

// ── Simple in-memory token store (no shared_preferences needed) ──────────────
/// Fixed prefix for registration numbers; only last 3 digits vary (from email).
const String kRegNumberPrefix = '2117240020';

class AuthStore {
  static String? token;
  static String? role;
  static String? userId;
  static String? fullName;
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
    final firstPart =
        prefix.contains('.') ? prefix.split('.').first : prefix;
    if (firstPart.isEmpty) return 'Student';
    return firstPart[0].toUpperCase() +
        firstPart.substring(1).toLowerCase();
  }

  /// Call when student signs in with college email (before opening StudentHomeScreen).
  static void applyStudentLogin(String email) {
    studentLoginEmail = email.trim();
    fullName = displayNameFromStudentEmail(email);
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

  /// Simple helpers for mentor / HoD names from the same email textbox.
  static void applyMentorLogin(String input) {
    final email = input.trim();
    fullName = email.contains('@')
        ? displayNameFromStudentEmail(email)
        : 'Mentor';
    role = 'mentor';
  }

  static void applyHodLogin(String input) {
    final email = input.trim();
    fullName =
        email.contains('@') ? displayNameFromStudentEmail(email) : 'HoD';
    role = 'hod';
  }

  static void clear() {
    token = null;
    role = null;
    userId = null;
    fullName = null;
    studentProfile = null;
    studentLoginEmail = null;
  }

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
}

// Simple in-memory store used when kUseMockApi is true. This lets the full
// OD life cycle (student → mentor → EC → HoD) work without a backend.
class MockOdStore {
  static int _nextId = 1;
  static final List<Map<String, dynamic>> items = [];

  static Map<String, dynamic> addRequest({
    required String eventName,
    required String organiser,
    required String venue,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    required String reason,
  }) {
    final id = (_nextId++).toString();
    final request = <String, dynamic>{
      'id': id,
      'event_name': eventName,
      'organiser': organiser,
      'venue': venue,
      'start_date': startDate,
      'end_date': endDate,
      'start_time': startTime,
      'end_time': endTime,
      'reason': reason,
      'status': 'PENDING',
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
  // Submit new OD request
  static Future<ApiResult<Map>> submit({
    required String eventName,
    required String organiser,
    required String venue,
    required String startDate, // YYYY-MM-DD
    required String endDate,
    required String startTime, // HH:MM
    required String endTime,
    required String reason,
    String? eventId,
    String? attachmentBase64, // base64 encoded file
    String? attachmentMime, // e.g. application/pdf
    String? attachmentName, // original filename
  }) async {
    if (kUseMockApi) {
      final request = MockOdStore.addRequest(
        eventName: eventName,
        organiser: organiser,
        venue: venue,
        startDate: startDate,
        endDate: endDate,
        startTime: startTime,
        endTime: endTime,
        reason: reason,
      );
      return ApiResult.success(request);
    }

    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/student/od-requests'),
            headers: AuthStore.headers,
            body: jsonEncode({
              'event_name': eventName,
              'organiser': organiser,
              'venue': venue,
              'start_date': startDate,
              'end_date': endDate,
              'start_time': startTime,
              'end_time': endTime,
              'reason': reason,
              if (eventId != null) 'event_id': eventId,
              if (attachmentBase64 != null)
                'attachment_base64': attachmentBase64,
              if (attachmentMime != null) 'attachment_mime': attachmentMime,
              if (attachmentName != null) 'attachment_name': attachmentName,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(res.body);
      if (res.statusCode == 201) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Submission failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  // Get my OD history
  static Future<ApiResult<List>> myRequests() async {
    if (kUseMockApi) {
      return ApiResult.success(List<Map<String, dynamic>>.from(MockOdStore.items));
    }

    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/student/od-requests'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return ApiResult.success(body['requests'] as List);
      }
      return ApiResult.fail(body['error'] ?? 'Failed to load');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  // Check date overlap before submitting
  static Future<ApiResult<Map>> checkOverlap({
    required String startDate,
    required String endDate,
  }) async {
    if (kUseMockApi) {
      // Very simple mock: never blocks, just says no overlap.
      return ApiResult.success(<String, dynamic>{
        'has_overlap': false,
      });
    }

    try {
      final res = await http
          .get(
            Uri.parse(
              '$kBaseUrl/api/student/check-overlap'
              '?start_date=$startDate&end_date=$endDate',
            ),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Check failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  // Active OD session
  static Future<ApiResult<Map>> activeSession() async {
    if (kUseMockApi) {
      return ApiResult.success(<String, dynamic>{
        'has_active_session': false,
      });
    }

    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/student/active-session'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }
}

// ── MENTOR ────────────────────────────────────────────────────────────────────
class MentorApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final pending = MockOdStore.items
          .where((r) => r['status'] == 'PENDING')
          .toList(growable: false);
      return ApiResult.success(pending);
    }

    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/mentor/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return ApiResult.success(body['queue'] as List);
      }
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
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
      r['status'] = action == 'APPROVED' ? 'MENTOR_APPROVED' : 'MENTOR_REJECTED';
      return ApiResult.success(r);
    }

    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/mentor/action'),
            headers: AuthStore.headers,
            body: jsonEncode({
              'request_id': requestId,
              'action': action,
              if (reason != null) 'reason': reason,
              if (comment != null) 'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Action failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<List>> history() async {
    if (kUseMockApi) {
      final items = MockOdStore.items.where((r) {
        final s = r['status']?.toString() ?? '';
        return s == 'MENTOR_APPROVED' || s == 'MENTOR_REJECTED';
      }).toList(growable: false);
      return ApiResult.success(items);
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/mentor/history'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return ApiResult.success(body['items'] as List? ?? []);
      }
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }
}

// ── EC ────────────────────────────────────────────────────────────────────────
class ECApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final pending = MockOdStore.items
          .where((r) => r['status'] == 'MENTOR_APPROVED')
          .toList(growable: false);
      return ApiResult.success(pending);
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/ec/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body['queue'] as List);
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action, // CONFIRMED | REJECTED
    String? reason,
  }) async {
    if (kUseMockApi) {
      final r = MockOdStore.byId(requestId);
      if (r == null) {
        return ApiResult.fail('Request not found');
      }
      r['ec_comment'] = reason;
      r['status'] = action == 'CONFIRMED' ? 'EC_CONFIRMED' : 'EC_REJECTED';
      return ApiResult.success(r);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/ec/action'),
            headers: AuthStore.headers,
            body: jsonEncode({
              'request_id': requestId,
              'action': action,
              if (reason != null) 'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Action failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }
}

// ── HOD ───────────────────────────────────────────────────────────────────────
class HoDApi {
  static Future<ApiResult<List>> queue() async {
    if (kUseMockApi) {
      final pending = MockOdStore.items.where((r) {
        final s = r['status'] as String? ?? '';
        // In mock mode, HoD sees requests approved by mentor (no EC step).
        return s == 'MENTOR_APPROVED' || s == 'EC_CONFIRMED';
      }).toList(growable: false);
      return ApiResult.success(pending);
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body['queue'] as List);
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
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
      r['status'] = action == 'APPROVED' ? 'HOD_APPROVED' : 'HOD_REJECTED';
      return ApiResult.success(r);
    }
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/hod/action'),
            headers: AuthStore.headers,
            body: jsonEncode({
              'request_id': requestId,
              'action': action,
              if (reason != null) 'reason': reason,
            }),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Action failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map>> bulkAction(String eventId) async {
    if (kUseMockApi) {
      for (final r in MockOdStore.items) {
        if (r['status'] == 'EC_CONFIRMED') {
          r['status'] = 'HOD_APPROVED';
        }
      }
      return ApiResult.success({'ok': true});
    }
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/hod/bulk-action'),
            headers: AuthStore.headers,
            body: jsonEncode({'event_id': eventId, 'action': 'APPROVED'}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Bulk action failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map>> analytics() async {
    if (kUseMockApi) {
      final total = MockOdStore.items.length;
      final approved = MockOdStore.items
          .where((r) => r['status'] == 'HOD_APPROVED')
          .length;
      final pending = MockOdStore.items.where((r) {
        final s = r['status']?.toString() ?? '';
        return s == 'PENDING' ||
            s == 'MENTOR_APPROVED' ||
            s == 'EC_CONFIRMED';
      }).length;
      final rejected = MockOdStore.items.where((r) {
        final s = r['status']?.toString() ?? '';
        return s.contains('REJECTED') || s == 'CANCELLED';
      }).length;
      final activeNow = 0;
      return ApiResult.success({
        'total': total,
        'approved': approved,
        'pending': pending,
        'rejected': rejected,
        'active_now': activeNow,
      });
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/analytics'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) return ApiResult.success(body);
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<List>> history() async {
    if (kUseMockApi) {
      final items = MockOdStore.items.where((r) {
        final s = r['status']?.toString() ?? '';
        return s == 'HOD_APPROVED' || s == 'HOD_REJECTED';
      }).toList(growable: false);
      return ApiResult.success(items);
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/history'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return ApiResult.success(body['items'] as List? ?? []);
      }
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }

  static Future<ApiResult<List>> activeSessions() async {
    if (kUseMockApi) {
      return ApiResult.success(const []);
    }
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/active-sessions'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return ApiResult.success(body['sessions'] as List? ?? []);
      }
      return ApiResult.fail(body['error'] ?? 'Failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
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
      return ApiResult.fail(body['error'] ?? 'Scan failed');
    } catch (e) {
      return ApiResult.fail('Network error: $e');
    }
  }
}

