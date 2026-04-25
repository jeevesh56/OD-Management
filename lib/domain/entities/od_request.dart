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
    this.proofUrl,
    this.createdAt,
    this.updatedAt,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
