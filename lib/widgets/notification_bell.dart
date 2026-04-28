import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/services/notification_service.dart';
import '../presentation/app/app_providers.dart';
import '../domain/enums/user_role.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const SizedBox.shrink();

    final notificationService = ref.read(notificationServiceProvider);
    final roles = <String>[user.role.value];
    if (user.role == UserRole.mentor && user.isEc) {
      roles.add('ec');
    }

    return StreamBuilder<List<NotificationItem>>(
      stream: notificationService.watchForRolesItems(roles),
      builder: (context, snap) {
        final items = snap.data ?? <NotificationItem>[];
        final unread = items.where((i) => !i.seen).length;
        return IconButton(
          tooltip: 'Notifications',
          onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications),
              if (unread > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      unread > 99 ? '99+' : unread.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
