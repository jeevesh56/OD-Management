import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/notification_service.dart';
import '../../../domain/enums/user_role.dart';
import '../../app/app_providers.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const Scaffold(body: Center(child: Text('Not signed in')));

    final notificationService = ref.read(notificationServiceProvider);
    final roles = <String>[user.role.value];
    if (user.role == UserRole.mentor && user.isEc) roles.add('ec');

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<NotificationItem>>(
        stream: notificationService.watchForRolesItems(roles),
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.message),
                subtitle: Text('${item.timestamp}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      tooltip: 'Mark as read',
                      onPressed: () => notificationService.markSeen(item.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      onPressed: () => notificationService.delete(item.id),
                    ),
                  ],
                ),
                tileColor: item.seen
                    ? null
                    : Colors.blue.withValues(alpha: 0.05),
                onTap: () async {
                  if (!item.seen) await notificationService.markSeen(item.id);
                  if (item.requestId != null) {
                    // navigate to request details if implemented
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
