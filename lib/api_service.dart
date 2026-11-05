import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'data/services/firestore_paths.dart';

const Color kBlue = Color(0xFF1565C0);
const Color kRed = Color(0xFFB71C1C);

String getFullUrl(String path) => path.trim();

bool _isRejectedStatus(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  return value == 'rejected' || value.endsWith('_rejected');
}

bool _isAcceptedStatus(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  return value == 'accepted' ||
      value == 'approved' ||
      value == 'principal_approved';
}

bool _isPendingStatus(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  return value == 'pending' ||
      value == 'mentor_approved' ||
      value == 'hod_approved';
}

class ApiResult<T> {
  ApiResult.success(this.data) : ok = true, error = null;
  ApiResult.fail(this.error) : ok = false, data = null;

  final bool ok;
  final T? data;
  final String? error;
}

class RoleRequestSnapshot {
  const RoleRequestSnapshot({
    required this.queue,
    required this.history,
    required this.totalCount,
    required this.approvedCount,
    required this.rejectedCount,
  });

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> history;
  final int totalCount;
  final int approvedCount;
  final int rejectedCount;
}

class AuthStore {
  static String role = 'student';
  static String? fullName;
  static Map<String, dynamic>? studentProfile;
  static String? _loginEmail;

  static void setLoginEmail(String? email) => _loginEmail = email;

  static String? get loginEmail => _loginEmail;

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
  static CollectionReference<Map<String, dynamic>> get approvals =>
      _db.collection(FirestorePaths.approvals);

  static Future<List<Map<String, dynamic>>> allRequests() async {
    final requestSnapshot = await odRequests.get();
    final approvalSnapshot = await approvals.get();
    final historyByRequest = <String, List<Map<String, dynamic>>>{};
    for (final doc in approvalSnapshot.docs) {
      final data = doc.data();
      final requestId =
          (data['request_id'] ?? data['requestId'] ?? data['od_request_id'])
              ?.toString() ??
          '';
      if (requestId.isEmpty) continue;
      historyByRequest.putIfAbsent(requestId, () => []).add({
        'id': doc.id,
        ...data,
      });
    }

    for (final history in historyByRequest.values) {
      history.sort(
        (a, b) =>
            _dateValue(a['created_at']).compareTo(_dateValue(b['created_at'])),
      );
    }
    final requests = requestSnapshot.docs
        .map(
          (doc) => <String, dynamic>{
            'id': doc.id,
            ...doc.data(),
            'workflow_history': historyByRequest[doc.id] ?? const [],
          },
        )
        .toList();
    requests.sort(
      (a, b) =>
          _dateValue(b['updated_at']).compareTo(_dateValue(a['updated_at'])),
    );
    return requests;
  }

  static Stream<List<Map<String, dynamic>>> watchRequests() {
    return odRequests.snapshots().asyncMap((snapshot) async {
      final approvalSnapshot = await approvals.get();
      final historyByRequest = <String, List<Map<String, dynamic>>>{};
      for (final doc in approvalSnapshot.docs) {
        final data = doc.data();
        final requestId =
            (data['request_id'] ?? data['requestId'] ?? data['od_request_id'])
                ?.toString() ??
            '';
        if (requestId.isEmpty) continue;
        historyByRequest.putIfAbsent(requestId, () => []).add({
          'id': doc.id,
          ...data,
        });
      }
      for (final history in historyByRequest.values) {
        history.sort(
          (a, b) => _dateValue(
            a['created_at'],
          ).compareTo(_dateValue(b['created_at'])),
        );
      }
      final requests = snapshot.docs
          .map(
            (doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
              'workflow_history': historyByRequest[doc.id] ?? const [],
            },
          )
          .toList();
      requests.sort(
        (a, b) =>
            _dateValue(b['updated_at']).compareTo(_dateValue(a['updated_at'])),
      );
      return requests;
    });
  }

  static int _dateValue(dynamic value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      return DateTime.tryParse(value)?.millisecondsSinceEpoch ?? 0;
    }
    return 0;
  }

  static Future<Map<String, dynamic>?> requestById(String id) async {
    final doc = await odRequests.doc(id).get();
    if (!doc.exists) return null;
    return <String, dynamic>{'id': doc.id, ...?doc.data()};
  }

  static Future<Map<String, dynamic>> actor() async {
    final user = FirebaseAuth.instance.currentUser;
    final loginEmail = AuthStore.loginEmail?.trim().toLowerCase() ?? '';
    var profile = loginEmail.isNotEmpty
        ? <String, dynamic>{}
        : user == null
        ? <String, dynamic>{}
        : (await _db.collection(FirestorePaths.users).doc(user.uid).get())
                  .data() ??
              <String, dynamic>{};
    if (loginEmail.isNotEmpty) {
      final users = _db.collection(FirestorePaths.users);
      if (profile.isEmpty) {
        final direct = await users.doc(loginEmail).get();
        if (direct.exists) {
          profile = direct.data() ?? <String, dynamic>{};
          profile['__document_id'] = direct.id;
        } else {
          final localPart = loginEmail.split('@').first;
          final byIdentifier = await users.doc(localPart).get();
          if (byIdentifier.exists) {
            profile = byIdentifier.data() ?? <String, dynamic>{};
            profile['__document_id'] = byIdentifier.id;
          }
        }
        if (profile.isEmpty) {
          for (final field in const ['email', 'email_address', 'user_email']) {
            final byEmail = await users
                .where(field, isEqualTo: loginEmail)
                .limit(1)
                .get();
            if (byEmail.docs.isNotEmpty) {
              profile = byEmail.docs.first.data();
              profile['__document_id'] = byEmail.docs.first.id;
              break;
            }
          }
        }
      }
      if (profile.isEmpty && user != null) {
        final byUid = await _db
            .collection(FirestorePaths.users)
            .doc(user.uid)
            .get();
        if (byUid.exists) {
          profile = byUid.data() ?? <String, dynamic>{};
          profile['__document_id'] = byUid.id;
        }
      }
    }
    final profileIds = <String>[
      user?.uid ?? '',
      profile['uid']?.toString() ?? '',
      profile['user_id']?.toString() ?? '',
      profile['userId']?.toString() ?? '',
      profile['employee_id']?.toString() ?? '',
      profile['employeeId']?.toString() ?? '',
      profile['staff_id']?.toString() ?? '',
      profile['staffId']?.toString() ?? '',
      profile['__document_id']?.toString() ?? '',
      loginEmail,
    ].where((value) => value.trim().isNotEmpty).toSet().toList();
    return {
      'user_id': profileIds.firstOrNull ?? '',
      'user_ids': profileIds,
      'user_email': loginEmail.isNotEmpty ? loginEmail : user?.email ?? '',
      'user_name':
          profile['full_name'] ??
          profile['name'] ??
          user?.displayName ??
          user?.email ??
          user?.uid ??
          'Unknown',
      'role': (profile['role'] ?? AuthStore.role).toString().toLowerCase(),
      'department': profile['department']?.toString() ?? '',
      'profile_found': profile.isNotEmpty,
      'profile_document_id': profile['__document_id'] ?? user?.uid ?? '',
    };
  }

  static Future<void> notify({
    required String role,
    required String title,
    required String body,
    required String requestId,
  }) {
    return notifications.add({
      'role': role,
      'title': title,
      'message': body,
      'request_id': requestId,
      'seen': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}

Future<Map<String, dynamic>> resolveStaffActor() async {
  final actor = await _FirestoreApi.actor();
  debugPrint(
    'Staff identity: email=${actor['user_email']} uid=${FirebaseAuth.instance.currentUser?.uid ?? ''} '
    'profile=${actor['profile_document_id']} role=${actor['role']} '
    'resolved=${actor['profile_found']}',
  );
  return actor;
}

String _effectiveApproverRole(Map<String, dynamic> request) {
  final explicit = request['current_approver_role']?.toString().toLowerCase();
  if (explicit == 'mentor' || explicit == 'hod' || explicit == 'principal') {
    return explicit!;
  }

  if (!_workflowFlag(request['mentor_approved'])) return 'mentor';
  if (!_workflowFlag(request['hod_approved'])) return 'hod';
  if (!_workflowFlag(request['principal_approved'])) return 'principal';
  return 'closed';
}

Future<Map<String, dynamic>> _currentActor() async {
  return resolveStaffActor();
}

bool _assignedTo(
  Map<String, dynamic> request,
  Map<String, dynamic> actor,
  String role,
) {
  // Staff login is temporary and not tied to a specific profile. Assignment
  // is therefore role-based; _effectiveApproverRole still enforces sequence.
  return true;
}

String _historyRole(Map entry) {
  final value =
      (entry['approver_role'] ??
              entry['approval_role'] ??
              entry['user_role'] ??
              entry['approverType'] ??
              entry['role'] ??
              '')
          .toString()
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');
  if (value == 'head_of_department' || value == 'head_department') {
    return 'hod';
  }
  return value == 'head' ? 'hod' : value;
}

String _historyActorId(Map entry) {
  return (entry['approver_id'] ??
          entry['approver_uid'] ??
          entry['approver_user_id'] ??
          entry['approverUserId'] ??
          entry['userId'] ??
          entry['user_id'] ??
          entry['actor_id'] ??
          entry['uid'] ??
          '')
      .toString();
}

bool? _historyDecision(Map entry) {
  final value =
      entry['is_approved'] ??
      entry['approved'] ??
      entry['isApproved'] ??
      entry['approval_status'];
  if (value is bool) return value;
  final boolValue = value?.toString().trim().toLowerCase();
  if (boolValue == 'true' ||
      boolValue == 'approved' ||
      boolValue == 'approve') {
    return true;
  }

  if (boolValue == 'false' ||
      boolValue == 'rejected' ||
      boolValue == 'reject') {
    return false;
  }
  final action = (entry['action'] ?? entry['decision'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (action == 'approved' || action == 'approve') return true;
  if (action == 'rejected' || action == 'reject') return false;
  return null;
}

bool _workflowFlag(dynamic value) {
  if (value is bool) return value;
  final normalized = value?.toString().trim().toLowerCase();
  return normalized == 'true' ||
      normalized == 'approved' ||
      normalized == 'approve' ||
      normalized == 'accepted';
}

bool _historyRoleHasDecision(
  Map<String, dynamic> request, {
  required String role,
  required bool approved,
}) {
  final history = request['workflow_history'];
  if (history is! List) return false;
  return history.any(
    (entry) =>
        entry is Map &&
        _historyRole(entry) == role &&
        _historyDecision(entry) == approved,
  );
}

bool _historyHas(
  Map<String, dynamic> request, {
  required String role,
  required String userId,
  required bool approved,
}) {
  final history = request['workflow_history'];
  if (history is! List) return false;
  return history.any(
    (entry) =>
        entry is Map &&
        _historyRole(entry) == role &&
        _historyActorId(entry) == userId &&
        _historyDecision(entry) == approved,
  );
}

int _decisionCount(
  List<Map<String, dynamic>> requests, {
  required String role,
  required String userId,
  required bool approved,
}) {
  return requests
      .where(
        (request) =>
            _historyRoleHasDecision(request, role: role, approved: approved),
      )
      .length;
}

RoleRequestSnapshot _roleSnapshot(
  List<Map<String, dynamic>> requests,
  Map<String, dynamic> actor,
  String role,
) {
  final history = _historyForRole(requests, actor, role: role);
  final userId = actor['user_id']?.toString() ?? '';
  debugPrint(
    'Role retrieval: role=$role identity=${actor['profile_document_id']} '
    'matching=${history.length} queue=${_roleQueue(requests, actor, role).length}',
  );
  return RoleRequestSnapshot(
    queue: _roleQueue(requests, actor, role),
    history: history,
    totalCount: history.length,
    approvedCount: _decisionCount(
      history,
      role: role,
      userId: userId,
      approved: true,
    ),
    rejectedCount: _decisionCount(
      history,
      role: role,
      userId: userId,
      approved: false,
    ),
  );
}

bool _reachedStage(Map<String, dynamic> request, {required String role}) {
  final history = request['workflow_history'];
  final hasAction =
      history is List &&
      history.any((entry) => entry is Map && _historyRole(entry) == role);
  if (hasAction) return true;
  if (_effectiveApproverRole(request) == role) return true;
  final rejectedBy = _rejectionRole(request);
  if (_isRejectedStatus(request['status']) &&
      rejectedBy != null &&
      _workflowRoleOrder(role) <= _workflowRoleOrder(rejectedBy)) {
    return true;
  }
  return switch (role) {
    'mentor' =>
      _workflowFlag(request['mentor_approved']) ||
          _isRejectedStatus(request['status']) &&
              request['rejected_by_role']?.toString().toLowerCase() == 'mentor',
    'hod' =>
      _workflowFlag(request['mentor_approved']) &&
          (_workflowFlag(request['hod_approved']) ||
              request['rejected_by_role']?.toString().toLowerCase() == 'hod'),
    'principal' =>
      _workflowFlag(request['mentor_approved']) &&
          _workflowFlag(request['hod_approved']) &&
          (_workflowFlag(request['principal_approved']) ||
              request['rejected_by_role']?.toString().toLowerCase() ==
                  'principal'),
    _ => false,
  };
}

String? _rejectionRole(Map<String, dynamic> request) {
  final stored = request['rejected_by_role']?.toString().trim().toLowerCase();
  if (stored != null && stored.isNotEmpty) {
    return _normalizeWorkflowRole(stored);
  }
  final history = request['workflow_history'];
  if (history is! List) return null;
  for (final entry in history.reversed) {
    if (entry is! Map || _historyDecision(entry) != false) continue;
    final role = _historyRole(entry);
    if (role == 'mentor' || role == 'hod' || role == 'principal') {
      return role;
    }
  }
  return null;
}

String _normalizeWorkflowRole(String role) {
  if (role == 'head' ||
      role == 'head_of_department' ||
      role == 'head_department') {
    return 'hod';
  }
  return role;
}

int _workflowRoleOrder(String role) {
  switch (role) {
    case 'mentor':
      return 0;
    case 'hod':
      return 1;
    case 'principal':
      return 2;
    default:
      return 99;
  }
}

List<Map<String, dynamic>> _historyForRole(
  List<Map<String, dynamic>> requests,
  Map<String, dynamic> actor, {
  required String role,
}) {
  return requests
      .where(
        (request) =>
            _assignedTo(request, actor, role) &&
            _reachedStage(request, role: role),
      )
      .toList();
}

Future<ApiResult<Map>> _applyWorkflowAction({
  required String requestId,
  required String role,
  required bool approved,
  required String? reason,
}) async {
  try {
    final actor = await _FirestoreApi.actor();
    final requestRef = _FirestoreApi.odRequests.doc(requestId);
    await _FirestoreApi._db.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);
      if (!snapshot.exists) throw StateError('Request not found');
      final current = snapshot.data() ?? <String, dynamic>{};
      if (_isRejectedStatus(current['status']) ||
          _isAcceptedStatus(current['status'])) {
        throw StateError('Request is already closed');
      }
      if (_effectiveApproverRole(current) != role) {
        throw StateError('Request is not waiting for $role review');
      }
      if (!_assignedTo(current, actor, role)) {
        throw StateError('This request is assigned to another $role');
      }

      final updates = <String, dynamic>{
        'updated_at': FieldValue.serverTimestamp(),
        'rejected': !approved,
        'current_approver_role': approved
            ? role == 'mentor'
                  ? 'hod'
                  : role == 'hod'
                  ? 'principal'
                  : 'closed'
            : 'closed',
      };
      if (role == 'mentor') {
        updates['mentor_approved'] = approved;
        updates['mentor_comment'] = reason;
      } else if (role == 'hod') {
        updates['hod_approved'] = approved;
        updates['hod_comment'] = reason;
      } else {
        updates['principal_approved'] = approved;
        updates['principal_comment'] = reason;
      }

      if (approved) {
        updates['status'] = role == 'principal' ? 'ACCEPTED' : 'PENDING';
      } else {
        updates.addAll({
          'status': 'REJECTED',
          'rejected_by_user_id': actor['user_id'],
          'rejected_by_role': role,
          'rejected_by_name': actor['user_name'],
          'rejected_by_email': actor['user_email'],
          'rejection_reason': (reason ?? '').trim(),
          'rejected_at': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(requestRef, updates);
      transaction.set(_FirestoreApi.approvals.doc(), {
        'request_id': requestId,
        'approver_id': actor['user_id'],
        'approver_role': role,
        'approver_email': actor['user_email'],
        'approver_name': actor['user_name'],
        'is_approved': approved,
        'comment': (reason ?? '').trim(),
        'created_at': FieldValue.serverTimestamp(),
      });
    });
    final updated = await _FirestoreApi.requestById(requestId);
    return updated == null
        ? ApiResult.fail('Request not found after update')
        : ApiResult.success(updated);
  } on StateError catch (error) {
    return ApiResult.fail(error.message);
  } catch (error) {
    return ApiResult.fail('Workflow action failed: $error');
  }
}

class OdApi {
  static Future<ApiResult<List>> myRequests() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final requests = await _FirestoreApi.allRequests();
      return ApiResult.success(
        requests.where((r) => r['student_id']?.toString() == userId).toList(),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load requests: $error');
    }
  }

  static Future<ApiResult<Map>> activeSession() async =>
      ApiResult.success({'has_active_session': false});

  static Stream<List<Map<String, dynamic>>> watchMyRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    return _FirestoreApi.watchRequests().map(
      (requests) => requests
          .where((request) => request['student_id']?.toString() == userId)
          .toList(),
    );
  }

  static Future<ApiResult<Map>> resubmitRequest(Map item) async {
    try {
      final id = item['id']?.toString() ?? '';
      if (id.isEmpty) return ApiResult.fail('Missing request id');
      await _FirestoreApi.odRequests.doc(id).update({
        'rejected': false,
        'status': 'PENDING',
        'current_approver_role': 'mentor',
        'rejected_by_user_id': FieldValue.delete(),
        'rejected_by_role': FieldValue.delete(),
        'rejection_reason': FieldValue.delete(),
        'rejected_at': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      final updated = await _FirestoreApi.requestById(id);
      return updated == null
          ? ApiResult.fail('Request not found')
          : ApiResult.success(updated);
    } catch (error) {
      return ApiResult.fail('Resubmit failed: $error');
    }
  }
}

class MentorApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final actor = await _FirestoreApi.actor();
      final requests = await _FirestoreApi.allRequests();
      return ApiResult.success(
        requests
            .where(
              (r) =>
                  _effectiveApproverRole(r) == 'mentor' &&
                  _isPendingStatus(r['status']) &&
                  _assignedTo(r, actor, 'mentor'),
            )
            .toList(),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load mentor queue: $error');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
    String? comment,
  }) async {
    final result = await _applyWorkflowAction(
      requestId: requestId,
      role: 'mentor',
      approved: action == 'APPROVED',
      reason: comment ?? reason,
    );
    if (result.ok) {
      await _FirestoreApi.notify(
        role: action == 'APPROVED' ? 'hod' : 'student',
        title: action == 'APPROVED' ? 'OD Approved by Mentor' : 'OD Rejected',
        body: action == 'APPROVED'
            ? 'Request moved to HoD'
            : 'Your OD was rejected',
        requestId: requestId,
      );
    }
    return result;
  }

  static Future<ApiResult<List>> history() async {
    try {
      final actor = await _currentActor();
      return ApiResult.success(
        _historyForRole(
          await _FirestoreApi.allRequests(),
          actor,
          role: 'mentor',
        ),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load history: $error');
    }
  }

  static Stream<RoleRequestSnapshot> watchData() async* {
    final actor = await _currentActor();
    yield* _FirestoreApi.watchRequests().map(
      (requests) => _roleSnapshot(requests, actor, 'mentor'),
    );
  }
}

List<Map<String, dynamic>> _roleQueue(
  List<Map<String, dynamic>> requests,
  Map<String, dynamic> actor,
  String role,
) {
  return requests
      .where(
        (request) =>
            _effectiveApproverRole(request) == role &&
            _isPendingStatus(request['status']) &&
            _assignedTo(request, actor, role),
      )
      .toList();
}

class HoDApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final actor = await _FirestoreApi.actor();
      final requests = await _FirestoreApi.allRequests();
      return ApiResult.success(
        requests
            .where(
              (r) =>
                  _effectiveApproverRole(r) == 'hod' &&
                  _isPendingStatus(r['status']) &&
                  _assignedTo(r, actor, 'hod'),
            )
            .toList(),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load HoD queue: $error');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    final result = await _applyWorkflowAction(
      requestId: requestId,
      role: 'hod',
      approved: action == 'APPROVED',
      reason: reason,
    );
    if (result.ok) {
      await _FirestoreApi.notify(
        role: action == 'APPROVED' ? 'principal' : 'student',
        title: action == 'APPROVED' ? 'OD Approved by HoD' : 'OD Rejected',
        body: action == 'APPROVED'
            ? 'Request moved to Principal'
            : 'Your OD was rejected',
        requestId: requestId,
      );
    }
    return result;
  }

  static Future<ApiResult<Map>> bulkAction(String eventId) async =>
      ApiResult.fail('Bulk approval moved to Principal role.');

  static Future<ApiResult<Map>> analytics() async {
    final actor = await _FirestoreApi.actor();
    final requests = await _FirestoreApi.allRequests();
    final visible = _historyForRole(requests, actor, role: 'hod');
    final pending = visible
        .where((r) => _effectiveApproverRole(r) == 'hod')
        .length;
    final approved = visible
        .where(
          (r) => _historyHas(
            r,
            role: 'hod',
            userId: actor['user_id'].toString(),
            approved: true,
          ),
        )
        .length;
    final rejected = visible
        .where(
          (r) => _historyHas(
            r,
            role: 'hod',
            userId: actor['user_id'].toString(),
            approved: false,
          ),
        )
        .length;
    return ApiResult.success({
      'total': pending + approved + rejected,
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'active_now': 0,
    });
  }

  static Future<ApiResult<List>> history() async {
    try {
      final actor = await _currentActor();
      return ApiResult.success(
        _historyForRole(await _FirestoreApi.allRequests(), actor, role: 'hod'),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load history: $error');
    }
  }

  static Future<ApiResult<List>> activeSessions() async =>
      ApiResult.success(const []);

  static Stream<RoleRequestSnapshot> watchData() async* {
    final actor = await _currentActor();
    yield* _FirestoreApi.watchRequests().map(
      (requests) => _roleSnapshot(requests, actor, 'hod'),
    );
  }
}

class PrincipalApi {
  static Future<ApiResult<List>> queue() async {
    try {
      final actor = await _FirestoreApi.actor();
      final requests = await _FirestoreApi.allRequests();
      return ApiResult.success(
        requests
            .where(
              (r) =>
                  _effectiveApproverRole(r) == 'principal' &&
                  _isPendingStatus(r['status']) &&
                  _assignedTo(r, actor, 'principal'),
            )
            .toList(),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load Principal queue: $error');
    }
  }

  static Future<ApiResult<Map>> action({
    required String requestId,
    required String action,
    String? reason,
  }) async {
    final result = await _applyWorkflowAction(
      requestId: requestId,
      role: 'principal',
      approved: action == 'APPROVED',
      reason: reason,
    );
    if (result.ok) {
      await _FirestoreApi.notify(
        role: 'student',
        title: action == 'APPROVED' ? 'OD Accepted' : 'OD Rejected',
        body: action == 'APPROVED'
            ? 'Your OD was accepted'
            : 'Your OD was rejected',
        requestId: requestId,
      );
    }
    return result;
  }

  static Future<ApiResult<Map>> bulkApprove(List<String> ids) async {
    var count = 0;
    for (final id in ids) {
      final result = await action(
        requestId: id,
        action: 'APPROVED',
        reason: 'Approved by Principal',
      );
      if (result.ok) count++;
    }
    return ApiResult.success({
      'message': '$count requests approved',
      'count': count,
    });
  }

  static Future<ApiResult<List>> history() async {
    try {
      final actor = await _currentActor();
      return ApiResult.success(
        _historyForRole(
          await _FirestoreApi.allRequests(),
          actor,
          role: 'principal',
        ),
      );
    } catch (error) {
      return ApiResult.fail('Failed to load history: $error');
    }
  }

  static Stream<RoleRequestSnapshot> watchData() async* {
    final actor = await _currentActor();
    yield* _FirestoreApi.watchRequests().map(
      (requests) => _roleSnapshot(requests, actor, 'principal'),
    );
  }
}

class VerifyApi {
  static Future<ApiResult<Map>> scan(String uniqueId) async =>
      ApiResult.fail('QR verification backend removed; use Firebase flow.');
}
