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

  static String displayNameFromEmail(String email) {
    final localPart = email.trim().toLowerCase().split('@').first;
    final namePart = localPart.split(RegExp(r'[._-]')).first;
    final lettersOnly = namePart.replaceAll(RegExp(r'[^a-z]'), '');
    if (lettersOnly.isEmpty) return 'User';
    return '${lettersOnly[0].toUpperCase()}${lettersOnly.substring(1)}';
  }

  static String departmentFromEmail(String email) {
    final domain = email.trim().toLowerCase().split('@').skip(1).join('@');
    final parts = domain.split('.');
    if (parts.contains('cse')) return 'CSE';
    return '';
  }
}
