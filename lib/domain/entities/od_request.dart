import '../enums/od_status.dart';

class OdRequest {
  const OdRequest({
    required this.id,
    required this.studentId,
    required this.eventName,
    required this.organizer,
    required this.venue,
    required this.startDateTime,
    required this.endDateTime,
    required this.isMultiDay,
    required this.reason,
    required this.status,
    this.expired = false,
    this.isPinned = false,
    this.proofUrl,
    this.createdAt,
    this.updatedAt,
    this.currentApproverRole,
    this.mentorApproved = false,
    this.hodApproved = false,
    this.principalApproved = false,
  });

  final String id;
  final String studentId;
  final String eventName;
  final String organizer;
  final String venue;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool isMultiDay;
  final String reason;
  final String? proofUrl;
  final OdStatus status;
  final bool expired;
  final bool isPinned;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? currentApproverRole;
  final bool mentorApproved;
  final bool hodApproved;
  final bool principalApproved;
}
