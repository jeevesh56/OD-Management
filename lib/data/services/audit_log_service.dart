import 'document_store.dart';
import 'firestore_paths.dart';

class AuditLogService {
  const AuditLogService(this._store);

  final DocumentStore _store;

  Future<void> log({
    required String actorId,
    required String actorRole,
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic>? metadata,
  }) {
    final id = '${action}_${DateTime.now().millisecondsSinceEpoch}';
    return _store.set(
      collection: FirestorePaths.logs,
      id: id,
      data: {
        'log_id': id,
        'actor_id': actorId,
        'actor_role': actorRole,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'metadata': metadata ?? <String, dynamic>{},
        'created_at': DateTime.now().toIso8601String(),
      },
      merge: false,
    );
  }
}
