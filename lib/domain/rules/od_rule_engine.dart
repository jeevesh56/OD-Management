class RuleViolation {
  const RuleViolation({required this.code, required this.message});

  final String code;
  final String message;
}

class RuleValidationResult {
  const RuleValidationResult(this.violations);

  final List<RuleViolation> violations;

  bool get isValid => violations.isEmpty;
}

class OdRuleEngine {
  static RuleValidationResult validateApplication({
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isMultiDay,
  }) {
    final violations = <RuleViolation>[];

    final now = DateTime.now();
    if (_isPastDate(startDateTime, now)) {
      violations.add(
        const RuleViolation(
          code: 'PAST_DATE_NOT_ALLOWED',
          message: 'OD cannot be applied for a past date.',
        ),
      );
    }

    final multiDayViolation = _validateMultiDayLogic(
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isMultiDay: isMultiDay,
    );
    if (multiDayViolation != null) {
      violations.add(multiDayViolation);
    }

    return RuleValidationResult(violations);
  }

  static RuleValidationResult validateRejectionReason(String? reason) {
    final trimmed = reason?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const RuleValidationResult([
        RuleViolation(
          code: 'REJECTION_REASON_REQUIRED',
          message: 'Rejection reason is mandatory.',
        ),
      ]);
    }
    return const RuleValidationResult([]);
  }

  static bool _isPastDate(DateTime startDateTime, DateTime now) {
    final startDay = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return startDay.isBefore(today);
  }

  static RuleViolation? _validateMultiDayLogic({
    required DateTime startDateTime,
    required DateTime endDateTime,
    required bool isMultiDay,
  }) {
    final sameDay =
        startDateTime.year == endDateTime.year &&
        startDateTime.month == endDateTime.month &&
        startDateTime.day == endDateTime.day;

    if (!isMultiDay && !sameDay) {
      return const RuleViolation(
        code: 'SINGLE_DAY_MUST_HAVE_SAME_DATE',
        message: 'Single-day OD must have same start and end date.',
      );
    }

    if (isMultiDay && sameDay) {
      return const RuleViolation(
        code: 'MULTI_DAY_REQUIRES_DATE_RANGE',
        message: 'Multi-day OD must span at least two dates.',
      );
    }

    if (endDateTime.isBefore(startDateTime)) {
      return const RuleViolation(
        code: 'INVALID_DATE_RANGE',
        message: 'End date/time must be after start date/time.',
      );
    }

    return null;
  }
}
