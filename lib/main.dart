import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'presentation/app/app_providers.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseFirestore.instance.collection('test').add({
    'msg': 'Firebase connected',
  });
  runApp(ProviderScope(child: const MyApp()));
}

class ThemeController {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static void toggle() {
    mode.value = switch (mode.value) {
      ThemeMode.dark => ThemeMode.light,
      _ => ThemeMode.dark,
    };
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      await ref.read(requestLifecycleServiceProvider).checkAndExpireRequests();
      _expiryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        ref.read(requestLifecycleServiceProvider).checkAndExpireRequests();
      });
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp.router(
        title: 'OD Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        themeAnimationDuration: const Duration(milliseconds: 220),
        themeAnimationCurve: Curves.easeInOut,
        routerConfig: ref.watch(routerProvider),
      ),
    );
  }
}
