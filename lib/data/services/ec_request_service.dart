import 'document_store.dart';
import 'firestore_paths.dart';

class EcRequestService {
  const EcRequestService(this._store);

  final DocumentStore _store;

  Future<void> createBulkRequest({
    required String createdBy,
    required String title,
    required String description,
    required List<String> studentIds,
    required DateTime startDate,
    required DateTime endDate,
    required List<String> targetDepartments,
    String requestType = 'bulk',
  }) async {
    final id = 'ec_${DateTime.now().millisecondsSinceEpoch}';
    await _store.set(
      collection: FirestorePaths.ecRequests,
      id: id,
      data: {
        'ec_request_id': id,
        'created_by': createdBy,
        'request_type': requestType,
        'title': title,
        'description': description,
        'student_ids': studentIds,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'target_departments': targetDepartments,
        'status': 'PENDING_MENTOR',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      merge: false,
    );
  }
}
