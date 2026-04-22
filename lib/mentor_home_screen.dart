import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Timer? _autoRefreshTimer;

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
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_busy) {
        _loadAll(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
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

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kMentorBg,
      drawer: desktop
          ? null
          : Drawer(child: _Sidebar(current: _section, onTap: _onTapSection)),
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
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
        return 'Settings';
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
            icon: Icons.event_note_rounded,
            label: 'OD Requests',
            active: current == 1,
            onTap: () => onTap(1),
          ),
          _SidebarItem(
            icon: Icons.settings_rounded,
            label: 'Settings',
            active: current == 2,
            onTap: () => onTap(2),
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
    final pending = queue.where((e) => (e['status']?.toString() ?? '') == 'Pending').length;
    final approved = history.where((e) => (e['status']?.toString() ?? '') == 'Approved').length;
    final rejected = history.where((e) => (e['status']?.toString() ?? '') == 'Rejected').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _StatCard(
              label: 'Pending Reviews',
              value: pending.toString(),
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
      width: 220,
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
            Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(color: Color(0xFF60708A))),
          ],
        ),
      ),
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
          .map(
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

class _ODRequestCard extends StatelessWidget {
  const _ODRequestCard({
    required this.row,
    required this.onApprove,
    required this.onReject,
  });

  final Map<String, dynamic> row;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  static bool _looksLikeImageUrl(String value) {
    final lower = value.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  static bool _looksLikePdfUrl(String value) {
    return value.toLowerCase().endsWith('.pdf');
  }

  Widget _buildFilePreview(BuildContext context, String fileUrl) {
    if (fileUrl.isEmpty) {
      return const Text('No uploaded proof available.');
    }

    if (_looksLikeImageUrl(fileUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fileUrl,
          height: 170,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Text('Unable to load image preview.'),
        ),
      );
    }

    if (_looksLikePdfUrl(fileUrl)) {
      return InkWell(
        onTap: () async {
          final uri = Uri.tryParse(fileUrl);
          if (uri != null) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: const Text(
          'View PDF Proof',
          style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(fileUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        fileUrl,
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildLegacyPreview() {
    final b64 = row['attachment_base64']?.toString() ?? '';
    final mime = row['attachment_mime']?.toString() ?? '';

    if (b64.isEmpty || mime.isEmpty) {
      return const Text('No uploaded proof available.');
    }

    if (mime.startsWith('image/')) {
      try {
        final bytes = base64Decode(b64);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(bytes, height: 170, width: double.infinity, fit: BoxFit.cover),
        );
      } catch (_) {
        return const Text('Unable to decode image proof.');
      }
    }

    if (mime == 'application/pdf') {
      return const Text('PDF proof attached (upload URL required for web preview).');
    }

    return const Text('Unsupported proof format.');
  }

  @override
  Widget build(BuildContext context) {
    final eventName = row['event_name']?.toString() ?? 'Untitled event';
    final datetime = row['datetime']?.toString() ?? '---';
    final venue = row['venue']?.toString() ?? '---';
    final organizer = row['organizer']?.toString() ?? row['organiser']?.toString() ?? '---';
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
                fileUrl.isNotEmpty ? _buildFilePreview(context, fileUrl) : _buildLegacyPreview(),
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
