import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../data/services/qr_verification_service.dart';
import '../../../domain/enums/user_role.dart';
import '../../app/app_providers.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key, required this.verificationService});

  final QrVerificationService verificationService;

  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  bool _busy = false;
  String _message = 'Scan a student ID QR';

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final value = capture.barcodes.first.rawValue?.trim() ?? '';
    if (value.isEmpty) return;
    setState(() => _busy = true);
    final user = ref.read(authStateProvider).asData?.value;
    final result = await widget.verificationService.verifyRegNo(
      value,
      scannedBy: user?.id,
      scannerRole: user?.role.value,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = result['message']?.toString() ?? 'Verification completed.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Verification')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: _onDetect,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_message),
          ),
        ],
      ),
    );
  }
}
