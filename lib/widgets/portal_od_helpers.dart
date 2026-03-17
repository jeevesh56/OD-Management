import 'package:flutter/material.dart';

String portalOdDateLabel(dynamic start, dynamic end) {
  final a = start?.toString() ?? '';
  final b = end?.toString() ?? '';
  if (a.isEmpty && b.isEmpty) return '—';
  if (a == b || b.isEmpty) return a;
  return '$a – $b';
}

String portalOdStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
      return 'Pending';
    case 'MENTOR_APPROVED':
      return 'Mentor approved';
    case 'MENTOR_REJECTED':
      return 'Mentor rejected';
    case 'EC_CONFIRMED':
      return 'EC confirmed';
    case 'EC_REJECTED':
      return 'EC rejected';
    case 'HOD_APPROVED':
      return 'Approved';
    case 'HOD_REJECTED':
      return 'HoD rejected';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status.isEmpty ? '—' : status;
  }
}

String portalOdBadgeLabel(String status) {
  if (status == 'MENTOR_APPROVED') return 'Mentor OK';
  return portalOdStatusLabel(status);
}

Color portalOdStatusColor(String status) {
  switch (status) {
    case 'HOD_APPROVED':
      return Colors.green;
    case 'MENTOR_REJECTED':
    case 'EC_REJECTED':
    case 'HOD_REJECTED':
      return Colors.red;
    case 'PENDING':
      return Colors.orange;
    case 'MENTOR_APPROVED':
    case 'EC_CONFIRMED':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

String portalOdShortDate(String raw) {
  if (raw.length >= 10 && raw.contains('-')) {
    try {
      final d = DateTime.parse(raw);
      const m = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${d.day} ${m[d.month - 1]} ${d.year}';
    } catch (_) {}
  }
  return raw;
}
