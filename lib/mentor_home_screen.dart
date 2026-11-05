import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';
import 'widgets/portal_od_helpers.dart';
import 'widgets/proof_action_buttons.dart';
import 'widgets/role_profile_widgets.dart';

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
  StreamSubscription<RoleRequestSnapshot>? _requestsSubscription;

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
    _requestsSubscription = MentorApi.watchData().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _queue = snapshot.queue;
        _history = snapshot.history;
      });
    }, onError: (Object error, StackTrace stackTrace) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Unable to load Mentor data: $error';
      });
    });
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadAll({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    if (!mounted) {
      _busy = false;
      return;
    }
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final results = await Future.wait([MentorApi.queue(), MentorApi.history()]);
    if (!mounted) {
      _busy = false;
      return;
    }

    final queueRes = results[0] as ApiResult<dynamic>;
    final historyRes = results[1] as ApiResult<dynamic>;

    setState(() {
      if (!silent) _loading = false;
      if (queueRes.ok) {
        _queue = _mapList(queueRes.data);
      } else {
        _error = queueRes.error;
      }
      if (historyRes.ok) {
        _history = _mapList(historyRes.data);
      }
    });
    _busy = false;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    AuthStore.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const ODLoginUI()),
      (_) => false,
    );
  }

  Future<void> _approve(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Approve OD',
      label: 'Note / comment (optional)',
      allowEmpty: true,
    );

    final result = await MentorApi.action(
      requestId: row['id'].toString(),
      action: 'APPROVED',
      reason: reason?.isEmpty == true ? 'Approved by mentor' : reason,
    );
    if (mounted && !result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Approval failed')),
      );
    }
    await _loadAll();
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Reject OD',
      label: 'Reason for rejection',
    );
    if (reason == null) return;

    final result = await MentorApi.action(
      requestId: row['id'].toString(),
      action: 'REJECTED',
      reason: reason,
    );
    if (mounted && !result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Rejection failed')),
      );
    }
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      drawer: desktop
          ? null
          : Drawer(
              child: _Sidebar(
                current: _section,
                onTap: _onTapSection,
                onLogout: _logout,
              ),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 260,
                child: _Sidebar(
                  current: _section,
                  onTap: _onTapSection,
                  onLogout: _logout,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _Topbar(
                    title: _titleForSection(_section),
                    isDesktop: desktop,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onToggleTheme: ThemeController.toggle,
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
        return 'OD Requests';
      case 2:
        return 'History';
      case 3:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _contentBySection() {
    switch (_section) {
      case 1:
        return _ODRequestsPanel(
          rows: _queue,
          onApprove: _approve,
          onReject: _reject,
        );
      case 2:
        return _HistoryPanel(rows: _history);
      case 3:
        return _ProfilePanel(onLogout: _logout);
      default:
        return _DashboardPanel(queue: _queue, history: _history);
    }
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.current,
    required this.onTap,
    required this.onLogout,
  });

  final int current;
  final ValueChanged<int> onTap;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = 'Mentor';
    final dept = 'Department';
    final roleLabel = 'Mentor Panel';

    return Container(
      color: kMentorSidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.auto_graph_rounded, color: Colors.white),
                SizedBox(width: 10),
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
          const SizedBox(height: 18),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
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
            icon: Icons.event_note_rounded,
            label: 'OD Requests',
            active: current == 1,
            onTap: () => onTap(1),
          ),
          _SidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onLogout,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
        color: active
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.transparent,
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
  });

  final String title;
  final bool isDesktop;
  final VoidCallback onMenuTap;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final name = 'Mentor';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
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
          CircleAvatar(
            backgroundColor: kMentorPrimary.withValues(alpha: 0.1),
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
    final name = 'Mentor';
    final dept = 'Department';
    final scheme = Theme.of(context).colorScheme;
    final pending = queue.length;
    final approved = history
        .where(
          (e) =>
              portalWorkflowHasRoleDecision(e, role: 'mentor', approved: true),
        )
        .length;
    final rejected = history
        .where(
          (e) =>
              portalWorkflowHasRoleDecision(e, role: 'mentor', approved: false),
        )
        .length;
    final total = pending + approved + rejected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleProfileCard(name: name, role: 'Mentor', subtitle: dept),
        DashboardStatGrid(
          items: [
            DashboardStatItem(
              title: 'Total Requests',
              value: total.toString(),
              accentColor: Colors.blue,
            ),
            DashboardStatItem(
              title: 'Accepted',
              value: approved.toString(),
              accentColor: Colors.green,
            ),
            DashboardStatItem(
              title: 'Pending',
              value: pending.toString(),
              accentColor: Colors.orange,
            ),
            DashboardStatItem(
              title: 'Rejected',
              value: rejected.toString(),
              accentColor: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Text(
            'Open OD Requests for full request details, proof verification, and approval actions.',
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ODRequestsPanel extends StatelessWidget {
  const _ODRequestsPanel({
    required this.rows,
    required this.onApprove,
    required this.onReject,
  });

  final List<Map<String, dynamic>> rows;
  final ValueChanged<Map<String, dynamic>> onApprove;
  final ValueChanged<Map<String, dynamic>> onReject;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No pending requests',
        subtitle: 'All caught up for now.',
      );
    }

    return Column(
      children: rows
          .map<Widget>(
            (row) => _ODRequestCard(
              row: row,
              onApprove: () => onApprove(row),
              onReject: () => onReject(row),
            ),
          )
          .toList(),
    );
  }
}

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final historyRows = rows;

    if (historyRows.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'No history yet',
        subtitle: 'Processed requests will appear here.',
      );
    }

    return Column(
      children: historyRows.map<Widget>((row) {
        final status = portalRoleDecisionDisplay(row, 'mentor');
        final isApproved = status.startsWith('Approved');
        final color = isApproved
            ? Colors.green
            : status.startsWith('Rejected')
            ? Colors.red
            : Colors.orange;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(
                isApproved
                    ? Icons.check_circle
                    : status.startsWith('Rejected')
                    ? Icons.cancel
                    : Icons.schedule,
                color: color,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row['event_name']?.toString() ?? 'Untitled event',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      portalOdDateTime(row['datetime']),
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    PortalHistoryRequestDetails(request: row),
                    ProofActionButtons(
                      fileUrl: row['file_url']?.toString() ?? '',
                    ),
                    Text(
                      '${status.startsWith('Approved')
                          ? 'Approved'
                          : status.startsWith('Rejected')
                          ? 'Rejected'
                          : 'Pending'} by ${portalRoleDecisionActor(row, 'mentor')}',
                      style: TextStyle(color: color),
                    ),
                  ],
                ),
              ),
              Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ODRequestCard extends StatelessWidget {
  const _ODRequestCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final eventName = row['event_name']?.toString() ?? 'Untitled event';
    final datetime = portalOdDateTime(row['datetime']);
    final venue = row['venue']?.toString() ?? '---';
    final organizer =
        row['organizer']?.toString() ?? row['organiser']?.toString() ?? '---';
    final reason = row['reason']?.toString() ?? '---';
    final fileUrl = row['file_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Date & Time: $datetime'),
          Text('Venue: $venue'),
          Text('Organizer: $organizer'),
          const SizedBox(height: 10),
          Text('Reason: $reason'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
              color: scheme.surfaceContainerHigh,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proof',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ProofActionButtons(fileUrl: fileUrl),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final name = 'Mentor';
    final dept = 'Department';

    return RoleProfilePage(
      name: name,
      role: 'Mentor',
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
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
