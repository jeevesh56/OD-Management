import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('RIT',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0))),
              ),
            ),
            const SizedBox(height: 24),
            const Text('RIT OD Manager',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Rajalakshmi Institute of Technology',
              style: TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
