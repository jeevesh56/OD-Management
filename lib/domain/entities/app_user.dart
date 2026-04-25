import '../enums/user_role.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.department,
    this.section,
    this.classAdvisorId,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.requiresPasswordChange = false,
  });

  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String department;
  final String? section;
  final String? classAdvisorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool requiresPasswordChange;
}
