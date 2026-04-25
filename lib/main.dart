import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/app/app_providers.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var firebaseEnabled = true;
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Fallback keeps web/app usable until Firebase web options are configured.
    firebaseEnabled = false;
  }
  runApp(
    ProviderScope(
      child: MyApp(firebaseEnabled: firebaseEnabled),
    ),
  );
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key, required this.firebaseEnabled});

  final bool firebaseEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!firebaseEnabled) {
      return MaterialApp(
        title: 'OD Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        themeAnimationDuration: const Duration(milliseconds: 220),
        themeAnimationCurve: Curves.easeInOut,
        home: const ODLoginUI(),
      );
    }

    return MaterialApp.router(
      title: 'OD Management System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.light,
      themeAnimationDuration: const Duration(milliseconds: 220),
      themeAnimationCurve: Curves.easeInOut,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

