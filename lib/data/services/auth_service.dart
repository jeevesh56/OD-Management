import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Firebase adapter placeholder.
///
/// Wire this to `firebase_auth` after dependency/config is added:
/// - signInWithEmailAndPassword
/// - authStateChanges
/// - signOut
class AuthService {
  const AuthService(this.repository);

  final AuthRepository repository;

  Stream<AppUser?> authStateChanges() => repository.authStateChanges();

  Future<AppUser?> currentUser() => repository.currentUser();

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) {
    return repository.signIn(email: email, password: password);
  }

  Future<void> signOut() => repository.signOut();
}
