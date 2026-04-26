import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/od_request.dart';
import '../../../domain/enums/od_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../../widgets/role_notifications_panel.dart';
import '../../app/app_providers.dart';

class ReviewerQueueScreen extends ConsumerWidget {
  const ReviewerQueueScreen({super.key, required this.roleScope});

  final String roleScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsStream =
        ref.watch(odRequestRepositoryProvider).watchPendingForRole(roleScope);
    final authUser = ref.watch(authStateProvider).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('${roleScope.toUpperCase()} Queue'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: StreamBuilder<List<OdRequest>>(
        stream: requestsStream,
        builder: (context, snapshot) {
          final sortedItems = (snapshot.data ?? const <OdRequest>[]).toList()
            ..sort((a, b) {
              if (a.isPinned == b.isPinned) return 0;
              return a.isPinned ? -1 : 1;
            });

          final canPin =
              roleScope == 'mentor' || roleScope == 'hod' || roleScope == 'principal';

          return Row(
            children: [
              Expanded(
                child: sortedItems.isEmpty
                    ? const Center(child: Text('No pending requests'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedItems.length,
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          final isExpired =
                              item.expired || item.status == OdStatus.expired;

                          return Card(
                            child: ListTile(
                              title: Text(item.eventName),
                              subtitle: Text(
                                '${item.startDateTime.toString().split(' ').first} • ${item.status.name}${isExpired ? ' • Expired' : ''}',
                              ),
                              trailing: Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  if (canPin)
                                    IconButton(
                                      tooltip: item.isPinned ? 'Unpin request' : 'Pin request',
                                      icon: Icon(
                                        item.isPinned
                                            ? Icons.push_pin
                                            : Icons.push_pin_outlined,
                                      ),
                                      onPressed: () => ref
                                          .read(requestLifecycleServiceProvider)
                                          .togglePin(item.id, item.isPinned),
                                    ),
                                  FilledButton(
                                    onPressed: isExpired
                                        ? null
                                        : () => _decide(
                                              context: context,
                                              ref: ref,
                                              authUserId: authUser?.id,
                                              role: roleScope,
                                              requestId: item.id,
                                              approved: true,
                                            ),
                                    child: const Text('Approve'),
                                  ),
                                  OutlinedButton(
                                    onPressed: isExpired
                                        ? null
                                        : () => _decide(
                                              context: context,
                                              ref: ref,
                                              authUserId: authUser?.id,
                                              role: roleScope,
                                              requestId: item.id,
                                              approved: false,
                                            ),
                                    child: const Text('Reject'),
                                  ),
                                  if (isExpired)
                                    const Text(
                                      'Action Closed',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: RoleNotificationsPanel(currentRole: roleScope),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _decide({
    required BuildContext context,
    required WidgetRef ref,
    required String? authUserId,
    required String role,
    required String requestId,
    required bool approved,
  }) async {
    if (authUserId == null) return;

    final userRole = switch (role) {
      'mentor' => UserRole.mentor,
      'hod' => UserRole.hod,
      'principal' => UserRole.principal,
      'admin' => UserRole.admin,
      _ => UserRole.mentor,
    };

    final result = await ref.read(odRequestServiceProvider).applyDecision(
          actorRole: userRole,
          requestId: requestId,
          isApproved: approved,
          reason: approved ? 'Approved' : 'Rejected by reviewer',
          actorId: authUserId,
        );
    if (!result.isValid) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.violations.first.message)),
        );
      }
      return;
    }

    await ref.read(auditLogServiceProvider).log(
          actorId: authUserId,
          actorRole: role,
          action: approved ? 'OD_APPROVED' : 'OD_REJECTED',
          entityType: 'od_request',
          entityId: requestId,
        );

    if (!approved) return;

    final notificationService = ref.read(notificationServiceProvider);
    if (role == 'mentor') {
      await notificationService.sendNotification(
        'hod',
        'OD approved by Mentor',
        requestId: requestId,
        stage: 'mentor_approved',
        dedupeKey: '${requestId}_mentor_approved_hod',
      );
      return;
    }

    if (role == 'hod') {
      await notificationService.sendNotification(
        'principal',
        'OD approved by HOD',
        requestId: requestId,
        stage: 'hod_approved',
        dedupeKey: '${requestId}_hod_approved_principal',
      );
      return;
    }

    if (role == 'principal') {
      await notificationService.sendNotification(
        'student',
        'Your OD is approved',
        requestId: requestId,
        stage: 'principal_approved',
        dedupeKey: '${requestId}_principal_approved_student',
      );
      await notificationService.sendNotification(
        'mentor',
        'OD approved by Principal',
        requestId: requestId,
        stage: 'principal_approved',
        dedupeKey: '${requestId}_principal_approved_mentor',
      );
      await notificationService.sendNotification(
        'hod',
        'OD approved by Principal',
        requestId: requestId,
        stage: 'principal_approved',
        dedupeKey: '${requestId}_principal_approved_hod',
      );
    }
  }
}
