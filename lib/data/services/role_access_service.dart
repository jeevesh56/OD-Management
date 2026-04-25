import '../../domain/enums/user_role.dart';

class RoleAccessService {
  const RoleAccessService();

  bool canCreateOd(UserRole role) => role == UserRole.student || role == UserRole.ec;

  bool canApproveAsMentor(UserRole role) => role == UserRole.mentor;

  bool canApproveAsHod(UserRole role) => role == UserRole.hod;

  bool canApproveAsPrincipal(UserRole role) =>
      role == UserRole.principal || role == UserRole.admin;

  bool canBulkApplyEc(UserRole role) => role == UserRole.ec;
}
