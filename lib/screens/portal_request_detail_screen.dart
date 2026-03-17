import 'package:flutter/material.dart';

import '../api_service.dart';
import '../widgets/portal_od_helpers.dart';
import '../widgets/portal_od_timeline.dart';
import '../widgets/portal_page_layout.dart';
import '../widgets/portal_progress_chip.dart';
import 'portal_qr_screen.dart';
import 'portal_status_timeline_screen.dart';

/// Full request view — same design system as dashboard cards.
class PortalRequestDetailScreen extends StatelessWidget {
  const PortalRequestDetailScreen({super.key, required this.request});

  final Map<dynamic, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final status = request['status']?.toString() ?? '';
    final badgeColor = portalOdStatusColor(status);
    final stages = odTimelineStagesFromRequest(request);

    final mentorDone = const {
      'MENTOR_APPROVED',
      'EC_CONFIRMED',
      'EC_REJECTED',
      'HOD_APPROVED',
      'HOD_REJECTED',
    }.contains(status);
    final mentorRejected = status == 'MENTOR_REJECTED';
    final ecDone = const {
      'EC_CONFIRMED',
      'HOD_APPROVED',
      'HOD_REJECTED',
    }.contains(status);
    final ecRejected = status == 'EC_REJECTED';
    final hodDone = status == 'HOD_APPROVED';
    final hodRejected = status == 'HOD_REJECTED';

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Request details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 24),
          SafeArea(
            top: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    20,
                    32,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: portalWhiteCardDecoration(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    request['event_name']?.toString() ?? '—',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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
                                    portalOdStatusLabel(status),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _detailRow(Icons.event_outlined, 'Dates',
                                portalOdDateLabel(
                                    request['start_date'], request['end_date'])),
                            _detailRow(Icons.access_time, 'Time',
                                '${request['start_time'] ?? '—'} – ${request['end_time'] ?? '—'}'),
                            _detailRow(Icons.place_outlined, 'Venue',
                                request['venue']?.toString() ?? '—'),
                            _detailRow(Icons.groups_outlined, 'Organizer',
                                request['organiser']?.toString() ?? '—'),
                            _detailRow(Icons.badge_outlined, 'Request ID',
                                request['id']?.toString() ?? '—'),
                            const Divider(height: 28),
                            if (request['mentor_comment'] != null ||
                                request['ec_comment'] != null ||
                                request['hod_comment'] != null) ...[
                              const Text(
                                'Staff remarks',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (request['mentor_comment'] != null)
                                Text(
                                  'Mentor: ${request['mentor_comment']}',
                                  style: const TextStyle(height: 1.4),
                                ),
                              if (request['ec_comment'] != null)
                                Text(
                                  'EC: ${request['ec_comment']}',
                                  style: const TextStyle(height: 1.4),
                                ),
                              if (request['hod_comment'] != null)
                                Text(
                                  'HoD: ${request['hod_comment']}',
                                  style: const TextStyle(height: 1.4),
                                ),
                              const Divider(height: 28),
                            ],
                            const Text(
                              'Reason',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              request['reason']?.toString() ?? '—',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),
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
                                  text: 'EC',
                                  state: ecRejected
                                      ? PortalChipState.rejected
                                      : ecDone
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
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: portalWhiteCardDecoration(radius: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.timeline,
                                    color: Colors.blue.shade700, size: 22),
                                const SizedBox(width: 8),
                                const Text(
                                  'Status timeline',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Track each stage of your OD approval.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 18),
                            PortalOdVerticalTimeline(
                              stages: stages,
                              compact: true,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PortalStatusTimelineScreen(
                                              request: request),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.open_in_full, size: 20),
                                label: const Text('Open full timeline'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: kBlue,
                                  side: const BorderSide(color: kBlue),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (status == 'HOD_APPROVED') ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PortalQrScreen(
                                    eventName: request['event_name']
                                            ?.toString() ??
                                        'OD',
                                    requestId:
                                        request['id']?.toString() ?? '',
                                  ),
                                ),
                              );
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: kBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.qr_code_2_rounded),
                            label: const Text(
                              'View OD pass (QR)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
