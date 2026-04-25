import '../enums/user_role.dart';

class Approval {
  const Approval({
    required this.id,
    required this.requestId,
    required this.approverId,
    required this.approverRole,
    required this.isApproved,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String requestId;
  final String approverId;
  final UserRole approverRole;
  final bool isApproved;
  final String comment;
  final DateTime createdAt;
}
