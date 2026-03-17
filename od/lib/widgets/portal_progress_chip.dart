import 'package:flutter/material.dart';

enum PortalChipState { completed, pending, rejected }

class PortalProgressChip extends StatelessWidget {
  const PortalProgressChip({
    super.key,
    required this.text,
    this.state = PortalChipState.pending,
  });

  final String text;
  final PortalChipState state;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final IconData icon;
    switch (state) {
      case PortalChipState.completed:
        bg = Colors.green.shade100;
        fg = Colors.green;
        icon = Icons.check_circle;
        break;
      case PortalChipState.rejected:
        bg = Colors.red.shade50;
        fg = Colors.red;
        icon = Icons.cancel;
        break;
      case PortalChipState.pending:
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        icon = Icons.schedule;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontSize: 11, color: fg),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
