import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile_model.dart';
import 'firestore_paths.dart';

class UserProfileService {
  UserProfileService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Stream<UserProfileModel?> watchProfile(String uid) {
    return _firestore.collection(FirestorePaths.users).doc(uid).snapshots().map(
      (doc) {
        final data = doc.data();
        if (data == null) return null;
        return UserProfileModel.fromMap(doc.id, data);
      },
    );
  }

  Future<UserProfileModel?> getProfile(String uid) async {
    final doc = await _firestore
        .collection(FirestorePaths.users)
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null) return null;
    return UserProfileModel.fromMap(doc.id, data);
  }

  Future<void> updateEditableFields({
    required String uid,
    required String name,
    required String phone,
    required String department,
    required String className,
    String? photoUrl,
  }) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).set({
      'name': name.trim(),
      'full_name': name.trim(),
      'phone': phone.trim(),
      'department': department.trim(),
      'className': className.trim(),
      'class_name': className.trim(),
      'photoUrl': photoUrl?.trim(),
      'photo_url': photoUrl?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No active user session.');
    }
    await user.updatePassword(newPassword);
    await _firestore.collection(FirestorePaths.users).doc(user.uid).set({
      'mustChangePassword': false,
      'requires_password_change': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
