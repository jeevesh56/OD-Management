import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String portalOdDateLabel(dynamic start, dynamic end) {
  final a = start?.toString() ?? '';
  final b = end?.toString() ?? '';
  if (a.isEmpty && b.isEmpty) return '—';
  if (a == b || b.isEmpty) return a;
  return '$a – $b';
}

DateTime? portalToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String portalOdDateTime(dynamic value) {
  final dt = portalToDateTime(value);
  if (dt == null) return value?.toString() ?? '—';
  return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
}

String portalOdStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
    case 'Pending':
      return 'Pending';
    case 'MENTOR_APPROVED':
      return 'Mentor approved';
    case 'MENTOR_REJECTED':
      return 'Mentor rejected';
    case 'HOD_APPROVED':
      return 'HoD approved';
    case 'PRINCIPAL_APPROVED':
    case 'ACCEPTED':
    case 'Approved':
      return 'Approved';
    case 'HOD_REJECTED':
      return 'HoD rejected';
    case 'PRINCIPAL_REJECTED':
    case 'REJECTED':
    case 'Rejected':
      return 'Principal rejected';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status.isEmpty ? '—' : status;
  }
}

String portalOdBadgeLabel(String status) {
  if (status == 'MENTOR_APPROVED') return 'Mentor OK';
  if (status == 'HOD_APPROVED') return 'HoD OK';
  return portalOdStatusLabel(status);
}

bool portalOdStatusIsRejected(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  return value == 'rejected' || value.endsWith('_rejected');
}

bool portalOdStatusIsApproved(dynamic status) {
  final value = status?.toString().trim().toLowerCase() ?? '';
  return value == 'accepted' ||
      value == 'approved' ||
      value.endsWith('_approved');
}

bool portalOdStatusIsPending(dynamic status) {
  return (status?.toString().trim().toLowerCase() ?? '') == 'pending';
}

bool portalRequestIsAttended(Map<dynamic, dynamic> request) {
  final status =
      request['attendance_status'] ??
      request['attendance'] ??
      request['visit_status'] ??
      request['status'];
  final value = status?.toString().trim().toLowerCase() ?? '';
  return request['attended'] == true ||
      request['is_attended'] == true ||
      request['completed'] == true ||
      value == 'attended' ||
      value == 'completed';
}

Color portalOdStatusColor(String status) {
  switch (status) {
    case 'PRINCIPAL_APPROVED':
    case 'ACCEPTED':
    case 'Approved':
      return Colors.green;
    case 'MENTOR_REJECTED':
    case 'HOD_REJECTED':
    case 'PRINCIPAL_REJECTED':
    case 'REJECTED':
    case 'Rejected':
      return Colors.red;
    case 'PENDING':
    case 'Pending':
      return Colors.orange;
    case 'MENTOR_APPROVED':
    case 'HOD_APPROVED':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

String portalOdShortDate(String raw) {
  final d = portalToDateTime(raw);
  if (d == null) return raw;
  return DateFormat('dd MMM yyyy').format(d);
}

bool portalWorkflowHasDecision(
  Map<dynamic, dynamic> request, {
  required String role,
  required String userId,
  required bool approved,
}) {
  final history = request['workflow_history'];
  if (history is! List) return false;
  return history.any(
    (entry) =>
        entry is Map &&
        _portalHistoryRole(entry) == role &&
        _portalHistoryActorId(entry) == userId &&
        _portalHistoryDecision(entry) == approved,
  );
}

String _portalHistoryRole(Map entry) {
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

String _portalHistoryActorId(Map entry) {
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

bool? _portalHistoryDecision(Map entry) {
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

bool portalWorkflowHasRoleDecision(
  Map<dynamic, dynamic> request, {
  required String role,
  required bool approved,
}) {
  final history = request['workflow_history'];
  if (history is! List) return false;
  return history.any(
    (entry) =>
        entry is Map &&
        _portalHistoryRole(entry) == role &&
        _portalHistoryDecision(entry) == approved,
  );
}

Map<dynamic, dynamic>? portalRoleDecisionEntry(
  Map<dynamic, dynamic> request,
  String role,
) {
  final history = request['workflow_history'];
  if (history is! List) return null;
  final entries = history
      .whereType<Map>()
      .where((entry) => _portalHistoryRole(entry) == role)
      .toList();
  return entries.isEmpty ? null : entries.last;
}

String portalRoleDecisionActor(Map<dynamic, dynamic> request, String role) {
  final entry = portalRoleDecisionEntry(request, role);
  if (entry == null) return 'Unknown';
  final name = _portalVisibleIdentity(entry['approver_name']);
  if (name.isNotEmpty) return name;
  final email = entry['approver_email']?.toString().trim() ?? '';
  return _portalVisibleIdentity(email).isNotEmpty
      ? _portalVisibleIdentity(email)
      : 'Unknown';
}

String _portalVisibleIdentity(dynamic value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) return '';
  if (RegExp(r'^[a-f0-9]{12,}$', caseSensitive: false).hasMatch(text)) {
    return '';
  }
  return text;
}

String portalRoleDecisionLabel(Map<dynamic, dynamic> request, String role) {
  final detail = portalRoleDecisionDisplay(request, role);
  return detail.split(' — ').first;
}

String portalRoleDecisionDisplay(Map<dynamic, dynamic> request, String role) {
  final history = request['workflow_history'];
  if (history is List) {
    final entries = history.whereType<Map>().where(
      (entry) => _portalHistoryRole(entry) == role,
    );
    final list = entries.toList();
    if (list.isNotEmpty) {
      final entry = list.last;
      final decision = _portalHistoryDecision(entry);
      final label = decision == true
          ? 'Approved'
          : decision == false
          ? 'Rejected'
          : 'Pending';
      final comment = entry['comment']?.toString().trim() ?? '';
      return comment.isEmpty ? label : '$label — $comment';
    }
  }
  return 'Pending';
}

class PortalHistoryRequestDetails extends StatelessWidget {
  const PortalHistoryRequestDetails({super.key, required this.request});

  final Map<dynamic, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final studentName =
        request['student_name']?.toString() ??
        request['studentName']?.toString() ??
        'Student';
    final studentId =
        request['student_unique_id']?.toString() ??
        request['student_roll_no']?.toString() ??
        request['student_registration_no']?.toString() ??
        '—';
    final reason = request['reason']?.toString() ?? '—';
    final submitted = request['created_at'] ?? request['submitted_at'];
    final style = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Student: $studentName ($studentId)', style: style),
        Text('Reason: $reason', style: style),
        Text('Submitted: ${portalOdDateTime(submitted)}', style: style),
      ],
    );
  }
}

class PortalWorkflowHistory extends StatelessWidget {
  const PortalWorkflowHistory({super.key, required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    if (value is! List || value.isEmpty) return const SizedBox.shrink();
    final entries = value.whereType<Map>().toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map<Widget>((entry) {
          final role = _portalHistoryRole(entry);
          final decision = _portalHistoryDecision(entry);
          final action = decision == true ? 'Approved' : 'Rejected';
          final identity = portalRoleDecisionActor({'workflow_history': [entry]}, role);
          final comment = (entry['comment'] ??
                  entry['rejection_reason'] ??
                  entry['reason'] ??
                  '')
              .toString()
              .trim();
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${role.toUpperCase()} • $action by $identity${comment.isEmpty ? '' : ' — $comment'}',
              style: TextStyle(
                fontSize: 12,
                color: decision == true
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PortalApprovalTimeline extends StatelessWidget {
  const PortalApprovalTimeline({super.key, required this.value});

  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final entries = value is List ? value.whereType<Map>().toList() : <Map>[];
    final roles = const <String>['mentor', 'hod', 'principal'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: roles.map<Widget>((role) {
        final matching = entries.where((entry) {
          return _portalHistoryRole(entry) == role;
        }).toList();
        if (matching.isEmpty) {
          return Text(
            '${role.toUpperCase()}: Awaiting decision',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          );
        }
        final entry = matching.last;
        final decision = _portalHistoryDecision(entry);
        final action = decision == true
            ? 'Approved'
            : decision == false
            ? 'Rejected'
            : 'Awaiting decision';
        final comment = (entry['comment'] ??
                entry['rejection_reason'] ??
                entry['reason'] ??
                '')
            .toString()
            .trim();
        final actor = portalRoleDecisionActor({'workflow_history': [entry]}, role);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            '${role.toUpperCase()}: $action by $actor${comment.isEmpty ? '' : ' — $comment'}',
            style: TextStyle(
              fontSize: 12,
              color: decision == false
                  ? Colors.red.shade700
                  : decision == true
                  ? Colors.green.shade700
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }).toList(),
    );
  }
}
