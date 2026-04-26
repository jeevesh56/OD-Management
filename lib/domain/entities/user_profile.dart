class UserProfile {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.name,
    this.regNo,
    this.staffId,
    this.phone,
    required this.department,
    this.className,
    this.photoUrl,
    required this.mustChangePassword,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  final String uid;
  final String role;
  final String name;
  final String? regNo;
  final String? staffId;
  final String? phone;
  final String department;
  final String? className;
  final String? photoUrl;
  final bool mustChangePassword;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
