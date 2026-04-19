import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';

const Color kEcPrimary = Color(0xFF0D5AA7);
const Color kEcAccent = Color(0xFF0E9F6E);
const Color kEcBg = Color(0xFFF4F7FB);
const Color kEcSidebar = Color(0xFF0A2850);

class ECHomeScreen extends StatefulWidget {
  const ECHomeScreen({super.key});

  @override
  State<ECHomeScreen> createState() => _ECHomeScreenState();
}

class _ECHomeScreenState extends State<ECHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _section = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _allRequests = [];

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

    final results = await Future.wait([ECApi.queue(), OdApi.myRequests()]);
    if (!mounted) {
      _busy = false;
      return;
    }
    final queueRes = results[0] as ApiResult<dynamic>;
    final requestsRes = results[1] as ApiResult<dynamic>;

    setState(() {
      _loading = false;
      if (queueRes.ok) {
        _queue = (queueRes.data is List ? queueRes.data : const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _error = queueRes.error;
      }

      if (requestsRes.ok) {
        _allRequests = (requestsRes.data is List ? requestsRes.data : const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
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

  Future<void> _confirm(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Confirm OD',
      label: 'Note / comment (optional)',
      allowEmpty: true,
    );

    await ECApi.action(
      requestId: row['id'].toString(),
      action: 'CONFIRMED',
      reason: reason?.isEmpty == true ? 'Confirmed by EC' : reason,
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

    await ECApi.action(
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
      backgroundColor: kEcBg,
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
          onConfirm: _confirm,
          onReject: _reject,
          onViewProof: _openProof,
        );
      case 2:
        return _EventsPanel(allRequests: _allRequests);
      case 3:
        return _SettingsPanel(onLogout: _logout);
      default:
        return _DashboardPanel(queue: _queue, allRequests: _allRequests);
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'EC';
    final dept = AuthStore.userDepartment ?? 'Department';

    return Container(
      color: kEcSidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.fact_check_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'EC Panel',
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
                  foregroundColor: kEcSidebar,
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
                          color: Color(0xFFC6DBF8),
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
              style: TextStyle(color: Color(0xFF95B8E5), fontSize: 12),
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
    final name = AuthStore.fullName ?? 'EC';

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
            backgroundColor: kEcPrimary.withOpacity(0.1),
            foregroundColor: kEcPrimary,
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
  const _DashboardPanel({required this.queue, required this.allRequests});

  final List<Map<String, dynamic>> queue;
  final List<Map<String, dynamic>> allRequests;

  @override
  Widget build(BuildContext context) {
    final confirmed = allRequests
        .where((e) => (e['status']?.toString() ?? '') == 'EC_CONFIRMED')
        .length;
    final rejected = allRequests
        .where((e) => (e['status']?.toString() ?? '') == 'EC_REJECTED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StatCard(
              label: 'Pending Confirmations',
              value: queue.length.toString(),
              icon: Icons.pending_actions_rounded,
              color: kEcPrimary,
            ),
            _StatCard(
              label: 'Confirmed',
              value: confirmed.toString(),
              icon: Icons.verified_rounded,
              color: kEcAccent,
            ),
            _StatCard(
              label: 'Rejected',
              value: rejected.toString(),
              icon: Icons.cancel_rounded,
              color: const Color(0xFFC62828),
            ),
            _StatCard(
              label: 'Total Event Requests',
              value: allRequests.length.toString(),
              icon: Icons.view_timeline_rounded,
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
            'Use Participants to validate requests, then move to Events for grouped visibility.',
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
    required this.onConfirm,
    required this.onReject,
    required this.onViewProof,
  });

  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onConfirm;
  final ValueChanged<Map<String, dynamic>> onReject;
  final ValueChanged<Map<String, dynamic>> onViewProof;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No mentor-approved requests yet',
        subtitle: 'Once mentor approvals are completed they appear here.',
      );
    }

    final desktop = MediaQuery.of(context).size.width >= 900;
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => _ParticipantCard(
                row: row,
                onConfirm: () => onConfirm(row),
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
                DataCell(_statusChip('Mentor OK')),
                DataCell(
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => onConfirm(row),
                        child: const Text('Confirm'),
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
        color: const Color(0xFFDEEFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Color(0xFF0A4D9C),
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
    required this.onConfirm,
    required this.onReject,
    required this.onViewProof,
  });

  final Map<String, dynamic> row;
  final VoidCallback onConfirm;
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
                onPressed: onConfirm,
                style: FilledButton.styleFrom(backgroundColor: kEcPrimary),
                child: const Text('Confirm'),
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
  const _EventsPanel({required this.allRequests});

  final List<Map<String, dynamic>> allRequests;

  @override
  Widget build(BuildContext context) {
    if (allRequests.isEmpty) {
      return const _EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No events found',
        subtitle: 'Event groups will show up here from OD request data.',
      );
    }

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final item in allRequests) {
      final event = (item['event_name']?.toString().trim().isNotEmpty ?? false)
          ? item['event_name'].toString().trim()
          : 'Untitled event';
      grouped.putIfAbsent(event, () => []).add(item);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: entries.map((entry) {
        final total = entry.value.length;
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
                  color: kEcPrimary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.event_available, color: kEcPrimary),
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
                      '$total participant request${total == 1 ? '' : 's'}',
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
    final name = AuthStore.fullName ?? 'Event Coordinator';
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
          _settingRow('Role', 'Event Coordinator'),
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
