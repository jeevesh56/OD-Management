import 'document_store.dart';
import 'firestore_paths.dart';

class QrVerificationService {
  const QrVerificationService(this._store);

  final DocumentStore _store;

  Future<Map<String, dynamic>> verifyRegNo(
    String registerNumber, {
    String? scannedBy,
    String? scannerRole,
  }) async {
    final requests = await _store.query(
      collection: 'od_requests',
      field: 'student_register_number',
      isEqualTo: registerNumber,
    );
    if (requests.isEmpty) {
      final response = {
        'valid': false,
        'message': 'No OD request found for this register number.',
      };
      await _writeScanLog(
        requestId: null,
        registerNumber: registerNumber,
        scannedBy: scannedBy,
        scannerRole: scannerRole,
        result: 'invalid',
      );
      return response;
    }
    final approved = requests.any((row) => row['status'] == 'PRINCIPAL_APPROVED');
    final response = {
      'valid': approved,
      'message': approved ? 'OD is active/approved.' : 'OD is not approved yet.',
      'requests': requests,
    };
    await _writeScanLog(
      requestId: requests.first['id']?.toString(),
      registerNumber: registerNumber,
      scannedBy: scannedBy,
      scannerRole: scannerRole,
      result: approved ? 'valid' : 'invalid',
    );
    return response;
  }

  Future<void> _writeScanLog({
    required String? requestId,
    required String registerNumber,
    required String? scannedBy,
    required String? scannerRole,
    required String result,
  }) async {
    final id = 'scan_${DateTime.now().millisecondsSinceEpoch}';
    await _store.set(
      collection: FirestorePaths.scanLogs,
      id: id,
      data: {
        'scan_log_id': id,
        'request_id': requestId,
        'student_register_number': registerNumber,
        'scanned_by': scannedBy,
        'scanner_role': scannerRole,
        'result': result,
        'created_at': DateTime.now().toIso8601String(),
      },
      merge: false,
    );
  }
}
