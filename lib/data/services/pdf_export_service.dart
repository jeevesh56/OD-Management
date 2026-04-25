import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'document_store.dart';
import 'firestore_paths.dart';

class PdfExportService {
  const PdfExportService(this._store);

  final DocumentStore _store;

  Future<Uint8List> buildApprovedOdPdf({
    required String requestId,
    required Map<String, dynamic> student,
    required Map<String, dynamic> request,
    required List<Map<String, dynamic>> approvals,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('OD Approval Certificate',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 16),
            pw.Text('Request ID: $requestId'),
            pw.Text('Student: ${student['full_name'] ?? ''}'),
            pw.Text('Reg No: ${student['register_number'] ?? ''}'),
            pw.SizedBox(height: 12),
            pw.Text('Event: ${request['event_name'] ?? ''}'),
            pw.Text('Organizer: ${request['organizer'] ?? ''}'),
            pw.Text('Venue: ${request['venue'] ?? ''}'),
            pw.Text('Status: ${request['status'] ?? ''}'),
            pw.SizedBox(height: 12),
            pw.Text('Approval chain:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...approvals.map(
              (a) => pw.Text(
                  '${a['approver_role']}: ${a['decision']} (${a['reason'] ?? ''})'),
            ),
          ],
        ),
      ),
    );
    final bytes = await doc.save();

    await _store.set(
      collection: FirestorePaths.pdfExports,
      id: '${requestId}_${DateTime.now().millisecondsSinceEpoch}',
      data: {
        'request_id': requestId,
        'generated_at': DateTime.now().toIso8601String(),
        'status': 'GENERATED',
      },
      merge: false,
    );
    return bytes;
  }

  Future<void> preview(Uint8List bytes) {
    return Printing.layoutPdf(onLayout: (_) async => bytes);
  }
}
