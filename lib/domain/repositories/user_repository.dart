import '../entities/app_user.dart';

abstract class UserRepository {
  Future<AppUser?> getById(String userId);
  Stream<AppUser?> watchById(String userId);
  Future<void> upsert(AppUser user);
  Future<void> updateProfile(AppUser user);
}
