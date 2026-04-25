import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../api_service.dart';
import '../widgets/portal_page_layout.dart';

/// OD pass QR — shown after final approval; same portal background.
class PortalQrScreen extends StatelessWidget {
  const PortalQrScreen({
    super.key,
    required this.eventName,
    required this.requestId,
  });

  final String eventName;
  final String requestId;

  String get _qrPayload {
    final reg = AuthStore.registrationFromLoginEmail().isNotEmpty
        ? AuthStore.registrationFromLoginEmail()
        : (AuthStore.studentProfile?['register_number']?.toString() ?? '');
    final name = AuthStore.fullName ?? 'Student';
    return jsonEncode({
      'type': 'od_pass',
      'request_id': requestId,
      'event': eventName,
      'student': name,
      'register': reg,
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AuthStore.fullName ?? 'Student';
    final reg = AuthStore.registrationFromLoginEmail().isNotEmpty
        ? AuthStore.registrationFromLoginEmail()
        : (AuthStore.studentProfile?['register_number']?.toString() ?? '—');

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        elevation: 0,
        title: const Text(
          'OD pass',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 16),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                24,
                40,
              ),
              child: Column(
                children: [
                  Text(
                    eventName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Show this at the verification desk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: portalCardDecoration(context, radius: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: QrImageView(
                            data: _qrPayload,
                            version: QrVersions.auto,
                            size: 220,
                            eyeStyle: QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: scheme.primary,
                            ),
                            dataModuleStyle: QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: scheme.primary,
                            ),
                            backgroundColor: scheme.surface,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reg. No: $reg',
                          style: TextStyle(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded,
                                  color: Colors.green.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'HoD approved OD',
                                style: TextStyle(
                                  color: scheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
