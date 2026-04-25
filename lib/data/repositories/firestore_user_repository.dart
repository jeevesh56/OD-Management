import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/app_user_model.dart';
import '../services/document_store.dart';
import '../services/firestore_paths.dart';

class FirestoreUserRepository implements UserRepository {
  const FirestoreUserRepository(this._store);

  final DocumentStore _store;

  @override
  Future<AppUser?> getById(String userId) async {
    final data = await _store.get(collection: FirestorePaths.users, id: userId);
    if (data == null) return null;
    return AppUserModel.fromMap(userId, data);
  }

  @override
  Future<void> upsert(AppUser user) async {
    final model = AppUserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      department: user.department,
      section: user.section,
      classAdvisorId: user.classAdvisorId,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt ?? DateTime.now(),
      isActive: user.isActive,
      requiresPasswordChange: user.requiresPasswordChange,
    );
    await _store.set(
      collection: FirestorePaths.users,
      id: user.id,
      data: model.toMap(),
    );
  }
}
