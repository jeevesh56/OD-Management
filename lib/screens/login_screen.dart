import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../api_service.dart';
import '../student_home_screen.dart';
import '../mentor_home_screen.dart';
import '../hod_home_screen.dart';
import '../principal_home_screen.dart';
import 'register_screen.dart';

class ODLoginUI extends StatefulWidget {
  const ODLoginUI({super.key});

  @override
  State<ODLoginUI> createState() => _ODLoginUIState();
}

class _ODLoginUIState extends State<ODLoginUI> {
  String _loginType = 'student'; // student | mentor | hod | principal
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

  bool get _isValidRoleEmail {
    final email = _emailController.text.trim();
    if (email.isEmpty) return false;
    return AuthStore.isValidRoleEmail(email);
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
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: 960,
          height: 540,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                      Text(
                        "OD Management System",
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "OD Requests Made Simple",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF4B5563),
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
                      colors: [Color(0xFF11154A), Color(0xFF050733)],
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
                              }
                            },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: Color(0xFFF1F5FF),
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
                            foregroundColor: Colors.white,
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
                      Row(children: [Expanded(child: _loginTypeToggle())]),
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
      if (!_isValidRoleEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Mentor email must be: name@department.ritchennai.edu.in",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      AuthStore.applyMentorLogin(_emailController.text);
      _registerFcmForCurrentUser('mentor');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MentorHomeScreen()),
      );
      return;
    } else if (_loginType == 'principal') {
      if (!_isValidRoleEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Principal email must be: name@department.ritchennai.edu.in",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      AuthStore.applyPrincipalLogin(_emailController.text);
      _registerFcmForCurrentUser('principal');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PrincipalHomeScreen()),
      );
      return;
    } else if (_loginType == 'hod') {
      if (!_isValidRoleEmail) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "HoD email must be: name@department.ritchennai.edu.in",
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      AuthStore.applyHodLogin(_emailController.text);
      _registerFcmForCurrentUser('hod');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HoDHomeScreen()),
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
    _registerFcmForCurrentUser('student');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StudentHomeScreen()),
    );
  }

  Future<void> _registerFcmForCurrentUser(String role) async {
    final userId = AuthStore.userId ?? _emailController.text.trim();
    if (userId.isEmpty) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcm_token': token,
      'role': role,
      'user_id': userId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _loginTypeToggle() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
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
          Expanded(child: _toggleButton("HoD", _loginType == 'hod', 'hod')),
          Expanded(
            child: _toggleButton(
              "Principal",
              _loginType == 'principal',
              'principal',
            ),
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
          color: isSelected ? const Color(0xFFFF0F9D) : Colors.transparent,
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
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      style: const TextStyle(color: Colors.black, fontSize: 14),
      decoration: InputDecoration(
        labelText: "Password",
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F3D91), width: 1.2),
        ),
        prefixIcon: const Icon(
          Icons.lock_outline,
          color: Colors.black54,
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.black54,
            size: 22,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: hint == "College Email"
          ? const [AutofillHints.username, AutofillHints.email]
          : null,
      keyboardType: hint == "College Email"
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: const TextStyle(color: Colors.black, fontSize: 14),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0F3D91), width: 1.2),
        ),
        prefixIcon: Icon(icon, color: Colors.black54, size: 20),
      ),
    );
  }
}
