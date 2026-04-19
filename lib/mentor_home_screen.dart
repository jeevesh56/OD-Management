import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';

const Color kMentorPrimary = Color(0xFF1257B0);
const Color kMentorAccent = Color(0xFF0E9F6E);
const Color kMentorBg = Color(0xFFF4F7FB);
const Color kMentorSidebar = Color(0xFF102A5C);

class MentorHomeScreen extends StatefulWidget {
  const MentorHomeScreen({super.key});

  @override
  State<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends State<MentorHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _section = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (_busy) return;
    _busy = true;
    if (!mounted) {
      _busy = false;
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final results = await Future.wait([MentorApi.queue(), MentorApi.history()]);
    if (!mounted) {
      _busy = false;
      return;
    }
    final queueRes = results[0] as ApiResult<dynamic>;
    final historyRes = results[1] as ApiResult<dynamic>;

    setState(() {
      _loading = false;
      if (queueRes.ok) {
        _queue = (queueRes.data is List ? queueRes.data : const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _error = queueRes.error;
      }

      if (historyRes.ok) {
        _history = (historyRes.data is List ? historyRes.data : const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    });
    _busy = false;
  }

  Future<void> _logout() async {
    AuthStore.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ODLoginUI()),
    );
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Approve OD',
      label: 'Note / comment (optional)',
      allowEmpty: true,
    );

    await MentorApi.action(
      requestId: row['id'].toString(),
      action: 'APPROVED',
      reason: reason?.isEmpty == true ? 'Approved by mentor' : reason,
    );
    await _loadAll();
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Reject OD',
      label: 'Reason for rejection',
    );
    if (reason == null) return;

    await MentorApi.action(
      requestId: row['id'].toString(),
      action: 'REJECTED',
      reason: reason,
    );
    await _loadAll();
  }

  Future<void> _openProof(Map<String, dynamic> row) async {
    final b64 = row['attachment_base64']?.toString();
    final mime = row['attachment_mime']?.toString();

    if (b64 == null || mime == null || b64.isEmpty || mime.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image proof uploaded')));
      return;
    }
    if (!mime.startsWith('image/')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only image proof preview is supported')),
      );
      return;
    }

    final bytes = base64Decode(b64);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kMentorBg,
      drawer: desktop
          ? null
          : Drawer(
              child: _Sidebar(current: _section, onTap: _onTapSection),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 260,
                child: _Sidebar(current: _section, onTap: _onTapSection),
              ),
            Expanded(
              child: Column(
                children: [
                  _Topbar(
                    title: _titleForSection(_section),
                    isDesktop: desktop,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onToggleTheme: ThemeController.toggle,
                    onLogout: _logout,
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _ErrorPanel(error: _error!, onRetry: _loadAll)
                        : RefreshIndicator(
                            onRefresh: _loadAll,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                20,
                                20,
                                28,
                              ),
                              child: _contentBySection(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTapSection(int index) {
    setState(() => _section = index);
    Navigator.of(context).maybePop();
  }

  String _titleForSection(int section) {
    switch (section) {
      case 1:
        return 'Participants';
      case 2:
        return 'Events';
      case 3:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  Widget _contentBySection() {
    switch (_section) {
      case 1:
        return _ParticipantsPanel(
          rows: _queue,
          onApprove: _approve,
          onReject: _reject,
          onViewProof: _openProof,
        );
      case 2:
        return _EventsPanel(history: _history);
      case 3:
        return _SettingsPanel(onLogout: _logout);
      default:
        return _DashboardPanel(queue: _queue, history: _history);
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Mentor';
    final dept = AuthStore.userDepartment ?? 'Department';

    return Container(
      color: kMentorSidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Mentor Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: kMentorSidebar,
                  child: Text(name.substring(0, 1).toUpperCase()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        dept,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFC3D6FA),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            active: current == 0,
            onTap: () => onTap(0),
          ),
          _SidebarItem(
            icon: Icons.people_alt_rounded,
            label: 'Participants',
            active: current == 1,
            onTap: () => onTap(1),
          ),
          _SidebarItem(
            icon: Icons.event_note_rounded,
            label: 'Events',
            active: current == 2,
            onTap: () => onTap(2),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            active: current == 3,
            onTap: () => onTap(3),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'OD Management 2026',
              style: TextStyle(color: Color(0xFF95B4E7), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Material(
        color: active ? Colors.white.withOpacity(0.16) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({
    required this.title,
    required this.isDesktop,
    required this.onMenuTap,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final String title;
  final bool isDesktop;
  final VoidCallback onMenuTap;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Mentor';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE3E8F2))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(onPressed: onMenuTap, icon: const Icon(Icons.menu)),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleTheme,
            icon: const Icon(Icons.brightness_6_outlined),
          ),
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
          CircleAvatar(
            backgroundColor: kMentorPrimary.withOpacity(0.1),
            foregroundColor: kMentorPrimary,
            child: Text(name.substring(0, 1).toUpperCase()),
          ),
          if (isDesktop) ...[
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.queue, required this.history});

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final approved = history
        .where((e) => (e['status']?.toString() ?? '') == 'MENTOR_APPROVED')
        .length;
    final rejected = history
        .where((e) => (e['status']?.toString() ?? '') == 'MENTOR_REJECTED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StatCard(
              label: 'Pending Reviews',
              value: queue.length.toString(),
              icon: Icons.pending_actions_rounded,
              color: kMentorPrimary,
            ),
            _StatCard(
              label: 'Approved',
              value: approved.toString(),
              icon: Icons.check_circle_rounded,
              color: kMentorAccent,
            ),
            _StatCard(
              label: 'Rejected',
              value: rejected.toString(),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFC62828),
            ),
            _StatCard(
              label: 'Total Reviewed',
              value: history.length.toString(),
              icon: Icons.task_alt_rounded,
              color: const Color(0xFF6A1B9A),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF5)),
          ),
          child: const Text(
            'Review participant requests from the Participants tab and keep event flow moving.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECF5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF60708A))),
          ],
        ),
      ),
    );
  }
}

class _ParticipantsPanel extends StatelessWidget {
  const _ParticipantsPanel({
    required this.rows,
    required this.onApprove,
    required this.onReject,
    required this.onViewProof,
  });

  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onApprove;
  final ValueChanged<Map<String, dynamic>> onReject;
  final ValueChanged<Map<String, dynamic>> onViewProof;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No pending requests',
        subtitle: 'All caught up for now.',
      );
    }

    final desktop = MediaQuery.of(context).size.width >= 900;
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => _ParticipantCard(
                row: row,
                onApprove: () => onApprove(row),
                onReject: () => onReject(row),
                onViewProof: () => onViewProof(row),
              ),
            )
            .toList(),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Participant')),
            DataColumn(label: Text('Event')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Venue')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions')),
          ],
          rows: rows.map((row) {
            final hasProof =
                (row['attachment_base64']?.toString().isNotEmpty ?? false) &&
                (row['attachment_mime']?.toString().isNotEmpty ?? false);
            return DataRow(
              cells: [
                DataCell(Text(row['student_name']?.toString() ?? 'Student')),
                DataCell(
                  Text(row['event_name']?.toString() ?? 'Untitled event'),
                ),
                DataCell(
                  Text(
                    '${row['start_date'] ?? '---'} - ${row['end_date'] ?? '---'}',
                  ),
                ),
                DataCell(Text(row['venue']?.toString() ?? '---')),
                DataCell(_statusChip('Pending')),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => onApprove(row),
                        child: const Text('Approve'),
                      ),
                      TextButton(
                        onPressed: () => onReject(row),
                        child: const Text('Reject'),
                      ),
                      if (hasProof)
                        TextButton(
                          onPressed: () => onViewProof(row),
                          child: const Text('View Proof'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _statusChip(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3DB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF9C6B00),
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
    required this.onViewProof,
  });

  final Map<String, dynamic> row;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onViewProof;

  @override
  Widget build(BuildContext context) {
    final hasProof =
        (row['attachment_base64']?.toString().isNotEmpty ?? false) &&
        (row['attachment_mime']?.toString().isNotEmpty ?? false);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row['student_name']?.toString() ?? 'Student',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(row['event_name']?.toString() ?? 'Untitled event'),
          const SizedBox(height: 8),
          Text('${row['start_date'] ?? '---'} - ${row['end_date'] ?? '---'}'),
          Text(row['venue']?.toString() ?? '---'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: onApprove,
                style: FilledButton.styleFrom(backgroundColor: kMentorPrimary),
                child: const Text('Approve'),
              ),
              OutlinedButton(onPressed: onReject, child: const Text('Reject')),
              if (hasProof)
                TextButton(
                  onPressed: onViewProof,
                  child: const Text('View Proof'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventsPanel extends StatelessWidget {
  const _EventsPanel({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No reviewed events yet',
        subtitle: 'Approved and rejected event records will appear here.',
      );
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in history) {
      final key = (item['event_name']?.toString().trim().isNotEmpty ?? false)
          ? item['event_name'].toString().trim()
          : 'Untitled event';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((entry) {
        final approved = entry.value
            .where((e) => (e['status']?.toString() ?? '') == 'MENTOR_APPROVED')
            .length;
        final rejected = entry.value
            .where((e) => (e['status']?.toString() ?? '') == 'MENTOR_REJECTED')
            .length;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6ECF5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: kMentorPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available, color: kMentorPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Approved: $approved  |  Rejected: $rejected',
                      style: const TextStyle(color: Color(0xFF66768F)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Mentor';
    final dept = AuthStore.userDepartment ?? 'Department';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _settingRow('Name', name),
          _settingRow('Role', 'Mentor'),
          _settingRow('Department', dept),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _settingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF66768F)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 58, color: const Color(0xFF9AAAC4)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF66768F)),
          ),
        ],
      ),
    );
  }
}

Future<String?> _askReason(
  BuildContext context, {
  required String title,
  required String label,
  bool allowEmpty = false,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (!allowEmpty && controller.text.trim().isEmpty) return;
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
