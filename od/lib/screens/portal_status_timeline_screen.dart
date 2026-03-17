import 'package:flutter/material.dart';

import '../widgets/portal_od_helpers.dart';
import '../widgets/portal_od_timeline.dart';
import '../widgets/portal_page_layout.dart';

/// Full-screen vertical status timeline for one OD request.
class PortalStatusTimelineScreen extends StatelessWidget {
  const PortalStatusTimelineScreen({super.key, required this.request});

  final Map<dynamic, dynamic> request;

  @override
  Widget build(BuildContext context) {
    final stages = odTimelineStagesFromRequest(request);
    final title = request['event_name']?.toString() ?? 'OD request';
    final status = request['status']?.toString() ?? '';
    final badgeColor = portalOdStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xfff5f8fc),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.92),
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Status timeline',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 20),
          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                MediaQuery.of(context).padding.top + kToolbarHeight + 12,
                22,
                40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: portalWhiteCardDecoration(radius: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                portalOdStatusLabel(status),
                                style: TextStyle(
                                  color: badgeColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              portalOdDateLabel(request['start_date'],
                                  request['end_date']),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Approval chain',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    decoration: portalWhiteCardDecoration(radius: 20),
                    child: PortalOdVerticalTimeline(stages: stages),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xfff3f6ff),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mentor → Event Coordinator → HoD. You’ll be notified as each stage completes.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
