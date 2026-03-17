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
  final created = portalOdShortDate(r['created_at']?.toString() ?? '—');

  OdStageState mentorState() {
    if (status == 'MENTOR_REJECTED') return OdStageState.rejected;
    if (const {
      'MENTOR_APPROVED',
      'EC_CONFIRMED',
      'EC_REJECTED',
      'HOD_APPROVED',
      'HOD_REJECTED',
    }.contains(status)) {
      return OdStageState.completed;
    }
    if (status == 'PENDING') return OdStageState.current;
    return OdStageState.pending;
  }

  OdStageState ecState() {
    if (status == 'MENTOR_REJECTED') return OdStageState.pending;
    if (status == 'EC_REJECTED') return OdStageState.rejected;
    if (const {'HOD_APPROVED', 'HOD_REJECTED'}.contains(status) ||
        status == 'EC_CONFIRMED') {
      return OdStageState.completed;
    }
    if (status == 'MENTOR_APPROVED') return OdStageState.current;
    return OdStageState.pending;
  }

  OdStageState hodState() {
    if (status == 'HOD_APPROVED') return OdStageState.completed;
    if (status == 'HOD_REJECTED') return OdStageState.rejected;
    if (const {'MENTOR_REJECTED', 'EC_REJECTED'}.contains(status)) {
      return OdStageState.pending;
    }
    if (status == 'EC_CONFIRMED') return OdStageState.current;
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

  String ecSub() {
    switch (ecState()) {
      case OdStageState.rejected:
        return 'Event coordinator rejected';
      case OdStageState.completed:
        return 'Event details confirmed';
      case OdStageState.current:
        return 'EC confirming event participation';
      default:
        return 'After mentor approval';
    }
  }

  String hodSub() {
    switch (hodState()) {
      case OdStageState.rejected:
        return 'HoD did not grant OD';
      case OdStageState.completed:
        return 'Final approval granted';
      case OdStageState.current:
        return 'Awaiting HoD sign-off';
      default:
        return 'After EC confirmation';
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
      key: 'ec',
      title: 'Event coordinator',
      subtitle: ecSub(),
      state: ecState(),
    ),
    OdTimelineStage(
      key: 'hod',
      title: 'HoD approval',
      subtitle: hodSub(),
      state: hodState(),
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
    final (Color dotBg, Color dotBorder, IconData icon, Color iconColor) =
        switch (stage.state) {
      OdStageState.completed => (
          Colors.green.shade50,
          Colors.green,
          Icons.check_rounded,
          Colors.green.shade700,
        ),
      OdStageState.current => (
          Colors.orange.shade50,
          Colors.orange,
          Icons.more_horiz_rounded,
          Colors.orange.shade800,
        ),
      OdStageState.rejected => (
          Colors.red.shade50,
          Colors.red,
          Icons.close_rounded,
          Colors.red.shade700,
        ),
      OdStageState.pending => (
          Colors.grey.shade100,
          Colors.grey.shade400,
          Icons.schedule_rounded,
          Colors.grey.shade600,
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
                            : Colors.grey.shade300,
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
                      color: Colors.grey.shade700,
                      fontSize: compact ? 13 : 14,
                      height: 1.35,
                    ),
                  ),
                  if (stage.dateLabel != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      stage.dateLabel!,
                      style: TextStyle(
                        color: Colors.blue.shade700,
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
