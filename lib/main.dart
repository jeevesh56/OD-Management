import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'presentation/app/auth_gate.dart';
import 'presentation/app/service_registry.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = true;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Keep legacy flow usable when Firebase is not configured yet.
    firebaseEnabled = false;
  }
  runApp(MyApp(firebaseEnabled: firebaseEnabled));
}

class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static void toggle() {
    mode.value = switch (mode.value) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'OD Management System',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 220),
          themeAnimationCurve: Curves.easeInOut,
          home: AuthGate(
            services: firebaseEnabled ? ServiceRegistry.create() : null,
            firebaseEnabled: firebaseEnabled,
          ),
        );
      },
    );
  }
}

