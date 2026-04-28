enum UserRole {
  student,
  mentor,
  hod,
  principal,
  admin,
}

extension UserRoleX on UserRole {
  String get value => switch (this) {
        UserRole.student => 'student',
        UserRole.mentor => 'mentor',
        UserRole.hod => 'hod',
        UserRole.principal => 'principal',
        UserRole.admin => 'admin',
      };

  static UserRole fromValue(String raw) {
    return UserRole.values.firstWhere(
      (role) => role.value == raw,
      orElse: () => UserRole.student,
    );
  }
}
