import 'package:flutter/material.dart';

import '../api_service.dart';
import '../hod_home_screen.dart';

class HoDLoginUI extends StatefulWidget {
  const HoDLoginUI({super.key});

  @override
  State<HoDLoginUI> createState() => _HoDLoginUIState();
}

class _HoDLoginUIState extends State<HoDLoginUI> {
  bool _obscurePassword = true;
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      body: Center(
        child: Container(
          width: 960,
          height: 540,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/od_image.png",
                        height: 195,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        "HoD Login",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF071B3B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Access department OD dashboard",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 40,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF11154A),
                        Color(0xFF050733),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),
                      const Text(
                        "Welcome, HoD",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputField(
                        "Staff ID / Email",
                        Icons.badge_outlined,
                        false,
                        controller: _idController,
                      ),
                      const SizedBox(height: 14),
                      _passwordField(),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF0F9D),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _onContinue,
                          child: const Text(
                            "Continue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_idController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter staff ID and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // For now we keep HoD login local-only, similar to staff login.
    AuthStore.role = 'hod';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const HoDHomeScreen(),
      ),
    );
  }

  Widget _passwordField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: Colors.white70,
            size: 20,
          ),
          hintText: "Password",
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
        ),
      ),
    );
  }

  static Widget _inputField(
    String hint,
    IconData icon,
    bool obscureText, {
    TextEditingController? controller,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

