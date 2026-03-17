import 'package:flutter/material.dart';
import 'package:od/screens/login_screen.dart';

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
          theme: ThemeData.light(useMaterial3: true),
          darkTheme: ThemeData.dark(useMaterial3: true),
          themeMode: themeMode,
          home: const ODLoginUI(),
        );
      },
    );
  }
}

