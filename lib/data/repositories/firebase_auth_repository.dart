import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/login_identifier_normalizer.dart';
import '../services/firestore_paths.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AppUser?> authStateChanges() {
    return _firebaseAuth.authStateChanges().asyncMap(_resolveUserProfile);
  }

  @override
  Future<AppUser?> currentUser() async {
    return _resolveUserProfile(_firebaseAuth.currentUser);
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = LoginIdentifierNormalizer.toEmail(email);
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final appUser = await _resolveUserProfile(credential.user);
    if (appUser == null) {
      throw StateError('User profile missing in Firestore.');
    }
    return appUser;
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  Future<void> updatePassword(String newPassword) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('No authenticated user session.');
    }
    await user.updatePassword(newPassword);
    await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
      'requires_password_change': false,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<AppUser?> _resolveUserProfile(User? firebaseUser) async {
    if (firebaseUser == null) return null;

    final profileSnap =
        await _firestore.collection(FirestorePaths.users).doc(firebaseUser.uid).get();
    if (!profileSnap.exists) {
      return AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        fullName: firebaseUser.displayName ?? 'User',
        role: UserRole.student,
        regNo: null,
        staffId: null,
        phone: null,
        department: '',
        className: null,
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        requiresPasswordChange: false,
      );
    }
    final data = profileSnap.data() ?? <String, dynamic>{};
    return AppUser(
      id: firebaseUser.uid,
      email: data['email'] as String? ?? firebaseUser.email ?? '',
      fullName: data['full_name'] as String? ?? firebaseUser.displayName ?? 'User',
      role: UserRoleX.fromValue(data['role'] as String? ?? 'student'),
      regNo: data['reg_no'] as String?,
      staffId: data['staff_id'] as String?,
      phone: data['phone'] as String?,
      department: data['department'] as String? ?? '',
      className: data['class_name'] as String?,
      section: data['section'] as String?,
      classAdvisorId: data['class_advisor_id'] as String?,
      photoUrl: data['photo_url'] as String? ?? firebaseUser.photoURL,
      createdAt: _toDateTime(data['created_at']),
      updatedAt: _toDateTime(data['updated_at']),
      isActive: data['is_active'] as bool? ?? true,
      requiresPasswordChange:
          data['requires_password_change'] as bool? ?? false,
    );
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }
}
