import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String portalOdDateLabel(dynamic start, dynamic end) {
  final a = start?.toString() ?? '';
  final b = end?.toString() ?? '';
  if (a.isEmpty && b.isEmpty) return '—';
  if (a == b || b.isEmpty) return a;
  return '$a – $b';
}

DateTime? portalToDateTime(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

String portalOdDateTime(dynamic value) {
  final dt = portalToDateTime(value);
  if (dt == null) return value?.toString() ?? '—';
  return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
}

String portalOdStatusLabel(String status) {
  switch (status) {
    case 'PENDING':
    case 'Pending':
      return 'Pending';
    case 'MENTOR_APPROVED':
      return 'Mentor approved';
    case 'MENTOR_REJECTED':
      return 'Mentor rejected';
    case 'HOD_APPROVED':
      return 'HoD approved';
    case 'PRINCIPAL_APPROVED':
    case 'Approved':
      return 'Approved';
    case 'HOD_REJECTED':
    case 'Rejected':
      return 'HoD rejected';
    case 'CANCELLED':
      return 'Cancelled';
    default:
      return status.isEmpty ? '—' : status;
  }
}

String portalOdBadgeLabel(String status) {
  if (status == 'MENTOR_APPROVED') return 'Mentor OK';
  if (status == 'HOD_APPROVED') return 'HoD OK';
  return portalOdStatusLabel(status);
}

Color portalOdStatusColor(String status) {
  switch (status) {
    case 'PRINCIPAL_APPROVED':
    case 'Approved':
      return Colors.green;
    case 'MENTOR_REJECTED':
    case 'HOD_REJECTED':
    case 'Rejected':
      return Colors.red;
    case 'PENDING':
    case 'Pending':
      return Colors.orange;
    case 'MENTOR_APPROVED':
    case 'HOD_APPROVED':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

String portalOdShortDate(String raw) {
  final d = portalToDateTime(raw);
  if (d == null) return raw;
  return DateFormat('dd MMM yyyy').format(d);
}
