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
    final scheme = Theme.of(context).colorScheme;
    final stages = odTimelineStagesFromRequest(request);
    final title = request['event_name']?.toString() ?? 'OD request';
    final status = request['status']?.toString() ?? '';
    final badgeColor = portalOdStatusColor(status);
    final schedule = request['datetime'] != null
        ? portalOdDateTime(request['datetime'])
        : portalOdDateLabel(request['start_date'], request['end_date']);

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLowest,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: scheme.surface.withValues(alpha: 0.92),
        elevation: 0,
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
                    decoration: portalCardDecoration(context, radius: 18),
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
                              schedule,
                              style: TextStyle(
                                color: scheme.onSurface.withValues(alpha: 0.72),
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
                      color: scheme.onSurface.withValues(alpha: 0.72),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                    decoration: portalCardDecoration(context, radius: 20),
                    child: PortalOdVerticalTimeline(stages: stages),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mentor → Event Coordinator → HoD. You’ll be notified as each stage completes.',
                            style: TextStyle(
                              color: scheme.onSurface,
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
