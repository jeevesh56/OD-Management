import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class UserProfileModel extends UserProfile {
  const UserProfileModel({
    required super.uid,
    required super.role,
    required super.name,
    super.regNo,
    super.staffId,
    super.phone,
    required super.department,
    super.className,
    super.photoUrl,
    required super.mustChangePassword,
    required super.active,
    super.createdAt,
    super.updatedAt,
  });

  factory UserProfileModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfileModel(
      uid: uid,
      role: (map['role'] ?? 'student').toString(),
      name: (map['name'] ?? map['full_name'] ?? '').toString(),
      regNo: _stringOrNull(map['regNo'] ?? map['reg_no']),
      staffId: _stringOrNull(map['staffId'] ?? map['staff_id']),
      phone: _stringOrNull(map['phone']),
      department: (map['department'] ?? '').toString(),
      className: _stringOrNull(map['className'] ?? map['class_name']),
      photoUrl: _stringOrNull(map['photoUrl'] ?? map['photo_url']),
      mustChangePassword:
          (map['mustChangePassword'] ?? map['requires_password_change']) ==
          true,
      active: (map['active'] ?? map['is_active']) != false,
      createdAt: _toDateTime(map['createdAt'] ?? map['created_at']),
      updatedAt: _toDateTime(map['updatedAt'] ?? map['updated_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'full_name': name,
      'regNo': regNo,
      'reg_no': regNo,
      'staffId': staffId,
      'staff_id': staffId,
      'phone': phone,
      'department': department,
      'className': className,
      'class_name': className,
      'photoUrl': photoUrl,
      'photo_url': photoUrl,
      'mustChangePassword': mustChangePassword,
      'requires_password_change': mustChangePassword,
      'active': active,
      'is_active': active,
      'createdAt': createdAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }
}
