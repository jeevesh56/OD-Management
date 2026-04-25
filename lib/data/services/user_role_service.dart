import '../../domain/enums/user_role.dart';
import '../../domain/repositories/user_repository.dart';

class UserRoleService {
  const UserRoleService(this._userRepository);

  final UserRepository _userRepository;

  Future<UserRole?> getRole(String userId) async {
    final user = await _userRepository.getById(userId);
    return user?.role;
  }

  Future<bool> hasAnyRole(String userId, Set<UserRole> roles) async {
    final role = await getRole(userId);
    return role != null && roles.contains(role);
  }
}
