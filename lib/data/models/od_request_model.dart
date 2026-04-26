import '../../domain/entities/od_request.dart';
import '../../domain/enums/od_status.dart';

class OdRequestModel extends OdRequest {
  const OdRequestModel({
    required super.id,
    required super.studentId,
    required super.eventName,
    required super.organizer,
    required super.venue,
    required super.startDateTime,
    required super.endDateTime,
    required super.isMultiDay,
    required super.reason,
    required super.status,
    super.expired,
    super.isPinned,
    super.proofUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory OdRequestModel.fromMap(String id, Map<String, dynamic> map) {
    return OdRequestModel(
      id: id,
      studentId: map['student_id'] as String? ?? '',
      eventName: map['event_name'] as String? ?? '',
      organizer: map['organizer'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      startDateTime:
          _toDateTime(map['start_datetime']) ?? _toDateTime(map['datetime']) ?? DateTime.now(),
      endDateTime: _toDateTime(map['end_datetime']) ?? DateTime.now(),
      isMultiDay: map['is_multi_day'] as bool? ?? false,
      reason: map['reason'] as String? ?? '',
      status: OdStatusX.fromValue(map['status'] as String? ?? 'PENDING'),
      expired: map['expired'] as bool? ??
          OdStatusX.fromValue(map['status'] as String? ?? 'PENDING') ==
              OdStatus.expired,
      isPinned: map['is_pinned'] as bool? ?? false,
      proofUrl: map['proof_url'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'student_id': studentId,
      'event_name': eventName,
      'organizer': organizer,
      'venue': venue,
      'datetime': startDateTime.toIso8601String(),
      'start_datetime': startDateTime.toIso8601String(),
      'end_datetime': endDateTime.toIso8601String(),
      'is_multi_day': isMultiDay,
      'reason': reason,
      'status': status.value,
      'expired': expired || status == OdStatus.expired,
      'is_pinned': isPinned,
      'mentor_approved':
          status == OdStatus.mentorApproved ||
          status == OdStatus.hodApproved ||
          status == OdStatus.principalApproved,
      'hod_approved':
          status == OdStatus.hodApproved || status == OdStatus.principalApproved,
      'principal_approved': status == OdStatus.principalApproved,
      'current_approver_role': _currentApproverRole(status),
      'proof_url': proofUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static String _currentApproverRole(OdStatus status) {
    return switch (status) {
      OdStatus.pending => 'mentor',
      OdStatus.mentorApproved => 'hod',
      OdStatus.hodApproved => 'principal',
      _ => 'closed',
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
