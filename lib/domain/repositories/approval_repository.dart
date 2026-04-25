import '../entities/approval.dart';

abstract class ApprovalRepository {
  Future<void> create(Approval approval);
  Future<List<Approval>> getByRequest(String requestId);
}
