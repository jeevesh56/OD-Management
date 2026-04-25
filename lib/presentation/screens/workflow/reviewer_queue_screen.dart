import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/od_request.dart';
import '../../../domain/enums/user_role.dart';
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
          final items = snapshot.data ?? const <OdRequest>[];
          if (items.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.eventName),
                  subtitle: Text(
                    '${item.startDateTime.toString().split(' ').first} • ${item.status.name}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        onPressed: () => _decide(
                          ref: ref,
                          authUserId: authUser?.id,
                          role: roleScope,
                          requestId: item.id,
                          approved: true,
                        ),
                        child: const Text('Approve'),
                      ),
                      OutlinedButton(
                        onPressed: () => _decide(
                          ref: ref,
                          authUserId: authUser?.id,
                          role: roleScope,
                          requestId: item.id,
                          approved: false,
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _decide({
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

    await ref.read(odRequestServiceProvider).applyDecision(
          actorRole: userRole,
          requestId: requestId,
          isApproved: approved,
          reason: approved ? 'Approved' : 'Rejected by reviewer',
          actorId: authUserId,
        );
    await ref.read(auditLogServiceProvider).log(
          actorId: authUserId,
          actorRole: role,
          action: approved ? 'OD_APPROVED' : 'OD_REJECTED',
          entityType: 'od_request',
          entityId: requestId,
        );
  }
}
