import '../../domain/entities/approval.dart';
import '../../domain/repositories/approval_repository.dart';
import '../models/approval_model.dart';
import '../services/document_store.dart';
import '../services/firestore_paths.dart';

class FirestoreApprovalRepository implements ApprovalRepository {
  const FirestoreApprovalRepository(this._store);

  final DocumentStore _store;

  @override
  Future<void> create(Approval approval) async {
    final model = ApprovalModel(
      id: approval.id,
      requestId: approval.requestId,
      approverId: approval.approverId,
      approverRole: approval.approverRole,
      isApproved: approval.isApproved,
      comment: approval.comment,
      createdAt: approval.createdAt,
    );
    await _store.set(
      collection: FirestorePaths.approvals,
      id: approval.id,
      data: model.toMap(),
      merge: false,
    );
  }

  @override
  Future<List<Approval>> getByRequest(String requestId) async {
    final rows = await _store.query(
      collection: FirestorePaths.approvals,
      field: 'request_id',
      isEqualTo: requestId,
    );
    return rows
        .map((row) => ApprovalModel.fromMap(row['id'] as String? ?? '', row))
        .toList();
  }
}
