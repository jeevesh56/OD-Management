import 'document_store.dart';

class QrVerificationService {
  const QrVerificationService(this._store);

  final DocumentStore _store;

  Future<Map<String, dynamic>> verifyRegNo(String registerNumber) async {
    final requests = await _store.query(
      collection: 'od_requests',
      field: 'student_register_number',
      isEqualTo: registerNumber,
    );
    if (requests.isEmpty) {
      return {
        'valid': false,
        'message': 'No OD request found for this register number.',
      };
    }
    final approved = requests.any((row) => row['status'] == 'PRINCIPAL_APPROVED');
    return {
      'valid': approved,
      'message': approved ? 'OD is active/approved.' : 'OD is not approved yet.',
      'requests': requests,
    };
  }
}
