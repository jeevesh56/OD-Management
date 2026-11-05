import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/services/login_identifier_normalizer.dart';
import '../theme/app_theme.dart';

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

  // Mobile Teal + Mint colour palette
  static const Color _mobileBackground = Color(0xFFF3F8F6);
  static const Color _mobileBrandBackground = Color(0xFFE1F1EC);
  static const Color _mobileTeal = Color(0xFF087F80);
  static const Color _mobileDarkTeal = Color(0xFF075A60);
  static const Color _mobileMint = Color(0xFF54D6C3);
  static const Color _mobileText = Color(0xFF263B38);
  static const Color _mobileHint = Color(0xFF71817D);

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

  bool _isOnlyIntegers(String s) {
    final t = s.trim();

    if (t.isEmpty) return true;

    return RegExp(r'^[\d\s]+$').hasMatch(t);
  }

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
    return Theme(data: AppTheme.light(), child: _buildScreen(context));
  }

  Widget _buildScreen(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 700;

          final branding = Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: compact
                  ? _mobileBrandBackground
                  : Theme.of(context).cardColor,
              border: compact
                  ? const Border(
                      bottom: BorderSide(color: Color(0xFFC8E4DA), width: 1),
                    )
                  : null,
            ),
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
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 24 : 30,
                    fontWeight: FontWeight.bold,
                    color: compact ? _mobileText : null,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "OD Requests Made Simple",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 16 : 18,
                    color: compact
                        ? _mobileHint
                        : scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          );

          final form = _registrationForm(compact: compact);

          final content = compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [branding, form],
                )
              : SizedBox(
                  height: 540,
                  child: Row(
                    children: [
                      Expanded(child: branding),
                      Expanded(child: form),
                    ],
                  ),
                );

          return Container(
            color: compact ? _mobileBackground : Colors.transparent,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(compact ? 16 : 20),
                      boxShadow: compact
                          ? [
                              BoxShadow(
                                color: _mobileDarkTeal.withValues(alpha: 0.10),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
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

  Widget _registrationForm({required bool compact}) {
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
          if (!compact) const Spacer(flex: 1),

          const Text(
            "Register",
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 22),

          _inputField(
            "Full Name",
            Icons.person_outline,
            false,
            controller: _fullNameController,
            compact: compact,
          ),

          const SizedBox(height: 12),

          _inputField(
            "College Email",
            Icons.mail_outline,
            false,
            controller: _emailController,
            compact: compact,
          ),

          const SizedBox(height: 12),

          _passwordField(
            "Password (8 chars, letters & numbers)",
            _obscurePassword,
            _passwordController,
            () => setState(() => _obscurePassword = !_obscurePassword),
            compact: compact,
          ),

          const SizedBox(height: 12),

          _passwordField(
            "Confirm Password",
            _obscureConfirmPassword,
            _confirmPasswordController,
            () => setState(
              () => _obscureConfirmPassword = !_obscureConfirmPassword,
            ),
            compact: compact,
          ),

          const SizedBox(height: 24),

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
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: compact ? 0 : 2,
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
          if (compact) ...[
            const SizedBox(height: 18),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.white, fontSize: 13),
                  ),

                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        color: Color(0xFF54D6C3),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!compact) const Spacer(flex: 1),
        ],
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

      if (user == null) {
        throw StateError('Account creation failed.');
      }

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
      if (mounted) {
        setState(() => _registering = false);
      }
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
    VoidCallback onToggle, {
    required bool compact,
  }) {
    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: compact ? Colors.white : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: compact ? Border.all(color: const Color(0xFFDCEFE9)) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        cursorColor: compact ? _mobileTeal : Colors.white,
        autofillHints: hint.toLowerCase().contains('confirm')
            ? const [AutofillHints.newPassword]
            : const [AutofillHints.newPassword, AutofillHints.password],
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          LengthLimitingTextInputFormatter(_passwordLength),
        ],
        style: TextStyle(
          color: compact ? _mobileText : Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: compact ? _mobileTeal : Colors.white70,
            size: 20,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: compact ? _mobileHint : Colors.white,
            fontSize: 14,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: compact ? _mobileTeal : Colors.white70,
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
    required bool compact,
  }) {
    return Container(
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: compact ? Colors.white : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: compact ? Border.all(color: const Color(0xFFDCEFE9)) : null,
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        cursorColor: compact ? _mobileTeal : Colors.white,
        autofillHints: hint == "Full Name"
            ? const [AutofillHints.name]
            : const [AutofillHints.username, AutofillHints.email],
        keyboardType: hint == "College Email"
            ? TextInputType.emailAddress
            : TextInputType.text,
        style: TextStyle(
          color: compact ? _mobileText : Colors.white,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          prefixIcon: Icon(
            icon,
            color: compact ? _mobileTeal : Colors.white70,
            size: 20,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: compact ? _mobileHint : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
