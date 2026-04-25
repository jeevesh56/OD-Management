import '../../domain/entities/approval.dart';
import '../../domain/repositories/approval_repository.dart';

class InMemoryApprovalRepository implements ApprovalRepository {
  final Map<String, List<Approval>> _approvalsByRequest = {};

  @override
  Future<void> create(Approval approval) async {
    final current = _approvalsByRequest[approval.requestId] ?? <Approval>[];
    _approvalsByRequest[approval.requestId] = [...current, approval];
  }

  @override
  Future<List<Approval>> getByRequest(String requestId) async {
    return _approvalsByRequest[requestId] ?? <Approval>[];
  }
}
