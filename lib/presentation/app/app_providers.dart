import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/repositories/firestore_approval_repository.dart';
import '../../data/repositories/firestore_od_request_repository.dart';
import '../../data/repositories/firestore_user_repository.dart';
import '../../data/services/audit_log_service.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/document_store.dart';
import '../../data/services/ec_request_service.dart';
import '../../data/services/fcm_service.dart';
import '../../data/services/firebase_document_store.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/od_request_service.dart';
import '../../data/services/pdf_export_service.dart';
import '../../data/services/qr_verification_service.dart';
import '../../data/services/request_lifecycle_service.dart';
import '../../data/services/role_access_service.dart';
import '../../data/services/timetable_engine_service.dart';
import '../../data/services/user_profile_service.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/user_role.dart';
import '../../domain/repositories/approval_repository.dart';
import '../../domain/repositories/od_request_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../screens/login_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/qr/qr_scan_screen.dart';
import '../screens/workflow/reviewer_queue_screen.dart';
import '../screens/workflow/student_od_submit_screen.dart';
import '../screens/notifications/notification_center_screen.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final documentStoreProvider = Provider<DocumentStore>((ref) {
  return FirebaseDocumentStore(ref.watch(firestoreProvider));
});

final firebaseAuthRepositoryProvider = Provider<FirebaseAuthRepository>((ref) {
  return FirebaseAuthRepository(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthRepositoryProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(ref.watch(documentStoreProvider));
});

final odRequestRepositoryProvider = Provider<OdRequestRepository>((ref) {
  return FirestoreOdRequestRepository(ref.watch(documentStoreProvider));
});

final approvalRepositoryProvider = Provider<ApprovalRepository>((ref) {
  return FirestoreApprovalRepository(ref.watch(documentStoreProvider));
});

final roleAccessServiceProvider = Provider<RoleAccessService>((ref) {
  return const RoleAccessService();
});

final odRequestServiceProvider = Provider<OdRequestService>((ref) {
  return OdRequestService(
    requestRepository: ref.watch(odRequestRepositoryProvider),
    approvalRepository: ref.watch(approvalRepositoryProvider),
    roleAccessService: ref.watch(roleAccessServiceProvider),
  );
});

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(
    messaging: FirebaseMessaging.instance,
    store: ref.watch(documentStoreProvider),
  );
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(firestoreProvider));
});

final requestLifecycleServiceProvider = Provider<RequestLifecycleService>((
  ref,
) {
  return RequestLifecycleService(ref.watch(firestoreProvider));
});

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final auditLogServiceProvider = Provider<AuditLogService>((ref) {
  return AuditLogService(ref.watch(documentStoreProvider));
});

final timetableEngineProvider = Provider<TimetableEngineService>((ref) {
  return TimetableEngineService(ref.watch(documentStoreProvider));
});

final qrVerificationServiceProvider = Provider<QrVerificationService>((ref) {
  return QrVerificationService(ref.watch(documentStoreProvider));
});

final pdfExportServiceProvider = Provider<PdfExportService>((ref) {
  return PdfExportService(ref.watch(documentStoreProvider));
});

final ecRequestServiceProvider = Provider<EcRequestService>((ref) {
  return EcRequestService(ref.watch(documentStoreProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(firebaseAuthRepositoryProvider).authStateChanges();
});

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const ODLoginUI()),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/home/student',
        builder: (context, state) => const StudentOdSubmitScreen(),
      ),
      GoRoute(
        path: '/home/mentor',
        builder: (context, state) =>
            const ReviewerQueueScreen(roleScope: 'mentor'),
      ),
      GoRoute(
        path: '/home/hod',
        builder: (context, state) =>
            const ReviewerQueueScreen(roleScope: 'hod'),
      ),
      GoRoute(
        path: '/home/principal',
        builder: (context, state) =>
            const ReviewerQueueScreen(roleScope: 'principal'),
      ),
      GoRoute(
        path: '/home/ec',
        builder: (context, state) => const ReviewerQueueScreen(roleScope: 'ec'),
      ),
      GoRoute(
        path: '/home/admin',
        builder: (context, state) =>
            const ReviewerQueueScreen(roleScope: 'admin'),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/qr-scan',
        builder: (context, state) => QrScanScreen(
          verificationService: ref.read(qrVerificationServiceProvider),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggingIn = location == '/login';
      final isChangingPassword = location == '/change-password';

      if (auth.isLoading) return null;
      final user = auth.asData?.value;

      if (user == null) {
        return isLoggingIn ? null : '/login';
      }

      if (user.requiresPasswordChange && !isChangingPassword) {
        return '/change-password';
      }

      if (!user.requiresPasswordChange && (isLoggingIn || isChangingPassword)) {
        return _homeRouteForRole(user.role.value);
      }

      return null;
    },
  );
});

String _homeRouteForRole(String role) {
  return switch (role) {
    'mentor' => '/home/mentor',
    'hod' => '/home/hod',
    'principal' => '/home/principal',
    'ec' => '/home/ec',
    'admin' => '/home/admin',
    _ => '/home/student',
  };
}
