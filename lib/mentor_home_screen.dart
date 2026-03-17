import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';

class MentorHomeScreen extends StatefulWidget {
  const MentorHomeScreen({super.key});

  @override
  State<MentorHomeScreen> createState() => _MentorHomeScreenState();
}

class _MentorHomeScreenState extends State<MentorHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _MentorQueue(),
    _ScanPage(),
    _MentorHistory(),
    _MentorProfile(),
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
          'Mentor Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Queue'),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// ── QUEUE ─────────────────────────────────────────────────────────────────────
class _MentorQueue extends StatefulWidget {
  const _MentorQueue();

  @override
  State<_MentorQueue> createState() => _MentorQueueState();
}

class _MentorQueueState extends State<_MentorQueue> {
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
    final res = await MentorApi.queue();
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
    if (_requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'All caught up!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'No pending approvals',
              style: TextStyle(color: Colors.grey),
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                    color: Colors.orange.shade400,
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
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  r['start_date']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 11,
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
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Colors.red),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final reason = await _askReason(
                                  context,
                                  title: 'Reject OD',
                                  label: 'Reason for rejection',
                                );
                                if (reason == null) return;
                                MentorApi.action(
                                  requestId: r['id'].toString(),
                                  action: 'REJECTED',
                                  reason: reason,
                                ).then((_) => _load());
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              ),
                              label: const Text(
                                'Approve',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () async {
                                final reason = await _askReason(
                                  context,
                                  title: 'Approve OD',
                                  label: 'Note / comment (optional)',
                                  allowEmpty: true,
                                );
                                MentorApi.action(
                                  requestId: r['id'].toString(),
                                  action: 'APPROVED',
                                  reason: reason?.isEmpty == true
                                      ? 'Approved by mentor'
                                      : reason,
                                ).then((_) => _load());
                              },
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
          ),
        );
      },
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


// ── SCAN ──────────────────────────────────────────────────────────────────────
class _ScanPage extends StatelessWidget {
  const _ScanPage();

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
              'Point at the QR code on the back of the student\'s ID',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _showScanResult(context),
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
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showScanResult(context),
              child: const Text(
                'Simulate Scan (Demo)',
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showScanResult(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text(
              'OD ACTIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _resultRow('Student', 'Arjun Kumar'),
            _resultRow('Event', 'Symposium 2025'),
            _resultRow('Valid', 'Mar 10, 8:00 AM – Mar 11, 6:00 PM'),
            _resultRow('Approved by', 'Dr. R. Kumar (HoD)'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Scan Another',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      );
}

// ── HISTORY ───────────────────────────────────────────────────────────────────
class _MentorHistory extends StatefulWidget {
  const _MentorHistory();

  @override
  State<_MentorHistory> createState() => _MentorHistoryState();
}

class _MentorHistoryState extends State<_MentorHistory> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

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
    final res = await MentorApi.history();
    setState(() {
      _loading = false;
      if (res.ok) {
        _items = (res.data ?? const [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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
    if (_items.isEmpty) {
      return const Center(
        child: Text(
          'No approvals yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = _items[i];
          final status = r['status']?.toString() ?? '';
          final approved = status == 'MENTOR_APPROVED';
          final color = approved ? Colors.green : Colors.red;
          final label = approved ? 'Approved' : 'Rejected';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: kBlue,
                  child: Text(
                    (r['student_name']?.toString() ?? 'S')[0],
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['student_name']?.toString() ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        r['event_name']?.toString() ?? '—',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── PROFILE ───────────────────────────────────────────────────────────────────
class _MentorProfile extends StatelessWidget {
  const _MentorProfile();

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
            'Dr. Ramesh K.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Mentor · CSE',
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
                _row('Staff ID', 'RIT-FAC-001'),
                const Divider(height: 1),
                _row('Department', 'CSE'),
                const Divider(height: 1),
                _row('Students Assigned', '45'),
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

