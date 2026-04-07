// ignore_for_file: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';

import 'dart:convert';
import 'dart:html' as html;

import 'api_service.dart';
import 'screens/login_screen.dart';

class ECHomeScreen extends StatefulWidget {
  const ECHomeScreen({super.key});

  @override
  State<ECHomeScreen> createState() => _ECHomeScreenState();
}

class _ECHomeScreenState extends State<ECHomeScreen> {
  int _currentIndex = 0;

  void _openTab(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Coordinator',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kBlue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthStore.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ODLoginUI()),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _ECDashboard(
            onCreateOd: () => _openTab(2),
            onSelectStudentsBulk: () => _openTab(2),
            onOpenSubmittedRequests: () => _openTab(1),
            onOpenQrScanner: () => _openTab(3),
          ),
          const _ECEvents(),
          const _ECUpload(),
          const _ScanPageEC(),
          const _ECProfile(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_customize_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Submitted',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Upload',
          ),
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

class _ECDashboard extends StatefulWidget {
  const _ECDashboard({
    required this.onCreateOd,
    required this.onSelectStudentsBulk,
    required this.onOpenSubmittedRequests,
    required this.onOpenQrScanner,
  });

  final VoidCallback onCreateOd;
  final VoidCallback onSelectStudentsBulk;
  final VoidCallback onOpenSubmittedRequests;
  final VoidCallback onOpenQrScanner;

  @override
  State<_ECDashboard> createState() => _ECDashboardState();
}

class _ECDashboardState extends State<_ECDashboard> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];

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

    final res = await ECApi.queue();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.ok) {
        final raw = res.data;
        final list = raw is List ? raw : const [];
        _requests = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _error = res.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final width = MediaQuery.of(context).size.width;
    final useTable = width >= 900;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kBlue.withOpacity(0.07), cs.surface],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: theme.brightness == Brightness.light
                    ? const [
                        BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Coordinator Dashboard',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Review requests, create OD batches, and verify students quickly.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: widget.onCreateOd,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Create OD',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DashboardActionCard(
                  title: 'Select Students (Bulk)',
                  subtitle: 'Upload list and assign one event in seconds',
                  icon: Icons.groups_2_outlined,
                  onTap: widget.onSelectStudentsBulk,
                ),
                _DashboardActionCard(
                  title: 'Submitted Requests',
                  subtitle: 'Open complete queue and approvals timeline',
                  icon: Icons.assignment_turned_in_outlined,
                  onTap: widget.onOpenSubmittedRequests,
                ),
                _DashboardActionCard(
                  title: 'QR Scanner',
                  subtitle: 'Scan student ID and verify OD eligibility',
                  icon: Icons.qr_code_scanner,
                  onTap: widget.onOpenQrScanner,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Pending For EC',
                    value: _loading ? '...' : '${_requests.length}',
                    color: const Color(0xFFEF6C00),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    label: 'Ready To Process',
                    value: _loading
                        ? '...'
                        : '${_requests.where((e) => (e['status']?.toString().isNotEmpty ?? false)).length}',
                    color: const Color(0xFF00897B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: theme.brightness == Brightness.light
                    ? const [
                        BoxShadow(color: Color(0x10000000), blurRadius: 10),
                      ]
                    : const [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Submitted Requests',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  else if (_requests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No submitted requests available.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (useTable)
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        columns: const [
                          DataColumn(label: Text('Request ID')),
                          DataColumn(label: Text('Student')),
                          DataColumn(label: Text('Event')),
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Status')),
                        ],
                        rows: _requests.take(8).map((r) {
                          final status = r['status']?.toString() ?? 'Pending';
                          return DataRow(
                            cells: [
                              DataCell(Text(r['id']?.toString() ?? '-')),
                              DataCell(
                                Text(
                                  r['student_name']?.toString() ?? 'Student',
                                ),
                              ),
                              DataCell(
                                Text(r['event_name']?.toString() ?? '-'),
                              ),
                              DataCell(Text('${r['start_date'] ?? '-'}')),
                              DataCell(_statusBadge(status)),
                            ],
                          );
                        }).toList(),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _requests.length > 5 ? 5 : _requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _requests[i];
                        final status = r['status']?.toString() ?? 'Pending';
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      r['event_name']?.toString() ?? 'Event',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _statusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${r['student_name'] ?? 'Student'} • ID ${r['id'] ?? '-'}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toUpperCase();
    Color bg = Colors.blue.shade50;
    Color fg = Colors.blue.shade700;

    if (s.contains('REJECT')) {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
    } else if (s.contains('APPROVED') || s.contains('CONFIRM')) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
    } else if (s.contains('PENDING')) {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width > 780 ? (width - 56) / 3 : double.infinity;

    return SizedBox(
      width: cardWidth,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x14000000)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: kBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ECQueue extends StatefulWidget {
  const _ECQueue();

  @override
  State<_ECQueue> createState() => _ECQueueState();
}

class _ECQueueState extends State<_ECQueue> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  final Map<String, bool> _proofChecked = <String, bool>{};

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
    final res = await ECApi.queue();
    setState(() {
      _loading = false;
      if (res.ok) {
        final raw = res.data;
        final list = raw is List ? raw : const [];
        _requests = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _proofChecked.clear();
      } else {
        _error = res.error;
      }
    });
  }

  void _openProof(BuildContext context, Map<String, dynamic> r) {
    final b64 = r['attachment_base64']?.toString();
    final mime = r['attachment_mime']?.toString();
    final name = r['attachment_name']?.toString() ?? 'attachment';

    if (b64 == null || mime == null || b64.isEmpty || mime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No proof uploaded for this request')),
      );
      return;
    }

    if (mime.startsWith('image/')) {
      final bytes = base64Decode(b64);
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
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
    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Queue empty!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final r = _requests[i];
        final requestId = r['id']?.toString() ?? '';
        final hasProof =
            (r['attachment_base64']?.toString().isNotEmpty ?? false) &&
            (r['attachment_mime']?.toString().isNotEmpty ?? false);
        final proofChecked = _proofChecked[requestId] ?? false;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 6,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18),
                  ),
                  color: Colors.indigo.shade400,
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
                            backgroundColor: kBlue,
                            child: Text(
                              (r['student_name'] as String? ?? 'S')[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['student_name'] as String? ?? 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Request ID: ${r['id']}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 11,
                                  ),
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.verified, size: 14, color: kBlue),
                                SizedBox(width: 4),
                                Text(
                                  'Mentor OK',
                                  style: TextStyle(
                                    color: kBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r['event_name'] as String? ?? '—',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: Colors.grey,
                          ),
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
                          const Icon(Icons.place, size: 16, color: Colors.grey),
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
                      if (hasProof) ...[
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
                                r['attachment_name']?.toString() ??
                                    'attachment',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openProof(context, r),
                              child: const Text('View proof'),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        const Text(
                          'No proof uploaded',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      CheckboxListTile(
                        value: proofChecked,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'I verified the student proof',
                          style: TextStyle(fontSize: 12),
                        ),
                        onChanged: (v) {
                          if (requestId.isEmpty) return;
                          setState(() => _proofChecked[requestId] = v ?? false);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                ECApi.action(
                                  requestId: requestId,
                                  action: 'REJECTED',
                                  reason: 'Rejected by EC',
                                ).then((_) => _load());
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: proofChecked
                                  ? () {
                                      ECApi.action(
                                        requestId: requestId,
                                        action: 'CONFIRMED',
                                        reason: 'Confirmed by EC',
                                      ).then((_) => _load());
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _ECEvents extends StatefulWidget {
  const _ECEvents();

  @override
  State<_ECEvents> createState() => _ECEventsState();
}

class _ECEventsState extends State<_ECEvents> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _events = [];
  final Map<String, List<Map<String, dynamic>>> _registrationsByEventId = {};
  final Set<String> _loadingEventIds = {};

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
    final res = await EventsApi.list();
    setState(() {
      _loading = false;
      if (res.ok) {
        final raw = res.data;
        final list = raw is List ? raw : const [];
        _events = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _registrationsByEventId.clear();
        _loadingEventIds.clear();
      } else {
        _error = res.error;
      }
    });
  }

  Future<void> _loadRegistrations(String eventId) async {
    if (_registrationsByEventId.containsKey(eventId)) return;
    if (_loadingEventIds.contains(eventId)) return;
    setState(() => _loadingEventIds.add(eventId));

    final res = await EventsApi.registrations(eventId);
    if (!mounted) return;
    setState(() {
      _loadingEventIds.remove(eventId);
      if (res.ok) {
        final raw = res.data;
        final list = raw is List ? raw : const [];
        _registrationsByEventId[eventId] = list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } else {
        _registrationsByEventId[eventId] = const [];
        _error = res.error;
      }
    });
  }

  void _openProof(BuildContext context, Map<String, dynamic> r) {
    final b64 = r['attachment_base64']?.toString();
    final mime = r['attachment_mime']?.toString();
    final name = r['attachment_name']?.toString() ?? 'attachment';

    if (b64 == null || mime == null || b64.isEmpty || mime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No proof uploaded for this request')),
      );
      return;
    }

    if (mime.startsWith('image/')) {
      final bytes = base64Decode(b64);
      showDialog(
        context: context,
        builder: (_) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
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

    // PDF / other → open in new tab (web)
    final url = 'data:$mime;base64,$b64';
    html.window.open(url, '_blank');
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
    if (_events.isEmpty) {
      return const Center(
        child: Text(
          'No OD requests yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final ev = _events[i];
        final evId = ev['event_id']?.toString() ?? '';
        final evName = ev['event_name']?.toString() ?? 'Event';
        final venue = ev['venue']?.toString();
        final dateRange = '${ev['start_date'] ?? ''} – ${ev['end_date'] ?? ''}';

        final regs = _registrationsByEventId[evId];
        final loadingRegs = _loadingEventIds.contains(evId);

        final cs = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: theme.brightness == Brightness.light
                ? const [BoxShadow(color: Colors.black12, blurRadius: 4)]
                : const [],
          ),
          child: ExpansionTile(
            onExpansionChanged: (open) {
              if (open && evId.isNotEmpty) _loadRegistrations(evId);
            },
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.event, color: kBlue),
            ),
            title: Text(
              evName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              [
                if (venue != null && venue.trim().isNotEmpty) venue.trim(),
                dateRange.trim(),
              ].where((e) => e.isNotEmpty).join(' • '),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            children: [
              if (evId.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Cannot load registrations (missing event id).'),
                )
              else if (loadingRegs)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (regs == null)
                const SizedBox.shrink()
              else if (regs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'No students yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: regs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, j) {
                    final r = regs[j];
                    final name = r['student_name']?.toString() ?? 'Student';
                    final roll = r['roll_number']?.toString();
                    final status = r['status']?.toString();
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: kBlue.withOpacity(0.12),
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'S',
                          style: const TextStyle(color: kBlue),
                        ),
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        [
                          if (roll != null && roll.isNotEmpty) 'Roll: $roll',
                          if (status != null && status.isNotEmpty)
                            'Status: $status',
                        ].join(' • '),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        tooltip: 'View proof',
                        icon: const Icon(Icons.attachment_outlined),
                        onPressed: () => _openProof(context, r),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ECUpload extends StatelessWidget {
  const _ECUpload();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bulk PDF Upload',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Upload a PDF containing student roll numbers',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Event',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ['Symposium 2025', 'AI Workshop', 'Hackathon']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File picker coming soon')),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kBlue,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: kBlue.withOpacity(0.05),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.upload_file, size: 48, color: kBlue),
                        SizedBox(height: 12),
                        Text(
                          'Tap to select PDF',
                          style: TextStyle(
                            color: kBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Participant list with roll numbers',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text(
                      'Upload & Create ODs',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select a file first')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPageEC extends StatelessWidget {
  const _ScanPageEC();

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
                backgroundColor: kBlue,
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

class _ECProfile extends StatelessWidget {
  const _ECProfile();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const CircleAvatar(
            radius: 50,
            backgroundColor: kBlue,
            child: Text(
              'AN',
              style: TextStyle(
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Prof. Anita Nair',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'Event Coordinator · CSE',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Column(
              children: [
                _row('Staff ID', 'RIT-FAC-002'),
                const Divider(height: 1),
                _row('Department', 'CSE'),
                const Divider(height: 1),
                _row('Events Managed', '3'),
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
                  MaterialPageRoute(builder: (_) => const ODLoginUI()),
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
        Text(l, style: const TextStyle(color: Colors.grey)),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
