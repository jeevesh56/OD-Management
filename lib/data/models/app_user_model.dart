import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.isEc,
    super.regNo,
    super.staffId,
    super.phone,
    required super.department,
    super.className,
    super.section,
    super.classAdvisorId,
    super.photoUrl,
    super.createdAt,
    super.updatedAt,
    super.isActive,
    super.requiresPasswordChange,
  });

  factory AppUserModel.fromMap(String id, Map<String, dynamic> map) {
    // legacy: some users may have role 'ec' in the DB. Treat those as mentors with isEc=true
    final rawRole = map['role'] as String? ?? 'student';
    final isEcFlag = (map['is_ec'] as bool?) ?? rawRole == 'ec';

    return AppUserModel(
      id: id,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: UserRoleX.fromValue(rawRole == 'ec' ? 'mentor' : rawRole),
      isEc: isEcFlag,
      regNo: map['reg_no'] as String?,
      staffId: map['staff_id'] as String?,
      phone: map['phone'] as String?,
      department: map['department'] as String? ?? '',
      className: map['class_name'] as String?,
      section: map['section'] as String?,
      classAdvisorId: map['class_advisor_id'] as String?,
      photoUrl: map['photo_url'] as String?,
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
      'is_ec': isEc,
      'reg_no': regNo,
      'staff_id': staffId,
      'phone': phone,
      'department': department,
      'class_name': className,
      'section': section,
      'class_advisor_id': classAdvisorId,
      'photo_url': photoUrl,
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
