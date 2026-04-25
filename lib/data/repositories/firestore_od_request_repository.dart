import '../../domain/entities/od_request.dart';
import '../../domain/repositories/od_request_repository.dart';
import '../models/od_request_model.dart';
import '../services/document_store.dart';
import '../services/firestore_paths.dart';

class FirestoreOdRequestRepository implements OdRequestRepository {
  const FirestoreOdRequestRepository(this._store);

  final DocumentStore _store;

  @override
  Future<void> create(OdRequest request) async {
    final model = OdRequestModel(
      id: request.id,
      studentId: request.studentId,
      eventName: request.eventName,
      organizer: request.organizer,
      venue: request.venue,
      startDateTime: request.startDateTime,
      endDateTime: request.endDateTime,
      isMultiDay: request.isMultiDay,
      reason: request.reason,
      status: request.status,
      proofUrl: request.proofUrl,
      createdAt: request.createdAt ?? DateTime.now(),
      updatedAt: request.updatedAt ?? DateTime.now(),
    );
    await _store.set(
      collection: FirestorePaths.odRequests,
      id: request.id,
      data: model.toMap(),
      merge: false,
    );
  }

  @override
  Future<OdRequest?> getById(String requestId) async {
    final data =
        await _store.get(collection: FirestorePaths.odRequests, id: requestId);
    if (data == null) return null;
    return OdRequestModel.fromMap(requestId, data);
  }

  @override
  Stream<OdRequest?> watchById(String requestId) {
    return _store
        .watchDocument(collection: FirestorePaths.odRequests, id: requestId)
        .map((data) => data == null ? null : OdRequestModel.fromMap(requestId, data));
  }

  @override
  Future<List<OdRequest>> getByStudent(String studentId) async {
    final rows = await _store.query(
      collection: FirestorePaths.odRequests,
      field: 'student_id',
      isEqualTo: studentId,
    );
    return rows
        .map((row) => OdRequestModel.fromMap(row['id'] as String? ?? '', row))
        .toList();
  }

  @override
  Stream<List<OdRequest>> watchByStudent(String studentId) {
    return _store
        .watchQuery(
          collection: FirestorePaths.odRequests,
          field: 'student_id',
          isEqualTo: studentId,
        )
        .map(
          (rows) => rows
              .map((row) => OdRequestModel.fromMap(row['id'] as String? ?? '', row))
              .toList(),
        );
  }

  @override
  Future<List<OdRequest>> getPendingForRole(String roleScope) async {
    final rows = await _store.query(
      collection: FirestorePaths.odRequests,
      field: 'current_approver_role',
      isEqualTo: roleScope,
    );
    return rows
        .map((row) => OdRequestModel.fromMap(row['id'] as String? ?? '', row))
        .toList();
  }

  @override
  Stream<List<OdRequest>> watchPendingForRole(String roleScope) {
    return _store
        .watchQuery(
          collection: FirestorePaths.odRequests,
          field: 'current_approver_role',
          isEqualTo: roleScope,
        )
        .map(
          (rows) => rows
              .map((row) => OdRequestModel.fromMap(row['id'] as String? ?? '', row))
              .toList(),
        );
  }

  @override
  Future<void> update(OdRequest request) async {
    final model = OdRequestModel(
      id: request.id,
      studentId: request.studentId,
      eventName: request.eventName,
      organizer: request.organizer,
      venue: request.venue,
      startDateTime: request.startDateTime,
      endDateTime: request.endDateTime,
      isMultiDay: request.isMultiDay,
      reason: request.reason,
      status: request.status,
      proofUrl: request.proofUrl,
      createdAt: request.createdAt,
      updatedAt: DateTime.now(),
    );
    await _store.set(
      collection: FirestorePaths.odRequests,
      id: request.id,
      data: model.toMap(),
    );
  }
}
