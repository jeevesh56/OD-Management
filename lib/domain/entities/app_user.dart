import '../enums/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.regNo,
    this.staffId,
    this.phone,
    required this.department,
    this.className,
    this.section,
    this.classAdvisorId,
    this.photoUrl,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.requiresPasswordChange = false,
    this.isEc = false,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? regNo;
  final String? staffId;
  final String? phone;
  final String department;
  final String? className;
  final String? section;
  final String? classAdvisorId;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool requiresPasswordChange;
  final bool isEc;
}
