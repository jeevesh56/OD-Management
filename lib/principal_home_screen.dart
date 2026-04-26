import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';
import 'widgets/portal_od_helpers.dart';
import 'widgets/proof_action_buttons.dart';
import 'widgets/role_profile_widgets.dart';

const Color kPrincipalPrimary = Color(0xFF1257B0);
const Color kPrincipalAccent = Color(0xFF0E9F6E);
const Color kPrincipalBg = Color(0xFFF4F7FB);
const Color kPrincipalSidebar = Color(0xFF102A5C);

class PrincipalHomeScreen extends StatefulWidget {
  const PrincipalHomeScreen({super.key});

  @override
  State<PrincipalHomeScreen> createState() => _PrincipalHomeScreenState();
}

class _PrincipalHomeScreenState extends State<PrincipalHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _section = 1; // default to OD Requests
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _queue = [];
  List<Map<String, dynamic>> _allRequests = [];
  final Set<String> _selectedIds = <String>{};
  Timer? _timer;

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
    _loadQueue();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_busy) {
        _loadQueue(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue({bool silent = false}) async {
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

    final results = await Future.wait([
      PrincipalApi.queue(),
      PrincipalApi.history(),
    ]);
    if (!mounted) {
      _busy = false;
      return;
    }

    setState(() {
      if (!silent) _loading = false;
      final queueRes = results[0] as ApiResult<dynamic>;
      final historyRes = results[1] as ApiResult<dynamic>;
      if (queueRes.ok) {
        _queue = _mapList(queueRes.data);
        final visibleIds = _queue
            .map((item) => item['id']?.toString() ?? '')
            .toSet();
        _selectedIds.removeWhere((id) => !visibleIds.contains(id));
      } else {
        _error = queueRes.error ?? 'Failed to load principal requests';
      }
      if (historyRes.ok) {
        _allRequests = _mapList(historyRes.data);
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
    await PrincipalApi.action(
      requestId: row['id'].toString(),
      action: 'APPROVED',
      reason: 'Approved by Principal',
    );
    await _loadQueue();
  }

  Future<void> _reject(Map<String, dynamic> row) async {
    final reason = await _askReason(
      context,
      title: 'Reject OD',
      label: 'Reason for rejection',
    );
    if (reason == null) return;

    await PrincipalApi.action(
      requestId: row['id'].toString(),
      action: 'REJECTED',
      reason: reason,
    );
    await _loadQueue();
  }

  Future<void> _bulkApproveSelected() async {
    if (_selectedIds.isEmpty) return;
    await PrincipalApi.bulkApprove(_selectedIds.toList());
    if (!mounted) return;
    setState(_selectedIds.clear);
    await _loadQueue();
  }

  Future<void> _bulkApproveGroup(List<Map<String, dynamic>> items) async {
    final ids = items
        .map((e) => e['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;
    await PrincipalApi.bulkApprove(ids);
    if (!mounted) return;
    setState(() {
      _selectedIds.removeAll(ids);
    });
    await _loadQueue();
  }

  void _toggleSelected(String requestId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(requestId);
      } else {
        _selectedIds.remove(requestId);
      }
    });
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
                  ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? _ErrorPanel(error: _error!, onRetry: _loadQueue)
                        : RefreshIndicator(
                            onRefresh: _loadQueue,
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
      case 2:
        return 'History';
      case 3:
        return 'Profile';
      case 0:
        return 'Dashboard';
      default:
        return 'OD Requests';
    }
  }

  Widget _contentBySection() {
    switch (_section) {
      case 0:
        return _DashboardPanel(queue: _allRequests);
      case 2:
        return _HistoryPanel(rows: _allRequests);
      case 3:
        return _ProfilePanel(onLogout: _logout);
      default:
        return _ODRequestsPanel(
          rows: _queue,
          selectedIds: _selectedIds,
          onToggleSelected: _toggleSelected,
          onApprove: _approve,
          onReject: _reject,
          onBulkApprove: _bulkApproveSelected,
          onBulkApproveGroup: _bulkApproveGroup,
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
    final name = AuthStore.fullName ?? 'Principal';
    final dept = AuthStore.userDepartment ?? 'Department';
    final roleLabel = (AuthStore.role ?? 'principal').toLowerCase() == 'mentor'
        ? 'Mentor Panel'
        : (AuthStore.role ?? 'principal').toLowerCase() == 'hod'
        ? 'HOD Panel'
        : 'Principal Panel';

    return Container(
      color: kPrincipalSidebar,
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
                  foregroundColor: kPrincipalSidebar,
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
    final name = AuthStore.fullName ?? 'Principal';

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
          CircleAvatar(
            backgroundColor: kPrincipalPrimary.withValues(alpha: 0.1),
            foregroundColor: kPrincipalPrimary,
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
  const _DashboardPanel({required this.queue});

  final List<Map<String, dynamic>> queue;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Principal';
    final dept = AuthStore.userDepartment ?? 'Department';
    final total = queue.length;
    final approved = queue
        .where(
          (e) => (e['status']?.toString() ?? '').toLowerCase() == 'approved',
        )
        .length;
    final rejected = queue
        .where(
          (e) => (e['status']?.toString() ?? '').toLowerCase() == 'rejected',
        )
        .length;
    final pending = queue
        .where(
          (e) => (e['status']?.toString() ?? '').toLowerCase() == 'pending',
        )
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoleProfileCard(name: name, role: 'Principal', subtitle: dept),
        DashboardStatGrid(
          items: [
            DashboardStatItem(
              title: 'Total Requests',
              value: total.toString(),
              accentColor: Colors.blue,
            ),
            DashboardStatItem(
              title: 'Approved',
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE6ECF5)),
          ),
          child: const Text(
            'Open OD Requests for full request details, proof verification, and approval actions.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ODRequestsPanel extends StatelessWidget {
  const _ODRequestsPanel({
    required this.rows,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onApprove,
    required this.onReject,
    required this.onBulkApprove,
    required this.onBulkApproveGroup,
  });

  final List<Map<String, dynamic>> rows;
  final Set<String> selectedIds;
  final void Function(String requestId, bool selected) onToggleSelected;
  final ValueChanged<Map<String, dynamic>> onApprove;
  final ValueChanged<Map<String, dynamic>> onReject;
  final VoidCallback onBulkApprove;
  final ValueChanged<List<Map<String, dynamic>>> onBulkApproveGroup;

  Map<String, List<Map<String, dynamic>>> _groupByEvent(
    List<Map<String, dynamic>> data,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final item in data) {
      final event = item['event_name']?.toString().trim();
      final key = (event == null || event.isEmpty) ? 'Unknown' : event;
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(item);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final sortedMap = <String, List<Map<String, dynamic>>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    return sortedMap;
  }

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyState(
        icon: Icons.inbox_outlined,
        title: 'No pending requests',
        subtitle: 'All caught up for now.',
      );
    }
    final groupedData = _groupByEvent(rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedIds.isEmpty ? null : onBulkApprove,
            child: Text('Approve Selected (${selectedIds.length})'),
          ),
        ),
        const SizedBox(height: 12),
        ...groupedData.entries.map((entry) {
          final eventName = entry.key;
          final items = entry.value;
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        eventName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => onBulkApproveGroup(items),
                      child: const Text('Approve All'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (row) => _ODRequestCard(
                    row: row,
                    selected: selectedIds.contains(row['id']?.toString() ?? ''),
                    onToggleSelected: (checked) {
                      final id = row['id']?.toString() ?? '';
                      if (id.isEmpty) return;
                      onToggleSelected(id, checked);
                    },
                    onApprove: () => onApprove(row),
                    onReject: () => onReject(row),
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

class _HistoryPanel extends StatelessWidget {
  const _HistoryPanel({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final historyRows = rows.where((r) {
      final status = (r['status']?.toString() ?? '').toLowerCase();
      return status == 'approved' || status == 'rejected';
    }).toList();

    if (historyRows.isEmpty) {
      return const _EmptyState(
        icon: Icons.history_rounded,
        title: 'No final decisions yet',
        subtitle: 'Approved and rejected OD requests will appear here.',
      );
    }

    return Column(
      children: historyRows.map((row) {
        final status = row['status']?.toString() ?? 'Pending';
        final isApproved = status.toLowerCase() == 'approved';
        final color = isApproved ? Colors.green : Colors.red;
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
              Icon(
                isApproved ? Icons.check_circle : Icons.cancel,
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
                      style: const TextStyle(color: Colors.grey),
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
    required this.selected,
    required this.onToggleSelected,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final bool selected;
  final ValueChanged<bool> onToggleSelected;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: selected,
                onChanged: (value) => onToggleSelected(value ?? false),
              ),
              Expanded(
                child: Text(
                  eventName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
              border: Border.all(color: const Color(0xFFE3E8F2)),
              color: const Color(0xFFFAFCFF),
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
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: onReject,
                      child: const Text('Reject'),
                    ),
                  ],
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
    final name = AuthStore.fullName ?? 'Principal';
    final dept = AuthStore.userDepartment ?? 'Department';

    return RoleProfilePage(
      name: name,
      role: 'Principal',
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
