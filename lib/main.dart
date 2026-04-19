import 'package:flutter/material.dart';
import 'package:od/screens/login_screen.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class ThemeController {
  static final ValueNotifier<ThemeMode> mode =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          home: const ODLoginUI(),
        );
      },
    );
  }
}

