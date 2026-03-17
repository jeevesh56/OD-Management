import 'dart:convert';

import 'package:http/http.dart' as http;

// ── Change this to your Flask server IP ──────────────────────────────────────
// Chrome (web):        http://localhost:5000
// Android emulator:   http://10.0.2.2:5000
// Real phone on WiFi: http://192.168.x.x:5000  ← your PC's local IP
const String kBaseUrl = 'http://localhost:5000';

// ── Simple in-memory token store (no shared_preferences needed) ──────────────
class AuthStore {
  static String? token;
  static String? role;
  static String? userId;
  static String? fullName;
  static Map<String, dynamic>? studentProfile;

  static void clear() {
    token = null;
    role = null;
    userId = null;
    fullName = null;
    studentProfile = null;
  }

  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };
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
  static Future<ApiResult<Map<String, dynamic>>> login({
    required String emailOrId,
    required String password,
    String role = 'student',
  }) async {
    // Map register number / staff ID to email format for the backend
    // Backend uses email — students log in with reg number as email prefix
    final email = emailOrId.contains('@')
        ? emailOrId
        : '$emailOrId@rit.edu';

    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        AuthStore.token = body['access_token'] as String?;
        final user = body['user'] as Map<String, dynamic>? ?? {};
        AuthStore.role = user['role'] as String?;
        AuthStore.userId = user['user_id'] as String?;
        AuthStore.fullName = user['full_name'] as String?;
        final profile = body['student_profile'];
        AuthStore.studentProfile = profile == null
            ? null
            : Map<String, dynamic>.from(profile as Map);
        return ApiResult<Map<String, dynamic>>.success(body);
      } else {
        final error = body['error']?.toString() ?? 'Login failed';
        return ApiResult<Map<String, dynamic>>.fail(error);
      }
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail(
        'Cannot connect to server. Is Flask running?',
      );
    }
  }
}

// ── OD REQUESTS ───────────────────────────────────────────────────────────────
class OdApi {
  // Submit new OD request
  static Future<ApiResult<Map<String, dynamic>>> submit({
    required String eventName,
    required String organiser,
    required String venue,
    required String startDate,    // YYYY-MM-DD
    required String endDate,
    required String startTime,    // HH:MM
    required String endTime,
    required String reason,
    String? eventId,
    String? attachmentBase64,     // base64 encoded file
    String? attachmentMime,       // e.g. application/pdf
    String? attachmentName,       // original filename
  }) async {
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

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 201) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Submission failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }

  // Get my OD history
  static Future<ApiResult<List<dynamic>>> myRequests() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/student/od-requests'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['requests'] as List?)?.cast<dynamic>() ?? <dynamic>[];
        return ApiResult<List<dynamic>>.success(list);
      }
      final error = body['error']?.toString() ?? 'Failed to load';
      return ApiResult<List<dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<List<dynamic>>.fail('Network error: $e');
    }
  }

  // Check date overlap before submitting
  static Future<ApiResult<Map<String, dynamic>>> checkOverlap({
    required String startDate,
    required String endDate,
  }) async {
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

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Check failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }

  // Active OD session
  static Future<ApiResult<Map<String, dynamic>>> activeSession() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/student/active-session'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }
}

// ── MENTOR ────────────────────────────────────────────────────────────────────
class MentorApi {
  static Future<ApiResult<List<dynamic>>> queue() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/mentor/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['queue'] as List?)?.cast<dynamic>() ?? <dynamic>[];
        return ApiResult<List<dynamic>>.success(list);
      }
      final error = body['error']?.toString() ?? 'Failed';
      return ApiResult<List<dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<List<dynamic>>.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> action({
    required String requestId,
    required String action,   // APPROVED | REJECTED
    String? reason,
    String? comment,
  }) async {
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Action failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }
}

// ── EC ────────────────────────────────────────────────────────────────────────
class ECApi {
  static Future<ApiResult<List<dynamic>>> queue() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/ec/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['queue'] as List?)?.cast<dynamic>() ?? <dynamic>[];
        return ApiResult<List<dynamic>>.success(list);
      }
      final error = body['error']?.toString() ?? 'Failed';
      return ApiResult<List<dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<List<dynamic>>.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> action({
    required String requestId,
    required String action,   // CONFIRMED | REJECTED
    String? reason,
  }) async {
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Action failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }
}

// ── HOD ───────────────────────────────────────────────────────────────────────
class HoDApi {
  static Future<ApiResult<List<dynamic>>> queue() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/queue'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        final list = (body['queue'] as List?)?.cast<dynamic>() ?? <dynamic>[];
        return ApiResult<List<dynamic>>.success(list);
      }
      final error = body['error']?.toString() ?? 'Failed';
      return ApiResult<List<dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<List<dynamic>>.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
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
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Action failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> bulkAction(
    String eventId,
  ) async {
    try {
      final res = await http
          .post(
            Uri.parse('$kBaseUrl/api/hod/bulk-action'),
            headers: AuthStore.headers,
            body: jsonEncode({'event_id': eventId, 'action': 'APPROVED'}),
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Bulk action failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }

  static Future<ApiResult<Map<String, dynamic>>> analytics() async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/hod/analytics'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }
}

// ── VERIFY ────────────────────────────────────────────────────────────────────
class VerifyApi {
  static Future<ApiResult<Map<String, dynamic>>> scan(String uniqueId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$kBaseUrl/api/verify/$uniqueId'),
            headers: AuthStore.headers,
          )
          .timeout(const Duration(seconds: 10));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200) {
        return ApiResult<Map<String, dynamic>>.success(body);
      }
      final error = body['error']?.toString() ?? 'Scan failed';
      return ApiResult<Map<String, dynamic>>.fail(error);
    } catch (e) {
      return ApiResult<Map<String, dynamic>>.fail('Network error: $e');
    }
  }
}
