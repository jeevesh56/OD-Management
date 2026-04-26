import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api_service.dart';

class ProofActionButtons extends StatelessWidget {
  const ProofActionButtons({
    super.key,
    required this.fileUrl,
    this.showDownload = false,
  });

  final String fileUrl;
  final bool showDownload;

  bool get _hasProof => fileUrl.trim().isNotEmpty;

  bool _looksLikePdf(String value) {
    final lower = value.toLowerCase();
    return lower.contains('.pdf') || lower.startsWith('data:application/pdf');
  }

  bool _looksLikeImage(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('data:image/') ||
        lower.contains('.png') ||
        lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.webp') ||
        lower.contains('.gif');
  }

  Future<void> _openProof(BuildContext context) async {
    final fullUrl = getFullUrl(fileUrl.trim());
    if (fullUrl.isEmpty) return;
    final uri = Uri.tryParse(fullUrl);
    if (uri == null) return;

    if (_looksLikePdf(fullUrl)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }

    if (_looksLikeImage(fullUrl)) {
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Proof')),
            body: Center(child: Image.network(fullUrl)),
          ),
        ),
      );
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _downloadProof() async {
    final fullUrl = getFullUrl(fileUrl.trim());
    if (fullUrl.isEmpty) return;
    final uri = Uri.tryParse(fullUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasProof) {
      return const Text('No proof uploaded');
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.visibility),
          label: const Text('View Proof'),
          onPressed: () => _openProof(context),
        ),
        if (showDownload)
          OutlinedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download'),
            onPressed: _downloadProof,
          ),
      ],
    );
  }
}
