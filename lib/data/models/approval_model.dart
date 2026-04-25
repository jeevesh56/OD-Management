import '../../domain/entities/approval.dart';
import '../../domain/enums/user_role.dart';

class ApprovalModel extends Approval {
  const ApprovalModel({
    required super.id,
    required super.requestId,
    required super.approverId,
    required super.approverRole,
    required super.isApproved,
    required super.comment,
    required super.createdAt,
  });

  factory ApprovalModel.fromMap(String id, Map<String, dynamic> map) {
    return ApprovalModel(
      id: id,
      requestId: map['request_id'] as String? ?? '',
      approverId: map['approver_id'] as String? ?? '',
      approverRole: UserRoleX.fromValue(map['approver_role'] as String? ?? 'mentor'),
      isApproved: map['is_approved'] as bool? ?? false,
      comment: map['comment'] as String? ?? '',
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'request_id': requestId,
      'approver_id': approverId,
      'approver_role': approverRole.value,
      'is_approved': isApproved,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
