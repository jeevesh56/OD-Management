import 'package:flutter/material.dart';
import 'login_screen.dart';

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
        title: const Text('HoD Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kHoDRed,
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
        selectedItemColor: kHoDRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.queue), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.monitor), label: 'Monitor'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
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
  final _requests = [
    {'name': 'Arjun Kumar', 'roll': '21114101001', 'event': 'Symposium 2025', 'dates': 'Mar 10–11', 'section': 'CS-A'},
    {'name': 'Priya S',     'roll': '21114101002', 'event': 'Symposium 2025', 'dates': 'Mar 10–11', 'section': 'CS-A'},
    {'name': 'Ravi M',      'roll': '21114101003', 'event': 'Hackathon',      'dates': 'Mar 15–16', 'section': 'CS-B'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bulk approve banner
        if (_requests.isNotEmpty)
          Container(
            color: kHoDRed.withOpacity(0.08),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Expanded(child: Text(
                '${_requests.length} requests pending for Symposium 2025',
                style: const TextStyle(fontWeight: FontWeight.w500))),
              ElevatedButton(
                onPressed: () {
                  setState(() => _requests.clear());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All requests bulk approved ✓'),
                      backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHoDRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
                child: const Text('Bulk Approve',
                  style: TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        Expanded(
          child: _requests.isEmpty
            ? const Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                  SizedBox(height: 16),
                  Text('All approved!', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) {
                  final r = _requests[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          CircleAvatar(backgroundColor: kHoDRed,
                            child: Text(r['name']![0],
                              style: const TextStyle(color: Colors.white))),
                          const SizedBox(width: 10),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name']!, style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                              Text('${r['roll']}  •  ${r['section']}',
                                style: const TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                            ],
                          )),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20)),
                            child: const Text('EC ✓',
                              style: TextStyle(color: Colors.green,
                                fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text('${r['event']}  •  ${r['dates']}',
                          style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () {
                              setState(() => _requests.removeAt(i));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Request rejected'),
                                  backgroundColor: Colors.red));
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                            child: const Text('Reject',
                              style: TextStyle(color: Colors.red)),
                          )),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton(
                            onPressed: () {
                              setState(() => _requests.removeAt(i));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('OD Approved ✓'),
                                  backgroundColor: Colors.green));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                            child: const Text('Approve',
                              style: TextStyle(color: Colors.white)),
                          )),
                        ]),
                      ],
                    ),
                  );
                },
              ),
        ),
      ],
    );
  }
}

class _HoDAnalytics extends StatelessWidget {
  const _HoDAnalytics();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Month', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _statCard('Total', '47', Icons.assignment, kBlue),
              _statCard('Approved', '32', Icons.check_circle, Colors.green),
              _statCard('Pending', '12', Icons.pending, Colors.orange),
              _statCard('Active Now', '8', Icons.circle, kHoDRed),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('By Section',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _sectionBar('CS-A', 0.8, 18),
                _sectionBar('CS-B', 0.6, 14),
                _sectionBar('CS-C', 0.4, 10),
                _sectionBar('CS-D', 0.3, 5),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28,
            fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );

  Widget _sectionBar(String label, double value, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      SizedBox(width: 40, child: Text(label,
        style: const TextStyle(fontWeight: FontWeight.w500))),
      const SizedBox(width: 8),
      Expanded(child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: value, minHeight: 12,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation(kHoDRed)),
      )),
      const SizedBox(width: 8),
      Text('$count', style: const TextStyle(color: Colors.grey)),
    ]),
  );
}

class _HoDMonitor extends StatelessWidget {
  const _HoDMonitor();
  @override
  Widget build(BuildContext context) {
    final sessions = [
      ('Arjun Kumar', '2117240020160', 'Symposium 2025', 'Until 6:00 PM'),
      ('Priya S',     '2117240020161', 'Symposium 2025', 'Until 6:00 PM'),
      ('Ravi M',      '2117240020162', 'Hackathon',      'Until Mar 16'),
    ];
    return Column(
      children: [
        Container(
          color: Colors.green.shade50,
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.green.shade600, size: 12),
              const SizedBox(width: 8),
              Text('${sessions.length} students currently on OD',
                style: TextStyle(color: Colors.green.shade700,
                  fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.person, color: Colors.green.shade600)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sessions[i].$1, style: const TextStyle(
                      fontWeight: FontWeight.bold)),
                    Text(sessions[i].$3, style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
                    Text(sessions[i].$4, style: TextStyle(
                      color: Colors.green.shade600, fontSize: 11)),
                  ],
                )),
              ]),
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
            const Text('Scan Student ID Card',
              style: TextStyle(fontSize: 22, color: Colors.white,
                fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Verify student OD status',
              style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.camera_alt),
              label: const Text('Open Camera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kHoDRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
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
      child: Column(children: [
        const SizedBox(height: 16),
        const CircleAvatar(radius: 50, backgroundColor: kHoDRed,
          child: Text('RK', style: TextStyle(fontSize: 32,
            color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        const Text('Dr. R. Kumar', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Head of Department · CSE',
          style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(children: [
            _row('Staff ID', 'RIT-HOD-001'),
            const Divider(height: 1),
            _row('Department', 'CSE'),
            const Divider(height: 1),
            _row('Total Students', '180'),
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
