import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    required super.department,
    super.section,
    super.classAdvisorId,
    super.createdAt,
    super.updatedAt,
    super.isActive,
    super.requiresPasswordChange,
  });

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    return AppUserModel(
      id: id,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: UserRoleX.fromValue(map['role'] as String? ?? 'student'),
      department: map['department'] as String? ?? '',
      section: map['section'] as String?,
      classAdvisorId: map['class_advisor_id'] as String?,
      createdAt: _toDateTime(map['created_at']),
      updatedAt: _toDateTime(map['updated_at']),
      isActive: map['is_active'] as bool? ?? true,
      requiresPasswordChange: map['requires_password_change'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'full_name': fullName,
      'role': role.value,
      'department': department,
      'section': section,
      'class_advisor_id': classAdvisorId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
      'requires_password_change': requiresPasswordChange,
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
