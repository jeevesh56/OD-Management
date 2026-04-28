import '../../domain/entities/approval.dart';
import '../../domain/entities/od_request.dart';
import '../../domain/enums/od_status.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../domain/repositories/od_request_repository.dart';
import '../../domain/rules/od_rule_engine.dart';
import 'role_access_service.dart';

class OdRequestService {
  OdRequestService({
    required OdRequestRepository requestRepository,
    required ApprovalRepository approvalRepository,
    required RoleAccessService roleAccessService,
  })  : _requestRepository = requestRepository,
        _approvalRepository = approvalRepository,
        _roleAccessService = roleAccessService;

  final OdRequestRepository _requestRepository;
  final ApprovalRepository _approvalRepository;
  final RoleAccessService _roleAccessService;

  Future<RuleValidationResult> createRequest({
    required UserRole actorRole,
    bool actorIsEc = false,
    required OdRequest request,
  }) async {
    if (!_roleAccessService.canCreateOd(actorRole, isEc: actorIsEc)) {
      return const RuleValidationResult([
        RuleViolation(
          code: 'UNAUTHORIZED_OD_CREATE',
          message: 'Only students and mentors with EC permission can create OD requests.',
        ),
      ]);
    }

    final validation = OdRuleEngine.validateApplication(
      startDateTime: request.startDateTime,
      endDateTime: request.endDateTime,
      isMultiDay: request.isMultiDay,
    );
    if (!validation.isValid) return validation;

    await _requestRepository.create(request);
    return validation;
  }

  Future<RuleValidationResult> applyDecision({
    required UserRole actorRole,
    required String requestId,
    required bool isApproved,
    required String? reason,
    required String actorId,
  }) async {
    final request = await _requestRepository.getById(requestId);
    if (request == null) {
      return const RuleValidationResult([
        RuleViolation(code: 'REQUEST_NOT_FOUND', message: 'OD request not found.'),
      ]);
    }

    if (request.expired || request.status == OdStatus.expired) {
      return const RuleValidationResult([
        RuleViolation(
          code: 'REQUEST_EXPIRED',
          message: 'Action closed. This OD request is expired.',
        ),
      ]);
    }

    if (!isApproved) {
      final reasonValidation = OdRuleEngine.validateRejectionReason(reason);
      if (!reasonValidation.isValid) return reasonValidation;
    }

    final nextStatus = _nextStatus(actorRole: actorRole, isApproved: isApproved);
    if (nextStatus == null) {
      return const RuleValidationResult([
        RuleViolation(
          code: 'UNAUTHORIZED_APPROVAL',
          message: 'Current role cannot perform this approval action.',
        ),
      ]);
    }

    final updated = OdRequest(
      id: request.id,
      studentId: request.studentId,
      eventName: request.eventName,
      organizer: request.organizer,
      venue: request.venue,
      startDateTime: request.startDateTime,
      endDateTime: request.endDateTime,
      isMultiDay: request.isMultiDay,
      reason: request.reason,
      proofUrl: request.proofUrl,
      status: nextStatus,
      expired: request.expired,
      isPinned: request.isPinned,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
    );

    await _requestRepository.update(updated);
    await _approvalRepository.create(
      Approval(
        id: '${request.id}_${DateTime.now().millisecondsSinceEpoch}',
        requestId: request.id,
        approverId: actorId,
        approverRole: actorRole,
        isApproved: isApproved,
        comment: (reason ?? '').trim(),
        createdAt: DateTime.now(),
      ),
    );

    return const RuleValidationResult([]);
  }

  OdStatus? _nextStatus({
    required UserRole actorRole,
    required bool isApproved,
  }) {
    switch (actorRole) {
      case UserRole.mentor:
        if (!_roleAccessService.canApproveAsMentor(actorRole)) return null;
        return isApproved ? OdStatus.mentorApproved : OdStatus.mentorRejected;
      case UserRole.hod:
        if (!_roleAccessService.canApproveAsHod(actorRole)) return null;
        return isApproved ? OdStatus.hodApproved : OdStatus.hodRejected;
      case UserRole.principal:
      case UserRole.admin:
        if (!_roleAccessService.canApproveAsPrincipal(actorRole)) return null;
        return isApproved
            ? OdStatus.principalApproved
            : OdStatus.principalRejected;
      case UserRole.student:
        return null;
    }
  }
}
