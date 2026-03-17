import 'package:flutter/material.dart';
import 'login_screen.dart';

class ECHomeScreen extends StatefulWidget {
  const ECHomeScreen({super.key});
  @override
  State<ECHomeScreen> createState() => _ECHomeScreenState();
}

class _ECHomeScreenState extends State<ECHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _ECQueue(),
    _ECEvents(),
    _ECUpload(),
    _ScanPageEC(),
    _ECProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Coordinator',
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
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
  final _requests = [
    {'name': 'Arjun Kumar', 'roll': '21114101001', 'event': 'Symposium 2025', 'dates': 'Mar 10–11'},
    {'name': 'Priya S',     'roll': '21114101002', 'event': 'Symposium 2025', 'dates': 'Mar 10–11'},
  ];

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return const Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('Queue empty!', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold)),
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
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                CircleAvatar(backgroundColor: kBlue,
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
                  decoration: BoxDecoration(color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20)),
                  child: const Text('MENTOR ✓',
                    style: TextStyle(color: kBlue, fontSize: 11,
                      fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 10),
              Text('${r['event']}  •  ${r['dates']}',
                style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () {
                    setState(() => _requests.removeAt(i));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Request rejected'),
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
                      const SnackBar(content: Text('EC Confirmed ✓'),
                        backgroundColor: Colors.green));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
                  child: const Text('Confirm',
                    style: TextStyle(color: Colors.white)),
                )),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class _ECEvents extends StatelessWidget {
  const _ECEvents();
  @override
  Widget build(BuildContext context) {
    final events = [
      ('Symposium 2025', 'Mar 10–11', '45 students'),
      ('AI Workshop',    'Mar 12',    '12 students'),
      ('Hackathon',      'Mar 15–16', '30 students'),
    ];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(color: kBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.event, color: kBlue)),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(events[i].$1, style: const TextStyle(
                fontWeight: FontWeight.bold)),
              Text('${events[i].$2}  •  ${events[i].$3}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
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
          const Text('Bulk PDF Upload',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Upload a PDF containing student roll numbers',
            style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Event',
                  style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                  items: ['Symposium 2025', 'AI Workshop', 'Hackathon']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('File picker coming soon'))),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kBlue, style: BorderStyle.solid, width: 2),
                      borderRadius: BorderRadius.circular(12),
                      color: kBlue.withOpacity(0.05)),
                    child: const Column(children: [
                      Icon(Icons.upload_file, size: 48, color: kBlue),
                      SizedBox(height: 12),
                      Text('Tap to select PDF',
                        style: TextStyle(color: kBlue,
                          fontWeight: FontWeight.w600)),
                      Text('Participant list with roll numbers',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload, color: Colors.white),
                    label: const Text('Upload & Create ODs',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Select a file first'))),
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
                backgroundColor: kBlue,
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

class _ECProfile extends StatelessWidget {
  const _ECProfile();
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        const CircleAvatar(radius: 50, backgroundColor: kBlue,
          child: Text('AN', style: TextStyle(fontSize: 32,
            color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 12),
        const Text('Prof. Anita Nair', style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Event Coordinator · CSE',
          style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
          child: Column(children: [
            _row('Staff ID', 'RIT-FAC-002'),
            const Divider(height: 1),
            _row('Department', 'CSE'),
            const Divider(height: 1),
            _row('Events Managed', '3'),
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
