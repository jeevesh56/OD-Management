import '../../domain/rules/od_rule_engine.dart';
import 'document_store.dart';
import 'firestore_paths.dart';

class AffectedPeriod {
  const AffectedPeriod({
    required this.day,
    required this.periodNo,
    required this.subject,
  });

  final String day;
  final int periodNo;
  final String subject;

  Map<String, dynamic> toMap() => {
        'day': day,
        'period': periodNo,
        'subject': subject,
      };
}

class TimetableEngineService {
  const TimetableEngineService(this._store);

  final DocumentStore _store;

  Future<List<AffectedPeriod>> mapToAffectedPeriods({
    required String department,
    required String section,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isMultiDay,
  }) async {
    // Ensure rule checks are executed before timetable mapping.
    final validation = OdRuleEngine.validateApplication(
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isMultiDay: isMultiDay,
    );
    if (!validation.isValid) return const [];

    final timetableId = '${department}_$section';
    final rows = await _store.query(
      collection: FirestorePaths.timetable,
      field: 'timetable_id',
      isEqualTo: timetableId,
    );
    if (rows.isEmpty) return const [];

    final periods = rows.first['periods'];
    if (periods is! List) return const [];

    final startMinutes = (startDateTime.hour * 60) + startDateTime.minute;
    final endMinutes = (endDateTime.hour * 60) + endDateTime.minute;

    final impacted = <AffectedPeriod>[];
    for (final item in periods) {
      if (item is! Map) continue;
      final from = _timeToMinutes(item['start']?.toString() ?? '');
      final to = _timeToMinutes(item['end']?.toString() ?? '');
      if (from == null || to == null) continue;
      final overlaps = startMinutes < to && endMinutes > from;
      if (!overlaps) continue;
      impacted.add(
        AffectedPeriod(
          day: rows.first['day']?.toString() ?? '',
          periodNo: int.tryParse(item['period_no']?.toString() ?? '') ?? 0,
          subject: item['subject']?.toString() ?? '',
        ),
      );
    }
    return impacted;
  }

  int? _timeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return (h * 60) + m;
  }
}
