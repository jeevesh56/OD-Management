import 'package:flutter/material.dart';

import '../screens/portal_request_detail_screen.dart';
import 'portal_od_helpers.dart';
import 'portal_progress_chip.dart';

/// Single OD request card — tappable → [PortalRequestDetailScreen].
class PortalRequestCard extends StatelessWidget {
  const PortalRequestCard({super.key, required this.r});

  final Map<dynamic, dynamic> r;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = r['status']?.toString() ?? '';
    final badgeColor = portalOdStatusColor(status);
    final title = r['event_name']?.toString() ?? '—';
    final schedule = r['datetime'] != null
        ? portalOdDateTime(r['datetime'])
        : portalOdDateLabel(r['start_date'], r['end_date']);
    final venue = r['venue']?.toString() ?? '—';
    final reason = r['reason']?.toString() ?? '—';
    final organiser =
        r['organiser']?.toString() ?? r['organizer']?.toString() ?? '—';
    final submitted = r['created_at'] != null
        ? portalOdDateTime(r['created_at'])
        : (r['datetime'] != null ? portalOdDateTime(r['datetime']) : '—');

    final mentorDone =
        r['mentor_approved'] == true ||
        const {'MENTOR_APPROVED', 'HOD_APPROVED', 'Approved'}.contains(status);
    final mentorRejected = status == 'MENTOR_REJECTED';

    final hodDone = r['hod_approved'] == true || status == 'HOD_APPROVED';
    final hodRejected = status == 'HOD_REJECTED';
    final principalDone =
        r['principal_approved'] == true || status == 'Approved';
    final principalRejected = status == 'Rejected';

    final List<Widget> timeline = [];
    if (submitted != '—') {
      timeline.add(Text('✓ Submitted on ${portalOdShortDate(submitted)}'));
    }
    if (mentorRejected) {
      timeline.add(
        const Text(
          '✗ Rejected at mentor review',
          style: TextStyle(color: Colors.red),
        ),
      );
    } else if (mentorDone) {
      timeline.add(const Text('✓ Mentor approved'));
    }
    if (hodRejected) {
      timeline.add(
        const Text('✗ HoD rejected', style: TextStyle(color: Colors.red)),
      );
    } else if (hodDone) {
      timeline.add(const Text('✓ HoD approved'));
    }
    if (principalRejected) {
      timeline.add(
        const Text('✗ Principal rejected', style: TextStyle(color: Colors.red)),
      );
    } else if (principalDone) {
      timeline.add(const Text('✓ Principal approved'));
    }
    if (timeline.isEmpty) {
      timeline.add(const Text('Track your request below.'));
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PortalRequestDetailScreen(
                request: Map<String, dynamic>.from(r),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(blurRadius: 14, color: Color(0x1F000000)),
            ],
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      portalOdBadgeLabel(status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    schedule,
                    style: TextStyle(
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurface.withValues(alpha: 0.35),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Venue: $venue',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Reason: $reason',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text('Organizer: $organiser'),
              const SizedBox(height: 6),
              Text('Submitted: ${portalOdShortDate(submitted)}'),
              const SizedBox(height: 18),
              const Text(
                'Approval progress',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const PortalProgressChip(
                    text: 'Submitted',
                    state: PortalChipState.completed,
                  ),
                  PortalProgressChip(
                    text: 'Mentor',
                    state: mentorRejected
                        ? PortalChipState.rejected
                        : mentorDone
                        ? PortalChipState.completed
                        : PortalChipState.pending,
                  ),
                  PortalProgressChip(
                    text: 'HoD',
                    state: hodRejected
                        ? PortalChipState.rejected
                        : hodDone
                        ? PortalChipState.completed
                        : PortalChipState.pending,
                  ),
                  PortalProgressChip(
                    text: 'Principal',
                    state: principalRejected
                        ? PortalChipState.rejected
                        : principalDone
                        ? PortalChipState.completed
                        : PortalChipState.pending,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _spacedTexts(timeline),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _spacedTexts(List<Widget> lines) {
    final out = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) out.add(const SizedBox(height: 6));
      out.add(lines[i]);
    }
    return out;
  }
}
