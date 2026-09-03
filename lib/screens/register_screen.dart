import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/services/login_identifier_normalizer.dart';

class ODRegisterScreen extends StatefulWidget {
  const ODRegisterScreen({super.key});

  @override
  State<ODRegisterScreen> createState() => _ODRegisterScreenState();
}

class _ODRegisterScreenState extends State<ODRegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _registering = false;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  static const int _passwordLength = 8;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _isValidPassword {
    final p = _passwordController.text.trim();
    if (p.length != _passwordLength) return false;
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(p);
  }

  /// True if string is empty or only digits (integers).
  bool _isOnlyIntegers(String s) {
    final t = s.trim();
    if (t.isEmpty) return true;
    return RegExp(r'^[\d\s]+$').hasMatch(t);
  }

  /// First priority: username (Full Name). If that's only integers, take from mail.
  String get _displayName {
    final name = _fullNameController.text.trim();
    if (name.isNotEmpty && !_isOnlyIntegers(name)) {
      final first = name.split(RegExp(r'\s+')).first;
      if (first.isNotEmpty && !_isOnlyIntegers(first)) {
        return first[0].toUpperCase() + first.substring(1).toLowerCase();
      }
    }
    final email = _emailController.text.trim();
    if (email.isEmpty) return '';
    final i = email.indexOf('@');
    if (i <= 0) return '';
    final prefix = email.substring(0, i);
    final firstPart = prefix.contains('.') ? prefix.split('.').first : prefix;
    if (firstPart.isEmpty) return prefix;
    return firstPart[0].toUpperCase() + firstPart.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Container(
          width: 960,
          height: 540,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // LEFT SIDE (same as login)
              Expanded(
                child: Container(
                  color: Theme.of(context).cardColor,
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
                        style: textTheme.titleLarge?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "OD Requests Made Simple",
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // RIGHT SIDE (Register form)
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
                        "Register",
                        style: TextStyle(
                          fontSize: 26,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputField("Full Name", Icons.person_outline, false,
                          controller: _fullNameController),
                      const SizedBox(height: 12),
                      _inputField("College Email", Icons.mail_outline, false,
                          controller: _emailController),
                      const SizedBox(height: 12),
                      _passwordField(
                        "Password (8 chars, letters & numbers)",
                        _obscurePassword,
                        _passwordController,
                        () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      const SizedBox(height: 12),
                      _passwordField(
                        "Confirm Password",
                        _obscureConfirmPassword,
                        _confirmPasswordController,
                        () {
                          setState(() =>
                              _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      const SizedBox(height: 24),
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
                          onPressed: _registering ? null : _register,
                          child: _registering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const Spacer(flex: 1),
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

  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }
    if (!_isValidPassword) {
      _showError('Password must be 8 characters (letters and numbers only)');
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final fullName = _fullNameController.text.trim();
    if (fullName.isEmpty || !email.contains('@')) {
      _showError('Enter your full name and a valid email.');
      return;
    }

    setState(() => _registering = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text,
          );
      final user = credential.user;
      if (user == null) throw StateError('Account creation failed.');

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': email,
        'full_name': fullName,
        'role': 'student',
        'department': LoginIdentifierNormalizer.departmentFromEmail(email),
        'is_active': true,
        'requires_password_change': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pop(context, _displayName);
    } on FirebaseAuthException catch (error) {
      _showError(error.message ?? 'Unable to create account.');
    } catch (error) {
      _showError(error.toString());
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Widget _passwordField(
    String hint,
    bool obscure,
    TextEditingController controller,
    VoidCallback onToggle,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: Colors.white,
        autofillHints: hint.toLowerCase().contains('confirm')
            ? const [AutofillHints.newPassword]
            : const [AutofillHints.newPassword, AutofillHints.password],
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(_passwordLength),
        ],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white70,
              size: 22,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    IconData icon,
    bool obscureText, {
    TextEditingController? controller,
  }) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: Colors.white,
        autofillHints: hint == "Full Name"
            ? const [AutofillHints.name]
            : const [AutofillHints.username, AutofillHints.email],
        keyboardType: hint == "College Email"
            ? TextInputType.emailAddress
            : TextInputType.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(icon, color: Colors.white70, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
    );
  }
}
