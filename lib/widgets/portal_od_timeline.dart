import 'package:flutter/material.dart';

import 'portal_od_helpers.dart';

enum OdStageState { completed, current, pending, rejected }

class OdTimelineStage {
  const OdTimelineStage({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.state,
    this.dateLabel,
  });

  final String key;
  final String title;
  final String subtitle;
  final OdStageState state;
  final String? dateLabel;
}

List<OdTimelineStage> odTimelineStagesFromRequest(Map<dynamic, dynamic> r) {
  final status = r['status']?.toString() ?? '';
  final mentorApproved = r['mentor_approved'] == true;
  final hodApproved = r['hod_approved'] == true;
  final principalApproved = r['principal_approved'] == true;
  final created = portalOdShortDate(r['created_at']?.toString() ?? '—');

  OdStageState mentorState() {
    if (status == 'MENTOR_REJECTED') return OdStageState.rejected;
    if (mentorApproved || hodApproved || principalApproved) {
      return OdStageState.completed;
    }
    if (status == 'PENDING' || status == 'Pending') return OdStageState.current;
    return OdStageState.pending;
  }

  OdStageState hodState() {
    if (status == 'MENTOR_REJECTED') return OdStageState.pending;
    if (status == 'HOD_REJECTED') return OdStageState.rejected;
    if (hodApproved || principalApproved) {
      return OdStageState.completed;
    }
    if (mentorApproved) return OdStageState.current;
    return OdStageState.pending;
  }

  OdStageState principalState() {
    if (status == 'Rejected') return OdStageState.rejected;
    if (principalApproved || status == 'Approved') return OdStageState.completed;
    if (const {'MENTOR_REJECTED', 'HOD_REJECTED'}.contains(status)) {
      return OdStageState.pending;
    }
    if (hodApproved) return OdStageState.current;
    return OdStageState.pending;
  }

  String mentorSub() {
    switch (mentorState()) {
      case OdStageState.rejected:
        return 'Mentor did not approve this request';
      case OdStageState.completed:
        return 'Mentor has approved';
      case OdStageState.current:
        return 'Waiting for mentor review';
      default:
        return 'Not yet reached';
    }
  }

  String hodSub() {
    switch (hodState()) {
      case OdStageState.rejected:
        return 'HoD did not approve this request';
      case OdStageState.completed:
        return 'HoD has approved';
      case OdStageState.current:
        return 'Awaiting HoD review';
      default:
        return 'After mentor approval';
    }
  }

  String principalSub() {
    switch (principalState()) {
      case OdStageState.rejected:
        return 'Principal rejected the request';
      case OdStageState.completed:
        return 'Final approval granted';
      case OdStageState.current:
        return 'Awaiting principal sign-off';
      default:
        return 'After HoD approval';
    }
  }

  return [
    OdTimelineStage(
      key: 'submitted',
      title: 'Submitted',
      subtitle: 'Application received and queued',
      state: OdStageState.completed,
      dateLabel: created,
    ),
    OdTimelineStage(
      key: 'mentor',
      title: 'Mentor approval',
      subtitle: mentorSub(),
      state: mentorState(),
    ),
    OdTimelineStage(
      key: 'hod',
      title: 'HoD approval',
      subtitle: hodSub(),
      state: hodState(),
    ),
    OdTimelineStage(
      key: 'principal',
      title: 'Principal approval',
      subtitle: principalSub(),
      state: principalState(),
    ),
  ];
}

/// Vertical timeline (full page or embedded).
class PortalOdVerticalTimeline extends StatelessWidget {
  const PortalOdVerticalTimeline({
    super.key,
    required this.stages,
    this.compact = false,
  });

  final List<OdTimelineStage> stages;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stages.length, (i) {
        final s = stages[i];
        final isLast = i == stages.length - 1;
        return _TimelineRow(
          stage: s,
          showLineBelow: !isLast,
          compact: compact,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.stage,
    required this.showLineBelow,
    required this.compact,
  });

  final OdTimelineStage stage;
  final bool showLineBelow;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color dotBg, Color dotBorder, IconData icon, Color iconColor) =
        switch (stage.state) {
      OdStageState.completed => (
          scheme.secondaryContainer,
          Colors.green,
          Icons.check_rounded,
          Colors.green.shade700,
        ),
      OdStageState.current => (
          scheme.primaryContainer,
          Colors.orange,
          Icons.more_horiz_rounded,
          Colors.orange.shade800,
        ),
      OdStageState.rejected => (
          scheme.errorContainer,
          Colors.red,
          Icons.close_rounded,
          Colors.red.shade700,
        ),
      OdStageState.pending => (
          scheme.surfaceContainerHigh,
          scheme.outline,
          Icons.schedule_rounded,
          scheme.onSurface.withOpacity(0.65),
        ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: compact ? 36 : 44,
            child: Column(
              children: [
                Container(
                  width: compact ? 32 : 40,
                  height: compact ? 32 : 40,
                  decoration: BoxDecoration(
                    color: dotBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: dotBorder, width: 2),
                  ),
                  child: Icon(icon, size: compact ? 16 : 20, color: iconColor),
                ),
                if (showLineBelow)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        color: stage.state == OdStageState.completed
                            ? Colors.green.shade200
                            : scheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: compact ? 2 : 4,
                bottom: showLineBelow ? (compact ? 16 : 22) : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: compact ? 15 : 17,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stage.subtitle,
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.72),
                      fontSize: compact ? 13 : 14,
                      height: 1.35,
                    ),
                  ),
                  if (stage.dateLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      stage.dateLabel!,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
