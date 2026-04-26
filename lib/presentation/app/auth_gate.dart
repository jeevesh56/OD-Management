import 'package:flutter/material.dart';

import '../../domain/enums/user_role.dart';
import '../../hod_home_screen.dart';
import '../../mentor_home_screen.dart';
import '../../principal_home_screen.dart';
import '../../screens/login_screen.dart';
import '../../student_home_screen.dart';
import 'service_registry.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/auth/change_password_screen.dart';
import '../screens/auth/firebase_login_screen.dart';
import '../screens/ec/ec_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.services, required this.firebaseEnabled});

  final ServiceRegistry? services;
  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    if (!firebaseEnabled) {
      return const ODLoginUI();
    }
    final serviceRegistry = services;
    if (serviceRegistry == null) {
      return const ODLoginUI();
    }

    return StreamBuilder(
      stream: serviceRegistry.authService.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return FirebaseLoginScreen(authService: serviceRegistry.authService);
        }

        if (user.requiresPasswordChange) {
          return const ChangePasswordScreen();
        }

        return switch (user.role) {
          UserRole.student => const StudentHomeScreen(),
          UserRole.mentor => const MentorHomeScreen(),
          UserRole.hod => const HoDHomeScreen(),
          UserRole.principal => const PrincipalHomeScreen(),
          UserRole.ec => const EcHomeScreen(),
          UserRole.admin => const AdminHomeScreen(),
        };
      },
    );
  }
}
