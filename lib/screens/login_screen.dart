import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../hod_home_screen.dart';
import '../mentor_home_screen.dart';
import '../principal_home_screen.dart';
import '../api_service.dart';
import '../data/services/login_identifier_normalizer.dart';
import '../theme/app_theme.dart';
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
  static const Color _mobileBackground = Color(0xFFF3F8F6);
  static const Color _mobileBrandBackground = Color(0xFFE1F1EC);
  static const Color _mobileTeal = Color(0xFF087F80);
  static const Color _mobileDarkTeal = Color(0xFF075A60);
  static const Color _mobileMint = Color(0xFF54D6C3);
  static const Color _mobileText = Color(0xFF263B38);
  static const Color _mobileHint = Color(0xFF71817D);

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
    return Theme(data: AppTheme.light(), child: _buildScreen(context));
  }

  Widget _buildScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;
          final content = compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brandingPanel(compact: true),
                    _loginPanel(compact: true),
                  ],
                )
              : SizedBox(
                  height: 540,
                  child: Row(
                    children: [
                      Expanded(child: _brandingPanel()),
                      Expanded(child: _loginPanel()),
                    ],
                  ),
                );

          return Container(
            color: compact ? _mobileBackground : scheme.surfaceContainerLowest,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 960,
                    minHeight: compact ? 0 : 540,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(compact ? 16 : 20),
                      border: Border.all(color: scheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: content,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _brandingPanel({bool compact = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: compact ? _mobileBrandBackground : scheme.surfaceContainerHigh,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 32,
        vertical: compact ? 24 : 20,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/od_image.png", fit: BoxFit.contain),
          SizedBox(height: compact ? 12 : 22),
          Text(
            "OD Management System",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: compact ? _mobileText : scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "OD Requests Made Simple",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: compact
                  ? _mobileHint
                  : scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPanel({bool compact = false}) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 20 : 40,
        compact ? 24 : 40,
        compact ? 20 : 40,
        compact ? 24 : 40,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: compact
              ? const [_mobileTeal, _mobileDarkTeal]
              : const [Color(0xFF11154A), Color(0xFF050733)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ODRegisterScreen(),
                  ),
                );
                if (result != null && result.isNotEmpty && mounted) {
                  setState(() => _welcomeUsername = result);
                }
              },
              child: Text(
                "Register",
                style: TextStyle(
                  color: compact ? _mobileMint : Color(0xFFF1F5FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 20 : 16),
          if (!compact) const Spacer(flex: 1),
          Text(
            _welcomeUsername != null && _welcomeUsername!.isNotEmpty
                ? "Welcome, $_welcomeUsername"
                : "Welcome",
            style: TextStyle(
              fontSize: compact ? 25 : 28,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          _inputField(
            "College Email",
            Icons.mail_outline,
            false,
            controller: _emailController,
            compact: compact,
          ),
          const SizedBox(height: 14),
          _passwordField(compact: compact),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: compact
                    ? _mobileMint
                    : const Color(0xFFFF0F9D),
                foregroundColor: compact ? _mobileDarkTeal : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _onContinue,
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: compact ? 22 : 0),
          if (!compact) const Spacer(flex: 1),
          _loginTypeToggle(compact: compact),
        ],
      ),
    );
  }

  Future<void> _onContinue() async {
    AuthStore.setLoginEmail(_emailController.text);
    if (_loginType == 'mentor') {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an email and password.')),
        );
        return;
      }
      await _openRole('mentor', const MentorHomeScreen());
      return;
    } else if (_loginType == 'principal') {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an email and password.')),
        );
        return;
      }
      await _openRole('principal', const PrincipalHomeScreen());
      return;
    } else if (_loginType == 'hod') {
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter an email and password.')),
        );
        return;
      }
      await _openRole('hod', const HoDHomeScreen());
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
    await _signIn();
  }

  Future<void> _openRole(String role, Widget screen) async {
    final normalizedLogin = LoginIdentifierNormalizer.toEmail(
      _emailController.text,
    );
    AuthStore.setLoginEmail(normalizedLogin);
    try {
      // TEMPORARY: staff authentication is bypassed for development only.
      // Replace this with proper credential authentication before production.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Unable to open role page')),
        );
      }
      return;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    AuthStore.role = role;
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _signIn() async {
    final enteredId = _emailController.text.trim();
    final emailCandidates = enteredId.contains('@')
        ? <String>[LoginIdentifierNormalizer.toEmail(enteredId)]
        : <String>[
            '$enteredId@staff.ritchennai.edu.in',
            '$enteredId@department.ritchennai.edu.in',
            '$enteredId@cse.ritchennai.edu.in',
          ];
    FirebaseAuthException? lastError;
    for (final email in emailCandidates) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );
        return;
      } on FirebaseAuthException catch (error) {
        lastError = error;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lastError?.message ??
              'Unable to sign in. Check the role email and password.',
        ),
      ),
    );
  }

  Widget _loginTypeToggle({bool compact = false}) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              "Student",
              _loginType == 'student',
              'student',
              compact: compact,
            ),
          ),
          Expanded(
            child: _toggleButton(
              "Mentor",
              _loginType == 'mentor',
              'mentor',
              compact: compact,
            ),
          ),
          Expanded(
            child: _toggleButton(
              "HoD",
              _loginType == 'hod',
              'hod',
              compact: compact,
            ),
          ),
          Expanded(
            child: _toggleButton(
              "Principal",
              _loginType == 'principal',
              'principal',
              compact: compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(
    String label,
    bool isSelected,
    String value, {
    bool compact = false,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _loginType = value;
          _emailController.clear();
          _passwordController.clear();
          _welcomeUsername = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? (compact ? _mobileMint : const Color(0xFFFF0F9D))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isSelected
                  ? Colors.white
                  : (compact
                        ? _mobileMint.withValues(alpha: 0.78)
                        : Colors.white70),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({required bool compact}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: compact ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        autofillHints: const [AutofillHints.password],
        style: TextStyle(
          color: compact ? _mobileText : Colors.black,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: "Password",
          labelStyle: TextStyle(color: compact ? _mobileText : Colors.black),
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
          prefixIcon: Icon(
            Icons.lock_outline,
            color: compact ? _mobileTeal : Colors.black54,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: compact ? _mobileTeal : Colors.black54,
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
    required bool compact,
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
      style: TextStyle(
        color: compact ? _mobileText : Colors.black,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: TextStyle(color: compact ? _mobileText : Colors.black),
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
        prefixIcon: Icon(
          icon,
          color: compact ? _mobileTeal : Colors.black54,
          size: 20,
        ),
      ),
    );
  }
}
