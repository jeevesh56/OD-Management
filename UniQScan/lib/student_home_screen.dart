// ignore_for_file: avoid_web_libraries_in_flutter
// dart:html only available on web build — used for file picker
// ignore: uri_does_not_exist
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});
  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBlue,
        automaticallyImplyLeading: false,
        title: const Text('RIT OD Manager',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthStore.clear();
              Navigator.pushReplacement<void, void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _pageForIndex(_tab),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard),         label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline),label: 'New OD'),
          BottomNavigationBarItem(icon: Icon(Icons.history),            label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person),             label: 'Profile'),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return const _Dashboard();
      case 1:
        return _NewODPage(
          onSubmitted: () {
            setState(() {
              _tab = 0;
            });
          },
        );
      case 2:
        return const _HistoryPage();
      case 3:
      default:
        return const _ProfilePage();
    }
  }
}

// ── DASHBOARD ─────────────────────────────────────────────────────────────────
class _Dashboard extends StatefulWidget {
  const _Dashboard();
  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  bool _loading = true;
  List<dynamic> _requests = <dynamic>[];
  Map<String, dynamic>? _activeSession;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final results = await Future.wait([
      OdApi.myRequests(),
      OdApi.activeSession(),
    ]);
    final reqRes = results[0] as ApiResult<List<dynamic>>;
    final sessRes = results[1] as ApiResult<Map<String, dynamic>>;
    setState(() {
      _loading = false;
      if (reqRes.ok)  _requests      = reqRes.data ?? <dynamic>[];
      if (sessRes.ok) _activeSession = sessRes.data;
      if (!reqRes.ok) _error = reqRes.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(_error!, _load);

    final name = AuthStore.fullName ?? 'Student';
    final sp   = AuthStore.studentProfile;
    final att  = sp?['attendance_percent'] != null
        ? '${sp!['attendance_percent']}%' : '—';
    final sessionName = ((_activeSession?['session'] as Map?)?['event_name'])
            ?.toString() ??
        '—';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Greeting
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kBlue, Color(0xFF1976D2)]),
              borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $name 👋',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Attendance: $att',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ]),
          ),
          const SizedBox(height: 16),
          // Active session banner
          if (_activeSession?['has_active_session'] == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'OD Active: $sessionName',
                  style: TextStyle(color: Colors.green.shade800,
                    fontWeight: FontWeight.bold))),
              ]),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
              child: const Row(children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 10),
                Text('No active OD session',
                  style: TextStyle(color: Colors.grey)),
              ]),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Requests', style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(onPressed: _load,
                child: const Text('Refresh')),
            ],
          ),
          const SizedBox(height: 8),
          if (_requests.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No OD requests yet',
                style: TextStyle(color: Colors.grey)),
            ))
          else
            ..._requests
                .take(5)
                .map((r) => _OdTile(r as Map<dynamic, dynamic>)),
        ]),
      ),
    );
  }
}

// ── NEW OD FORM ───────────────────────────────────────────────────────────────
class _NewODPage extends StatefulWidget {
  const _NewODPage({this.onSubmitted});

  final VoidCallback? onSubmitted;
  @override
  State<_NewODPage> createState() => _NewODPageState();
}

class _NewODPageState extends State<_NewODPage> {
  final _eventCtrl  = TextEditingController();
  final _orgCtrl    = TextEditingController();
  final _venueCtrl  = TextEditingController();
  final _reasonCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  // File attachment
  String? _fileName;
  String? _fileBase64;
  String? _fileMime;
  bool _fileLoading = false;

  bool _submitting  = false;
  bool _checkingOverlap = false;
  String? _overlapWarning;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c));

  // ── Web file picker using dart:html ───────────────────────────────────────
  Future<void> _pickFile() async {
    setState(() => _fileLoading = true);
    final input = html.FileUploadInputElement();
    input.accept = '.pdf,.jpg,.jpeg,.png';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) {
      setState(() => _fileLoading = false);
      return;
    }

    final file   = input.files![0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    // result is "data:mime;base64,XXXX" — strip the prefix
    final result  = reader.result as String;
    final commaIdx = result.indexOf(',');
    final base64  = result.substring(commaIdx + 1);
    final mime    = result.substring(5, result.indexOf(';'));

    // Limit to 5 MB
    if (base64.length * 3 / 4 > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File too large (max 5 MB)'),
          backgroundColor: Colors.red));
      setState(() => _fileLoading = false);
      return;
    }

    setState(() {
      _fileName   = file.name;
      _fileBase64 = base64;
      _fileMime   = mime;
      _fileLoading = false;
    });
  }

  // ── Date / time helpers ───────────────────────────────────────────────────
  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d == null) return;
    setState(() => isStart ? _startDate = d : _endDate = d);

    // Check overlap once both dates set
    if (_startDate != null && _endDate != null) {
      _checkOverlap();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isStart
        ? const TimeOfDay(hour: 9, minute: 0)
        : const TimeOfDay(hour: 17, minute: 0),
    );
    if (t == null) return;
    setState(() => isStart ? _startTime = t : _endTime = t);
  }

  Future<void> _checkOverlap() async {
    if (_startDate == null || _endDate == null) return;
    setState(() { _checkingOverlap = true; _overlapWarning = null; });
    final r = await OdApi.checkOverlap(
      startDate: _fmt(_startDate!),
      endDate:   _fmt(_endDate!),
    );
    setState(() {
      _checkingOverlap = false;
      if (r.ok && r.data?['has_overlap'] == true) {
        _overlapWarning = '⚠ Overlaps with an existing OD request';
      }
    });
  }

  String _fmt(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

  String _displayDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';

  String _displayTime(TimeOfDay t) => t.format(context);

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate
    if (_eventCtrl.text.trim().isEmpty) {
      _err('Enter event name'); return;
    }
    if (_orgCtrl.text.trim().isEmpty) {
      _err('Enter organiser'); return;
    }
    if (_venueCtrl.text.trim().isEmpty) {
      _err('Enter venue'); return;
    }
    if (_startDate == null) { _err('Select start date'); return; }
    if (_endDate == null)   { _err('Select end date'); return; }
    if (_startTime == null) { _err('Select start time'); return; }
    if (_endTime == null)   { _err('Select end time'); return; }
    if (_endDate!.isBefore(_startDate!)) {
      _err('End date cannot be before start date'); return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _err('Enter a reason'); return;
    }

    setState(() => _submitting = true);

    // Build reason — append file info if attached
    String reason = _reasonCtrl.text.trim();
    if (_fileName != null) {
      reason += '\n[Attachment: $_fileName]';
    }

    final r = await OdApi.submit(
      eventName:  _eventCtrl.text.trim(),
      organiser:  _orgCtrl.text.trim(),
      venue:      _venueCtrl.text.trim(),
      startDate:  _fmt(_startDate!),
      endDate:    _fmt(_endDate!),
      startTime:  _fmtTime(_startTime!),
      endTime:    _fmtTime(_endTime!),
      reason:     reason,
      attachmentBase64: _fileBase64,
      attachmentMime:   _fileMime,
      attachmentName:   _fileName,
    );

    setState(() => _submitting = false);

    if (!mounted) return;
    if (r.ok) {
      _eventCtrl.clear(); _orgCtrl.clear();
      _venueCtrl.clear(); _reasonCtrl.clear();
      setState(() {
        _startDate = null; _endDate = null;
        _startTime = null; _endTime = null;
        _fileName  = null; _fileBase64 = null;
        _overlapWarning = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OD Request submitted successfully! ✓'),
          backgroundColor: Colors.green));
      // After successful submit, go back to dashboard so the OD is visible.
      widget.onSubmitted?.call();
    } else {
      _err(r.error ?? 'Submission failed');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('New OD Request',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('Fill in the event details below',
          style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),

        _field('Event Name *', _eventCtrl, 'e.g. National Symposium 2025'),
        _field('Organiser *',  _orgCtrl,   'e.g. IEEE Chennai Section'),
        _field('Venue *',      _venueCtrl, 'e.g. Anna University, Chennai'),

        // ── Date Range ──────────────────────────────────────────────────────
        const Text('Date & Time *',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),

        // Start row
        Row(children: [
          Expanded(child: _dateTile(
            _startDate == null ? 'Start Date' : _displayDate(_startDate!),
            Icons.calendar_today, () => _pickDate(true))),
          const SizedBox(width: 8),
          Expanded(child: _timeTile(
            _startTime == null ? 'Start Time' : _displayTime(_startTime!),
            Icons.access_time, () => _pickTime(true))),
        ]),
        const SizedBox(height: 8),
        // End row
        Row(children: [
          Expanded(child: _dateTile(
            _endDate == null ? 'End Date' : _displayDate(_endDate!),
            Icons.calendar_today, () => _pickDate(false))),
          const SizedBox(width: 8),
          Expanded(child: _timeTile(
            _endTime == null ? 'End Time' : _displayTime(_endTime!),
            Icons.access_time, () => _pickTime(false))),
        ]),

        // Overlap warning
        if (_checkingOverlap)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(children: [
              SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Checking for overlaps…',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
        if (_overlapWarning != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_overlapWarning!,
              style: const TextStyle(color: Colors.orange,
                fontWeight: FontWeight.w500))),

        const SizedBox(height: 16),

        // ── File attachment ─────────────────────────────────────────────────
        const Text('Supporting Document',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Brochure, proof of participation (PDF / JPG / PNG, max 5 MB)',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 8),

        _fileName == null
          ? GestureDetector(
              onTap: _fileLoading ? null : _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: kBlue.withOpacity(0.4),
                    style: BorderStyle.solid, width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                  color: kBlue.withOpacity(0.03)),
                child: _fileLoading
                  ? const Center(child: CircularProgressIndicator())
                  : const Column(children: [
                      Icon(Icons.upload_file, size: 36, color: kBlue),
                      SizedBox(height: 8),
                      Text('Click to attach file',
                        style: TextStyle(color: kBlue,
                          fontWeight: FontWeight.w600)),
                      Text('PDF, JPG or PNG',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ]),
              ),
            )
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.insert_drive_file, color: Colors.green),
                const SizedBox(width: 10),
                Expanded(child: Text(_fileName!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis)),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 18),
                  onPressed: () => setState(() {
                    _fileName   = null;
                    _fileBase64 = null;
                    _fileMime   = null;
                  })),
              ]),
            ),

        const SizedBox(height: 16),
        _field('Reason *', _reasonCtrl,
          'Why are you attending?', maxLines: 3),

        const SizedBox(height: 4),
        const Text(
          'Your request goes: Mentor → Event Coordinator → HoD',
          style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            child: _submitting
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
              : const Text('SUBMIT OD REQUEST', style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
          fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(hintText: hint,
            border: _border(Colors.grey),
            enabledBorder: _border(Colors.grey),
            focusedBorder: _border(kBlue))),
      ]));

  Widget _dateTile(String label, IconData icon, VoidCallback onTap) =>
    _pickerTile(label, icon, onTap,
      label.contains('/') ? kBlue : Colors.grey);

  Widget _timeTile(String label, IconData icon, VoidCallback onTap) =>
    _pickerTile(label, icon, onTap,
      label.contains(':') ? kBlue : Colors.grey);

  Widget _pickerTile(String label, IconData icon,
      VoidCallback onTap, Color iconColor) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: iconColor == Colors.grey ? Colors.grey : Colors.black))),
        ]),
      ),
    );
}

// ── HISTORY ───────────────────────────────────────────────────────────────────
class _HistoryPage extends StatefulWidget {
  const _HistoryPage();
  @override
  State<_HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<_HistoryPage> {
  bool _loading = true;
  List<dynamic> _items   = <dynamic>[];
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final r = await OdApi.myRequests();
    setState(() {
      _loading = false;
      if (r.ok) _items = r.data ?? [];
      else      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _ErrorView(_error!, _load);
    if (_items.isEmpty) return const Center(
      child: Text('No OD requests yet',
        style: TextStyle(color: Colors.grey)));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _OdTile(_items[i] as Map, expanded: true),
      ),
    );
  }
}

// ── PROFILE ───────────────────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();
  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Student';
    final sp   = AuthStore.studentProfile ?? {};
    final initials = name.split(' ').take(2)
      .map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 16),
        CircleAvatar(radius: 50, backgroundColor: kBlue,
          child: Text(initials, style: const TextStyle(fontSize: 32,
            color: Colors.white, fontWeight: FontWeight.bold))),
        const SizedBox(height: 16),
        Text(name, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.bold)),
        Text(
          (sp['register_number'] ?? '').toString(),
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        _infoCard([
          ('Department', sp['department'] ?? '—'),
          ('Section',    sp['section']    ?? '—'),
          ('Semester',   sp['semester']?.toString() ?? '—'),
          ('Batch',      sp['batch']?.toString()    ?? '—'),
          ('Attendance', sp['attendance_percent'] != null
            ? '${sp['attendance_percent']}%' : '—'),
        ]),
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
            onPressed: () {
              AuthStore.clear();
              Navigator.pushReplacement<void, void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _infoCard(List<(String, String)> rows) => Container(
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)]),
    child: Column(children: List.generate(rows.length, (i) => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(rows[i].$1,
                style: const TextStyle(color: Colors.grey)),
              Text(rows[i].$2,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
        if (i < rows.length - 1)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ]))),
  );
}

// ── SHARED WIDGETS ─────────────────────────────────────────────────────────────
class _OdTile extends StatelessWidget {
  final Map<dynamic, dynamic> r;
  final bool expanded;
  const _OdTile(this.r, {this.expanded = false});

  static const _statusColor = {
    'PENDING':          Colors.orange,
    'MENTOR_APPROVED':  Colors.blue,
    'MENTOR_REJECTED':  Colors.red,
    'EC_CONFIRMED':     Colors.indigo,
    'EC_REJECTED':      Colors.red,
    'HOD_APPROVED':     Colors.green,
    'HOD_REJECTED':     Colors.red,
    'CANCELLED':        Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final status = r['status']?.toString() ?? '';
    final color  = _statusColor[status] ?? Colors.grey;
    final start  = r['start_date']?.toString() ?? '';
    final end    = r['end_date']?.toString() ?? '';
    final dates  = start == end ? start : '$start → $end';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(r['event_name']?.toString() ?? '—',
            style: const TextStyle(fontWeight: FontWeight.bold))),
          _badge(status, color),
        ]),
        const SizedBox(height: 4),
        Text('$dates  •  ${(r['venue']?.toString() ?? '')}',
          style: const TextStyle(color: Colors.grey, fontSize: 12)),
        if (expanded && r['organiser'] != null) ...[
          const SizedBox(height: 4),
          Text('Organiser: ${r['organiser']}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
        if (expanded && (r['mentor_comment'] != null ||
            r['ec_comment'] != null || r['hod_comment'] != null)) ...[
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),
          const Text('Remarks',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          if (r['mentor_comment'] != null)
            Text('Mentor: ${r['mentor_comment']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (r['ec_comment'] != null)
            Text('EC: ${r['ec_comment']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          if (r['hod_comment'] != null)
            Text('HoD: ${r['hod_comment']}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10,
      fontWeight: FontWeight.bold)));
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView(this.message, this.onRetry);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: kBlue,
            foregroundColor: Colors.white)),
      ]),
    ),
  );
}
