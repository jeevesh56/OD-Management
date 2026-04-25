import '../entities/app_user.dart';

abstract class UserRepository {
  Future<AppUser?> getById(String userId);
  Future<void> upsert(AppUser user);
}
