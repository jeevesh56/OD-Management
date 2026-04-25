import '../../domain/entities/app_user.dart';
import '../../domain/repositories/user_repository.dart';

class InMemoryUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};

  @override
  Future<AppUser?> getById(String userId) async => _users[userId];

  @override
  Future<void> upsert(AppUser user) async {
    _users[user.id] = user;
  }
}
