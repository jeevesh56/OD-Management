import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RITODApp());
}

class RITODApp extends StatelessWidget {
  const RITODApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RIT OD Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
