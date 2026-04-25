class LoginIdentifierNormalizer {
  const LoginIdentifierNormalizer._();

  /// Supports:
  /// - full email -> unchanged
  /// - student reg number -> reg_no@students.ritchennai.edu.in
  /// - staff id (alpha-numeric) -> staff_id@staff.ritchennai.edu.in
  static String toEmail(String input) {
    final value = input.trim().toLowerCase();
    if (value.contains('@')) return value;

    final digitsOnly = RegExp(r'^\d+$').hasMatch(value);
    if (digitsOnly) return '$value@students.ritchennai.edu.in';

    final alphaNum = RegExp(r'^[a-z0-9._-]+$').hasMatch(value);
    if (alphaNum) return '$value@staff.ritchennai.edu.in';

    return value;
  }
}
