import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../presentation/app/app_providers.dart';

class RoleNotificationsPanel extends ConsumerStatefulWidget {
  const RoleNotificationsPanel({
    super.key,
    required this.currentRole,
    this.showPopups = true,
  });

  final String currentRole;
  final bool showPopups;

  @override
  ConsumerState<RoleNotificationsPanel> createState() =>
      _RoleNotificationsPanelState();
}

class _RoleNotificationsPanelState extends ConsumerState<RoleNotificationsPanel> {
  final Set<String> _popupShownIds = <String>{};

  @override
  Widget build(BuildContext context) {
    final stream =
        ref.watch(notificationServiceProvider).watchByRole(widget.currentRole);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No notifications yet'));
        }

        _maybeShowPopups(context, docs);

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final message = data['message']?.toString() ?? 'No message';
            final seen = data['seen'] == true;
            final when = _formatTimestamp(data['timestamp']);

            return ListTile(
              leading: Icon(
                seen ? Icons.notifications_none : Icons.notifications_active,
              ),
              title: Text(message),
              subtitle: when == null ? null : Text(when),
              trailing: seen
                  ? null
                  : TextButton(
                      onPressed: () => ref
                          .read(notificationServiceProvider)
                          .markSeen(docs[index].id),
                      child: const Text('Mark seen'),
                    ),
            );
          },
        );
      },
    );
  }

  void _maybeShowPopups(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (!widget.showPopups) return;

    for (final doc in docs) {
      final data = doc.data();
      final seen = data['seen'] == true;
      if (seen || _popupShownIds.contains(doc.id)) {
        continue;
      }

      _popupShownIds.add(doc.id);
      final message = data['message']?.toString() ?? 'New notification';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
        );
      });
    }
  }

  String? _formatTimestamp(dynamic value) {
    if (value is! Timestamp) return null;
    final dt = value.toDate();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$month-$day $hour:$minute';
  }
}
