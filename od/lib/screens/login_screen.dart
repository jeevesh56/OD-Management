import 'package:flutter/material.dart';

import '../api_service.dart';
import '../student_home_screen.dart';
import '../mentor_home_screen.dart';
import '../hod_home_screen.dart';
import '../ec_home_screen.dart';
import 'register_screen.dart';

class ODLoginUI extends StatefulWidget {
  const ODLoginUI({super.key});

  @override
  State<ODLoginUI> createState() => _ODLoginUIState();
}

class _ODLoginUIState extends State<ODLoginUI> {
  String _loginType = 'student'; // student | mentor | ec | hod
  bool _obscurePassword = true;
  String? _welcomeUsername;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const String _studentEmailPattern =
      r'^[a-zA-Z]+\.[0-9]+@cse\.ritchennai\.edu\.in$';

  bool get _isValidStudentEmail {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    return RegExp(_studentEmailPattern).hasMatch(email);
  }

  @override
  void dispose() {
    _emailController.dispose();
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
              // LEFT SIDE
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
                        "OD Management System",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF071B3B),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "OD Requests Made Simple",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // RIGHT SIDE (MATCHED HEIGHT)
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
                      Row(
                        children: [
                          const Spacer(),
                          if (!AuthStore.hasRegistered)
                            GestureDetector(
                              onTap: () async {
                                final result = await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ODRegisterScreen(),
                                  ),
                                );
                                if (result != null &&
                                    result.isNotEmpty &&
                                    mounted) {
                                  setState(() => _welcomeUsername = result);
                                  AuthStore.hasRegistered = true;
                                }
                              },
                              child: const Text(
                                "Register",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Spacer(flex: 1),
                      Text(
                        _welcomeUsername != null && _welcomeUsername!.isNotEmpty
                            ? "Welcome, $_welcomeUsername"
                            : "Welcome",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputField(
                        "College Email",
                        Icons.mail_outline,
                        false,
                        controller: _emailController,
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
                      const Spacer(flex: 1),
                      Row(
                        children: [
                          Expanded(
                            child: _loginTypeToggle(),
                          ),
                        ],
                      ),
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
    if (_loginType == 'mentor') {
      AuthStore.applyMentorLogin(_emailController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MentorHomeScreen(),
        ),
      );
      return;
    } else if (_loginType == 'ec') {
      AuthStore.applyEcLogin(_emailController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ECHomeScreen(),
        ),
      );
      return;
    } else if (_loginType == 'hod') {
      AuthStore.applyHodLogin(_emailController.text);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HoDHomeScreen(),
        ),
      );
      return;
    }
    if (!_isValidStudentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Invalid college email. Use format: username.number@cse.ritchennai.edu.in",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    AuthStore.applyStudentLogin(_emailController.text.trim());
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentHomeScreen(),
      ),
    );
  }

  Widget _loginTypeToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton("Student", _loginType == 'student', 'student'),
          ),
          Expanded(
            child: _toggleButton("Mentor", _loginType == 'mentor', 'mentor'),
          ),
          Expanded(
            child: _toggleButton("EC", _loginType == 'ec', 'ec'),
          ),
          Expanded(
            child: _toggleButton("HoD", _loginType == 'hod', 'hod'),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, bool isSelected, String value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loginType = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF0F9D)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
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
          prefixIcon: Icon(Icons.lock_outline, color: Colors.white70, size: 20),
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
