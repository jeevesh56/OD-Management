enum OdStatus {
  pending,
  mentorApproved,
  mentorRejected,
  hodApproved,
  hodRejected,
  principalApproved,
  principalRejected,
  expired,
  cancelled,
}

extension OdStatusX on OdStatus {
  String get value => switch (this) {
    OdStatus.pending => 'PENDING',
    OdStatus.mentorApproved => 'MENTOR_APPROVED',
    OdStatus.mentorRejected => 'MENTOR_REJECTED',
    OdStatus.hodApproved => 'HOD_APPROVED',
    OdStatus.hodRejected => 'HOD_REJECTED',
    OdStatus.principalApproved => 'PRINCIPAL_APPROVED',
    OdStatus.principalRejected => 'PRINCIPAL_REJECTED',
    OdStatus.expired => 'EXPIRED',
    OdStatus.cancelled => 'CANCELLED',
  };

  static OdStatus fromValue(String raw) {
    if (raw.toUpperCase() == 'ACCEPTED') return OdStatus.principalApproved;
    if (raw.toUpperCase() == 'REJECTED') return OdStatus.principalRejected;
    return OdStatus.values.firstWhere(
      (status) => status.value == raw,
      orElse: () => OdStatus.pending,
    );
  }
}
