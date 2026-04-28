import '../../domain/enums/user_role.dart';

class RoleAccessService {
  const RoleAccessService();

  /// Determine if a user can create OD requests.
  /// Students can always create. Mentors with `isEc==true` can also create EC-type requests.
  bool canCreateOd(UserRole role, {bool isEc = false}) =>
    role == UserRole.student || (role == UserRole.mentor && isEc);

  bool canApproveAsMentor(UserRole role) => role == UserRole.mentor;

  bool canApproveAsHod(UserRole role) => role == UserRole.hod;

  bool canApproveAsPrincipal(UserRole role) =>
    role == UserRole.principal || role == UserRole.admin;

  /// Bulk EC actions allowed only for mentors with isEc permission.
  bool canBulkApplyEc(UserRole role, {bool isEc = false}) =>
    role == UserRole.mentor && isEc;
}
