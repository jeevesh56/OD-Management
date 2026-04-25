import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';
import 'widgets/role_profile_widgets.dart';

const Color kHoDPrimary = Color(0xFF0F3D91);
const Color kHoDAccent = Color(0xFF0E9F6E);
const Color kHoDBg = Color(0xFFF4F7FB);
const Color kHoDSidebar = Color(0xFF0B1F44);

class HoDHomeScreen extends StatefulWidget {
  const HoDHomeScreen({super.key});

  @override
  State<HoDHomeScreen> createState() => _HoDHomeScreenState();
}

class _HoDHomeScreenState extends State<HoDHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _section = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _sessions = [];
  Map<String, dynamic> _analytics = const {};

  List<Map<String, dynamic>> _mapList(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    super.dispose();
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

    final results = await Future.wait([
      HoDApi.queue(),
      HoDApi.analytics(),
      HoDApi.activeSessions(),
    ]);
    if (!mounted) {
      _busy = false;
      return;
    }

    final queueRes = results[0] as ApiResult<dynamic>;
    final analyticsRes = results[1] as ApiResult<dynamic>;
    final sessionsRes = results[2] as ApiResult<dynamic>;

    setState(() {
      _loading = false;
      if (queueRes.ok) {
        _requests = _mapList(queueRes.data);
      } else {
        _error = queueRes.error;
      }

      if (analyticsRes.ok) {
        _analytics = Map<String, dynamic>.from(analyticsRes.data ?? const {});
      }

      if (sessionsRes.ok) {
        _sessions = _mapList(sessionsRes.data);
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

    await HoDApi.action(
      requestId: row['id'].toString(),
      action: 'APPROVED',
      reason: reason?.isEmpty == true ? 'Approved by HoD' : reason,
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

    await HoDApi.action(
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
    final width = MediaQuery.of(context).size.width;
    final desktop = width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
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
                              child: _contentBySection(context),
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
        return 'OD Requests';
      case 3:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _contentBySection(BuildContext context) {
    switch (_section) {
      case 1:
        return _ParticipantsTable(
          requests: _requests,
          onApprove: _approve,
          onReject: _reject,
          onViewProof: _openProof,
        );
      case 2:
        return _EventsPanel(sessions: _sessions, requests: _requests);
      case 3:
        return _ProfilePanel(onLogout: _logout);
      default:
        return _DashboardPanel(
          requests: _requests,
          sessions: _sessions,
          analytics: _analytics,
        );
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'HoD';
    final dept = AuthStore.userDepartment ?? 'Department';
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'H';
    final roleLabel = (AuthStore.role ?? 'hod').toLowerCase() == 'mentor'
        ? 'Mentor Panel'
        : (AuthStore.role ?? 'hod').toLowerCase() == 'principal'
            ? 'Principal Panel'
            : 'HOD Panel';

    return Container(
      color: kHoDSidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  foregroundColor: kHoDSidebar,
                  child: Text(initials),
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dept,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFBFD0F0),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
              label: 'OD Requests',
            active: current == 2,
            onTap: () => onTap(2),
          ),
          _SidebarItem(
            icon: Icons.person_rounded,
            label: 'Profile',
            active: current == 3,
            onTap: () => onTap(3),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'OD Management 2026',
              style: TextStyle(color: Color(0xFF95ADD9), fontSize: 12),
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
        color: active ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
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
    final name = AuthStore.fullName ?? 'HoD';

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
            IconButton(icon: const Icon(Icons.menu), onPressed: onMenuTap),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.brightness_6_outlined),
            tooltip: 'Toggle theme',
            onPressed: onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: onLogout,
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: kHoDPrimary.withValues(alpha: 0.1),
            foregroundColor: kHoDPrimary,
            child: Text(name.substring(0, 1).toUpperCase()),
          ),
          const SizedBox(width: 8),
          if (isDesktop)
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({
    required this.requests,
    required this.sessions,
    required this.analytics,
  });

  final List<Map<String, dynamic>> requests;
  final List<Map<String, dynamic>> sessions;
  final Map<String, dynamic> analytics;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'HoD';
    final dept = AuthStore.userDepartment ?? 'Department';
    final totalCount = requests.length;
    final approvedCount = requests
        .where((e) => (e['status']?.toString() ?? '').toLowerCase() == 'approved')
        .length;
    final rejectedCount = requests
        .where((e) => (e['status']?.toString() ?? '').toLowerCase() == 'rejected')
        .length;
    final pendingCount = requests
        .where((e) => (e['status']?.toString() ?? '').toLowerCase() == 'pending')
        .length;
    final total = totalCount.toString();
    final approved = approvedCount.toString();
    final pending = pendingCount.toString();
    final rejected = rejectedCount.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleProfileCard(
          name: name,
          role: 'Head of Department',
          subtitle: dept,
        ),
        DashboardStatGrid(
          items: [
            DashboardStatItem(
              title: 'Total Requests',
              value: total,
              accentColor: Colors.blue,
            ),
            DashboardStatItem(
              title: 'Approved',
              value: approved,
              accentColor: Colors.green,
            ),
            DashboardStatItem(
              title: 'Pending',
              value: pending,
              accentColor: Colors.orange,
            ),
            DashboardStatItem(
              title: 'Rejected',
              value: rejected,
              accentColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }
}

class _ParticipantsTable extends StatelessWidget {
  const _ParticipantsTable({
    required this.requests,
    required this.onApprove,
    required this.onReject,
    required this.onViewProof,
  });

  final List<Map<String, dynamic>> requests;
  final ValueChanged<Map<String, dynamic>> onApprove;
  final ValueChanged<Map<String, dynamic>> onReject;
  final ValueChanged<Map<String, dynamic>> onViewProof;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No participant requests right now',
        subtitle: 'New requests will appear here automatically.',
      );
    }

    final desktop = MediaQuery.of(context).size.width >= 900;
    if (!desktop) {
      return Column(
        children: requests
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
          rows: requests.map((row) {
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
                  Text(row['datetime']?.toString() ?? '---'),
                ),
                DataCell(Text(row['venue']?.toString() ?? '---')),
                DataCell(_statusChip(row['status']?.toString() ?? 'Pending')),
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
          Text(row['datetime']?.toString() ?? '---'),
          Text(row['venue']?.toString() ?? '---'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(onPressed: onApprove, child: const Text('Approve')),
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
  const _EventsPanel({required this.sessions, required this.requests});

  final List<Map<String, dynamic>> sessions;
  final List<Map<String, dynamic>> requests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF5)),
          ),
          child: Text(
            'Active sessions: ${sessions.length} | Pending event requests: ${requests.length}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 14),
        if (sessions.isEmpty)
          const _EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'No active OD requests',
            subtitle:
                'Once approved students are in-session, they will show up here.',
          )
        else
          ...sessions.map((s) {
            final event = s['event_name']?.toString() ?? 'Event';
            final student = s['student_unique_id']?.toString() ?? '---';
            final approvedBy = s['approved_by_name']?.toString() ?? '---';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                      color: kHoDAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.event_available, color: kHoDAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Student ID: $student',
                          style: const TextStyle(color: Color(0xFF66768F)),
                        ),
                        Text(
                          'Approved by: $approvedBy',
                          style: const TextStyle(color: Color(0xFF66768F)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'HoD';
    final dept = AuthStore.userDepartment ?? 'Department';

    return RoleProfilePage(
      name: name,
      role: 'HOD',
      department: dept,
      onLogout: onLogout,
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
              if (!allowEmpty && controller.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
