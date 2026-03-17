import 'package:flutter/material.dart';
import 'login_screen.dart';

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
        title: const Text('Mentor Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kBlue,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen())),
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
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
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
  final _requests = [
    {'name': 'Arjun Kumar',   'roll': '21114101001', 'event': 'Symposium 2025',  'dates': 'Mar 10–11', 'attend': '78.5%', 'hrs': '2.1'},
    {'name': 'Priya S',       'roll': '21114101002', 'event': 'AI Workshop',      'dates': 'Mar 12',    'attend': '82.0%', 'hrs': '0.5'},
    {'name': 'Ravi M',        'roll': '21114101003', 'event': 'Hackathon',        'dates': 'Mar 15–16', 'attend': '71.0%', 'hrs': '5.0'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('All caught up!', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
          Text('No pending approvals', style: TextStyle(color: Colors.grey)),
        ],
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = _requests[i];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(
                  backgroundColor: kBlue,
                  child: Text(r['name']![0],
                    style: const TextStyle(color: Colors.white))),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r['name']!, style: const TextStyle(
                      fontWeight: FontWeight.bold)),
                    Text(r['roll']!, style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text('${r['hrs']}h ago',
                    style: TextStyle(color: Colors.orange.shade700,
                      fontSize: 11)),
                ),
              ]),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  _row('Event', r['event']!),
                  _row('Dates', r['dates']!),
                  _row('Attendance', r['attend']!),
                ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  label: const Text('Reject',
                    style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    setState(() => _requests.removeAt(i));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request rejected'),
                        backgroundColor: Colors.red));
                  },
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.check, color: Colors.white, size: 18),
                  label: const Text('Approve',
                    style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  onPressed: () {
                    setState(() => _requests.removeAt(i));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request approved ✓'),
                        backgroundColor: Colors.green));
                  },
                )),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500,
          fontSize: 13)),
      ],
    ),
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
            const Text('Scan Student ID Card',
              style: TextStyle(fontSize: 22, color: Colors.white,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Point at the QR code on the back of the student\'s ID',
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => _showScanResult(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showScanResult(context),
              child: const Text('Simulate Scan (Demo)',
                style: TextStyle(color: Colors.white54)),
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
          borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            const Text('OD ACTIVE', style: TextStyle(
              color: Colors.white, fontSize: 22,
              fontWeight: FontWeight.bold)),
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
                    borderRadius: BorderRadius.circular(12))),
                child: const Text('Scan Another',
                  style: TextStyle(fontWeight: FontWeight.bold)),
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
        Text(label, style: const TextStyle(color: Colors.white70)),
        Flexible(child: Text(value, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.w600),
          textAlign: TextAlign.right)),
      ],
    ),
  );
}

// ── HISTORY ───────────────────────────────────────────────────────────────────
class _MentorHistory extends StatelessWidget {
  const _MentorHistory();
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Arjun Kumar',  'Symposium 2025', 'Approved', Colors.green),
      ('Priya S',      'AI Workshop',    'Rejected',  Colors.red),
      ('Ravi M',       'Hackathon',      'Approved',  Colors.green),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(children: [
          CircleAvatar(backgroundColor: kBlue,
            child: Text(items[i].$1[0],
              style: const TextStyle(color: Colors.white))),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(items[i].$1,
                style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(items[i].$2,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: items[i].$4.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20)),
            child: Text(items[i].$3,
              style: TextStyle(color: items[i].$4,
                fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ]),
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
      child: Column(children: [
        const SizedBox(height: 16),
        const CircleAvatar(radius: 50, backgroundColor: kBlue,
          child: Text('RK', style: TextStyle(fontSize: 32,
            color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        const Text('Dr. Ramesh K.', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Mentor · CSE', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(children: [
            _row('Staff ID', 'RIT-FAC-001'),
            const Divider(height: 1),
            _row('Department', 'CSE'),
            const Divider(height: 1),
            _row('Students Assigned', '45'),
            const Divider(height: 1),
            _row('Pending Approvals', '3'),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 48,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout',
              style: TextStyle(color: Colors.red, fontSize: 16)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen())),
          ),
        ),
      ]),
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
