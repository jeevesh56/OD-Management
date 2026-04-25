import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/document_store.dart';
import '../../data/services/firebase_document_store.dart';

class ServiceRegistry {
  ServiceRegistry._({
    required this.authRepository,
    required this.authService,
    required this.documentStore,
  });

  final FirebaseAuthRepository authRepository;
  final AuthService authService;
  final DocumentStore documentStore;

  static ServiceRegistry create() {
    final firestore = FirebaseFirestore.instance;
    final firebaseAuth = FirebaseAuth.instance;
    final authRepository = FirebaseAuthRepository(
      firebaseAuth: firebaseAuth,
      firestore: firestore,
    );
    return ServiceRegistry._(
      authRepository: authRepository,
      authService: AuthService(authRepository),
      documentStore: FirebaseDocumentStore(firestore),
    );
  }
}
