// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:html' as html;

import 'api_service.dart';
import 'screens/login_screen.dart';
import 'main.dart';

const Color kHoDRed = Color(0xFFB71C1C);

class HoDHomeScreen extends StatefulWidget {
  const HoDHomeScreen({super.key});

  @override
  State<HoDHomeScreen> createState() => _HoDHomeScreenState();
}

class _HoDHomeScreenState extends State<HoDHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _HoDQueue(),
    _HoDAnalytics(),
    _HoDMonitor(),
    _ScanPageHoD(),
    _HoDProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.brightness_6_outlined, color: Colors.white),
          onPressed: ThemeController.toggle,
          tooltip: 'Toggle theme',
        ),
        title: const Text(
          'HoD Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kHoDRed,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthStore.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const ODLoginUI(),
                ),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: kHoDRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Queue'),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.monitor), label: 'Monitor'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HoDQueue extends StatefulWidget {
  const _HoDQueue();

  @override
  State<_HoDQueue> createState() => _HoDQueueState();
}

class _HoDQueueState extends State<_HoDQueue> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HoDApi.queue();
    setState(() {
      _loading = false;
      if (res.ok) {
        final raw = res.data;
        _requests = (raw is List ? raw : const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _requests
        : _requests.where((r) {
            final roll = r['roll_number']?.toString().toLowerCase() ?? '';
            final unique = r['unique_id_number']?.toString().toLowerCase() ?? '';
            final name = r['student_name']?.toString().toLowerCase() ?? '';
            return roll.contains(q) || unique.contains(q) || name.contains(q);
          }).toList();

    return Column(
      children: [
        // Bulk approve banner
        if (filtered.isNotEmpty)
          Container(
            color: kHoDRed.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${filtered.length} requests pending final approval',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    HoDApi.bulkAction('all').then((_) => _load());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kHoDRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Bulk Approve',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: Colors.green,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'All approved!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return TextField(
                        onChanged: (v) => setState(() => _query = v),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search by roll / unique ID / name',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      );
                    }

                    final r = filtered[i - 1];
                    return Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: theme.brightness == Brightness.light
                            ? const [
                                BoxShadow(
                                  color: Color(0x11000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ]
                            : const [],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              width: 6,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(20),
                                ),
                                color: kHoDRed,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: kHoDRed,
                                        child: Text(
                                          (r['student_name'] as String? ?? 'S')[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              r['student_name'] as String? ??
                                                  'Student',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurface,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                if ((r['roll_number'] ?? '')
                                                    .toString()
                                                    .isNotEmpty)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: cs
                                                          .surfaceContainerHighest,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        999,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'Roll: ${r['roll_number']}',
                                                      style: TextStyle(
                                                        color: cs.onSurface,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'ID: ${r['id']}',
                                                  style: TextStyle(
                                                    color: cs.onSurfaceVariant,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.surfaceContainerHighest,
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.verified,
                                              size: 14,
                                              color: kHoDRed,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Awaiting HoD',
                                              style: TextStyle(
                                                color: kHoDRed,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.event,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          r['event_name'] as String? ?? '—',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '${r['start_date']} – ${r['end_date']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.place,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          r['venue'] as String? ?? '—',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.fact_check_outlined),
                                      label: const Text('Review & Decide'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      onPressed: () async {
                                        final didAct = await _showReviewSheet(
                                          context,
                                          request: r,
                                        );
                                        if (didAct == true) {
                                          _load();
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HoDAnalytics extends StatefulWidget {
  const _HoDAnalytics();

  @override
  State<_HoDAnalytics> createState() => _HoDAnalyticsState();
}

class _HoDAnalyticsState extends State<_HoDAnalytics> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HoDApi.analytics();
    setState(() {
      _loading = false;
      if (res.ok) {
        _data = Map<String, dynamic>.from(res.data ?? const {});
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final total = (_data['total'] ?? 0).toString();
    final approved = (_data['approved'] ?? 0).toString();
    final pending = (_data['pending'] ?? 0).toString();
    final rejected = (_data['rejected'] ?? 0).toString();
    final activeNow = (_data['active_now'] ?? 0).toString();

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _statCard('Total', total, Icons.assignment, kBlue),
                _statCard(
                  'Approved',
                  approved,
                  Icons.check_circle,
                  Colors.green,
                ),
                _statCard('Pending', pending, Icons.pending, Colors.orange),
                _statCard('Rejected', rejected, Icons.cancel, Colors.red),
                _statCard('Active Now', activeNow, Icons.circle, kHoDRed),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) =>
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
}

class _HoDMonitor extends StatefulWidget {
  const _HoDMonitor();

  @override
  State<_HoDMonitor> createState() => _HoDMonitorState();
}

class _HoDMonitorState extends State<_HoDMonitor> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sessions = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await HoDApi.activeSessions();
    setState(() {
      _loading = false;
      if (res.ok) {
        _sessions = (res.data ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _error = res.error;
      }
    });
  }

  String _fmtUntil(Map<String, dynamic> s) {
    final endRaw = s['end_datetime']?.toString();
    if (endRaw == null || endRaw.isEmpty) return '—';
    final dt = DateTime.tryParse(endRaw);
    if (dt == null) return endRaw;
    final two = (int x) => x.toString().padLeft(2, '0');
    return 'Until ${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final count = _sessions.length;

    return Column(
      children: [
        Container(
          color: Colors.green.shade50,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                color: Colors.green.shade600,
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                '$count active OD session${count == 1 ? '' : 's'}',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: count == 0
              ? const Center(
                  child: Text(
                    'No active OD sessions right now.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _sessions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final s = _sessions[i];
                      final eventName =
                          s['event_name']?.toString() ?? 'Event';
                      final uid =
                          s['student_unique_id']?.toString() ?? '—';
                      final approvedBy =
                          s['approved_by_name']?.toString() ?? '—';
                      final until = _fmtUntil(s);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.green.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uid,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    eventName,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    '$until  •  Approved by $approvedBy',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _ScanPageHoD extends StatelessWidget {
  const _ScanPageHoD();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.qr_code_scanner, size: 120, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Scan Student ID Card',
              style: TextStyle(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verify student OD status',
              style: TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHoDRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoDProfile extends StatelessWidget {
  const _HoDProfile();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 50,
            backgroundColor: kHoDRed,
            child: Text(
              'RK',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Dr. R. Kumar',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Head of Department · CSE',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                _row('Staff ID', 'RIT-HOD-001'),
                const Divider(height: 1),
                _row('Department', 'CSE'),
                const Divider(height: 1),
                _row('Total Students', '180'),
                const Divider(height: 1),
                _row('Pending Approvals', '3'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                AuthStore.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ODLoginUI(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l,
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              v,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

Future<bool?> _showReviewSheet(
  BuildContext context, {
  required Map<String, dynamic> request,
}) {
  final controller = TextEditingController();
  bool submitting = false;

  final studentName = request['student_name']?.toString() ?? 'Student';
  final eventName = request['event_name']?.toString() ?? '—';
  final venue = request['venue']?.toString() ?? '—';
  final dateRange =
      '${request['start_date'] ?? ''} – ${request['end_date'] ?? ''}';
  final id = request['id']?.toString() ?? '';
  final attachmentBase64 = request['attachment_base64']?.toString();
  final attachmentMime = request['attachment_mime']?.toString();
  final attachmentName =
      request['attachment_name']?.toString() ?? 'attachment';

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          void openProof() {
            final b64 = attachmentBase64;
            final mime = attachmentMime;
            if (b64 == null || mime == null || b64.isEmpty || mime.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No proof uploaded for this request')),
              );
              return;
            }

            if (mime.startsWith('image/')) {
              final bytes = base64Decode(b64);
              showDialog(
                context: ctx,
                builder: (_) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachmentName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: InteractiveViewer(
                            child: Image.memory(bytes, fit: BoxFit.contain),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              return;
            }

            final url = 'data:$mime;base64,$b64';
            html.window.open(url, '_blank');
          }

          Future<void> submit(String action) async {
            final text = controller.text.trim();
            final isReject = action == 'REJECTED';
            if (isReject && text.isEmpty) return;
            setModalState(() => submitting = true);
            final res = await HoDApi.action(
              requestId: id,
              action: action == 'APPROVED' ? 'APPROVED' : 'REJECTED',
              reason:
                  text.isEmpty ? (isReject ? null : 'Approved by HoD') : text,
            );
            setModalState(() => submitting = false);
            if (!ctx.mounted) return;
            if (res.ok) {
              Navigator.pop(ctx, true);
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res.error ?? 'Action failed'),
                backgroundColor: Colors.red,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kHoDRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child:
                              const Icon(Icons.fact_check_outlined, color: kHoDRed),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Review OD Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: submitting ? null : () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7FB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0x11000000)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(studentName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              )),
                          const SizedBox(height: 4),
                          Text(eventName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 2),
                          Text(
                            dateRange,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(venue,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              )),
                          if ((attachmentBase64 ?? '').isNotEmpty &&
                              (attachmentMime ?? '').isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.attachment_outlined,
                                  size: 16,
                                  color: Colors.black54,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    attachmentName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                TextButton(
                                  onPressed: submitting ? null : openProof,
                                  child: const Text('View proof'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Comment / Reason',
                        helperText: 'Required for rejection. Optional for approval.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting ? null : () => submit('REJECTED'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: submitting ? null : () => submit('APPROVED'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


