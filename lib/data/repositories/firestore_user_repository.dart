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
  Stream<AppUser?> watchById(String userId) {
    return _store
        .watchDocument(collection: FirestorePaths.users, id: userId)
        .map((data) => data == null ? null : AppUserModel.fromMap(userId, data));
  }

  @override
  Future<void> upsert(AppUser user) async {
    final model = AppUserModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      regNo: user.regNo,
      staffId: user.staffId,
      phone: user.phone,
      department: user.department,
      className: user.className,
      section: user.section,
      classAdvisorId: user.classAdvisorId,
      photoUrl: user.photoUrl,
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

  @override
  Future<void> updateProfile(AppUser user) => upsert(user);
}
