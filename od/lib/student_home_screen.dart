// ignore_for_file: avoid_web_libraries_in_flutter
// dart:html only available on web build — used for file picker
// ignore: uri_does_not_exist
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';
import 'screens/portal_qr_screen.dart';
import 'widgets/portal_page_layout.dart';
import 'widgets/portal_request_card.dart';
import 'widgets/portal_stat_card.dart';

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
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: kBlue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.brightness_6_outlined, color: Colors.white),
          onPressed: ThemeController.toggle,
          tooltip: 'Toggle theme',
        ),
        title: const Text(
          'Student Portal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      body: _pageForIndex(_tab),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        selectedItemColor: kBlue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'New OD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _pageForIndex(int index) {
    switch (index) {
      case 0:
        return _Dashboard(
          onCreateNewRequest: () {
            setState(() {
              _tab = 1;
            });
          },
        );
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
  const _Dashboard({required this.onCreateNewRequest});

  final VoidCallback onCreateNewRequest;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  bool _loading = true;
  List _requests = [];
  Map? _activeSession;
  String? _error;
  int _tabIndex = 0; // 0 = My Requests, 1 = My QR Code

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
    final results = await Future.wait([
      OdApi.myRequests(),
      OdApi.activeSession(),
    ]);
    final reqRes = results[0];
    final sessRes = results[1];
    setState(() {
      _loading = false;
      if (reqRes.ok) _requests = reqRes.data as List? ?? [];
      if (sessRes.ok) _activeSession = sessRes.data as Map?;
      if (!reqRes.ok) _error = reqRes.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe9f2ff), Color(0xffffffff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe9f2ff), Color(0xffffffff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _ErrorView(_error!, _load),
      );
    }

    final name = AuthStore.fullName ?? 'Student';
    final sp = AuthStore.studentProfile;
    final section = sp?['section']?.toString() ??
        sp?['class']?.toString() ??
        sp?['department']?.toString() ??
        '';
    final welcomeSub =
        section.isNotEmpty ? 'Welcome, $name ($section)' : 'Welcome, $name';

    int total = _requests.length;
    int approved = 0;
    int rejected = 0;
    for (final x in _requests) {
      final s = (x as Map)['status']?.toString() ?? '';
      if (s == 'HOD_APPROVED') {
        approved++;
      } else if (s.contains('REJECTED') || s == 'CANCELLED') {
        rejected++;
      }
    }
    final pending = total - approved - rejected;

    return RefreshIndicator(
      onRefresh: _load,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xffe9f2ff), Color(0xffffffff)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -60,
              child: Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -100,
              bottom: 80,
              child: Container(
                height: 320,
                width: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.06),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student Portal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        welcomeSub,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: PortalStatCard(
                              title: 'Total',
                              value: '$total',
                              icon: Icons.description,
                              color: Colors.blue,
                            ),
                          ),
                          Expanded(
                            child: PortalStatCard(
                              title: 'Approved',
                              value: '$approved',
                              icon: Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          Expanded(
                            child: PortalStatCard(
                              title: 'Pending',
                              value: '$pending',
                              icon: Icons.schedule,
                              color: Colors.orange,
                            ),
                          ),
                          Expanded(
                            child: PortalStatCard(
                              title: 'Rejected',
                              value: '$rejected',
                              icon: Icons.cancel,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_activeSession?['has_active_session'] == true)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade300),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'OD active: ${_activeSession!['session']['event_name']}',
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 8,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.grey),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No active OD session',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x11000000),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _topTabButton('My Requests', 0),
                            _topTabButton('My QR Code', 1),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_tabIndex == 0)
                        _buildRequestsSection()
                      else
                        _buildQrSection(context, name, sp, _requests),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topTabButton(String label, int index) {
    final bool selected = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsSection() {
    if (_requests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(blurRadius: 14, color: Colors.black12),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox, size: 40, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No OD requests yet — use New OD to submit.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OD Requests',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_requests.length} total request${_requests.length == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ..._requests.map(
          (r) => PortalRequestCard(r: r as Map),
        ),
      ],
    );
  }

  Widget _buildQrSection(
    BuildContext context,
    String name,
    Map? sp,
    List requests,
  ) {
    final register = AuthStore.registrationFromLoginEmail().isNotEmpty
        ? AuthStore.registrationFromLoginEmail()
        : (sp?['register_number']?.toString() ?? '—');
    final studentQrData = jsonEncode({
      'type': 'student_id',
      'name': name,
      'register': register,
      'user_id': AuthStore.userId ?? '',
    });
    final approved = requests
        .where((x) => (x as Map)['status']?.toString() == 'HOD_APPROVED')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: portalWhiteCardDecoration(radius: 22),
          child: Column(
            children: [
              const Text(
                'Student QR',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan for identity at the desk',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.black12),
                ),
                child: QrImageView(
                  data: studentQrData,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reg. No: $register',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        if (approved.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'OD pass (approved events)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Full-screen QR for each approved OD',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          ...approved.map((raw) {
            final m = raw as Map;
            final ev = m['event_name']?.toString() ?? 'Event';
            final id = m['id']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PortalQrScreen(
                          eventName: ev,
                          requestId: id,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(blurRadius: 10, color: Colors.black12),
                      ],
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.qr_code_2_rounded,
                            color: Colors.green.shade700, size: 28),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'Open OD pass',
                                style: TextStyle(
                                  color: Colors.green.shade800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.open_in_new_rounded,
                            color: Colors.grey.shade500, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ],
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
  final _eventCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
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

  bool _submitting = false;
  bool _checkingOverlap = false;
  String? _overlapWarning;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c),
      );

  // ── Web file picker using dart:html ───────────────────────────────────────
  Future<void> _pickFile() async {
    setState(() => _fileLoading = true);
    final input = html.FileUploadInputElement();
    // Allow PDF + common image formats
    input.accept = '.pdf,image/*,.jpg,.jpeg,.png,.webp';
    input.click();

    await input.onChange.first;
    if (input.files == null || input.files!.isEmpty) {
      setState(() => _fileLoading = false);
      return;
    }

    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    // result is "data:mime;base64,XXXX" — strip the prefix
    final result = reader.result as String;
    final commaIdx = result.indexOf(',');
    final base64 = result.substring(commaIdx + 1);
    final mime = result.substring(5, result.indexOf(';'));

    // Limit to 5 MB
    if (base64.length * 3 / 4 > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File too large (max 5 MB)'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _fileLoading = false);
      return;
    }

    setState(() {
      _fileName = file.name;
      _fileBase64 = base64;
      _fileMime = mime;
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
    setState(() {
      _checkingOverlap = true;
      _overlapWarning = null;
    });
    final r = await OdApi.checkOverlap(
      startDate: _fmt(_startDate!),
      endDate: _fmt(_endDate!),
    );
    setState(() {
      _checkingOverlap = false;
      if (r.ok && r.data?['has_overlap'] == true) {
        _overlapWarning = '⚠ Overlaps with an existing OD request';
      }
    });
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _displayTime(TimeOfDay t) => t.format(context);

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate
    if (_eventCtrl.text.trim().isEmpty) {
      _err('Enter event name');
      return;
    }
    if (_orgCtrl.text.trim().isEmpty) {
      _err('Enter organiser');
      return;
    }
    if (_venueCtrl.text.trim().isEmpty) {
      _err('Enter venue');
      return;
    }
    if (_startDate == null) {
      _err('Select start date');
      return;
    }
    if (_endDate == null) {
      _err('Select end date');
      return;
    }
    if (_startTime == null) {
      _err('Select start time');
      return;
    }
    if (_endTime == null) {
      _err('Select end time');
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      _err('End date cannot be before start date');
      return;
    }
    if (_reasonCtrl.text.trim().isEmpty) {
      _err('Enter a reason');
      return;
    }

    setState(() => _submitting = true);

    // Build reason — append file info if attached
    String reason = _reasonCtrl.text.trim();
    if (_fileName != null) {
      reason += '\n[Attachment: $_fileName]';
    }

    final r = await OdApi.submit(
      eventName: _eventCtrl.text.trim(),
      organiser: _orgCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      startDate: _fmt(_startDate!),
      endDate: _fmt(_endDate!),
      startTime: _fmtTime(_startTime!),
      endTime: _fmtTime(_endTime!),
      reason: reason,
      attachmentBase64: _fileBase64,
      attachmentMime: _fileMime,
      attachmentName: _fileName,
    );

    setState(() => _submitting = false);

    if (!mounted) return;
    if (r.ok) {
      _eventCtrl.clear();
      _orgCtrl.clear();
      _venueCtrl.clear();
      _reasonCtrl.clear();
      setState(() {
        _startDate = null;
        _endDate = null;
        _startTime = null;
        _endTime = null;
        _fileName = null;
        _fileBase64 = null;
        _overlapWarning = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OD Request submitted successfully! ✓'),
          backgroundColor: Colors.green,
        ),
      );
      // After successful submit, go back to dashboard where the OD is visible.
      widget.onSubmitted?.call();
    } else {
      _err(r.error ?? 'Submission failed');
    }
  }

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade700,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const PortalDecoratedBackground(bottomCircleOffset: 100),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create OD request',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mentor → HoD',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: portalWhiteCardDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Text(
                  'Event details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All fields marked * are required',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 18),
                _field('Event Name *', _eventCtrl, 'e.g. National Symposium 2025'),
                _field('Organiser *', _orgCtrl, 'e.g. IEEE Chennai Section'),
                _field('Venue *', _venueCtrl, 'e.g. Anna University, Chennai'),
                // ── Date Range ──────────────────────────────────────────────
                const Text(
                  'Date & Time *',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                // Start row
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        _startDate == null
                            ? 'Start Date'
                            : _displayDate(_startDate!),
                        Icons.calendar_today,
                        () => _pickDate(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _timeTile(
                        _startTime == null
                            ? 'Start Time'
                            : _displayTime(_startTime!),
                        Icons.access_time,
                        () => _pickTime(true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // End row
                Row(
                  children: [
                    Expanded(
                      child: _dateTile(
                        _endDate == null ? 'End Date' : _displayDate(_endDate!),
                        Icons.calendar_today,
                        () => _pickDate(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _timeTile(
                        _endTime == null ? 'End Time' : _displayTime(_endTime!),
                        Icons.access_time,
                        () => _pickTime(false),
                      ),
                    ),
                  ],
                ),
                // Overlap warning
                if (_checkingOverlap)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Checking for overlaps…',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                if (_overlapWarning != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _overlapWarning!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                // ── File attachment ────────────────────────────────────────
                const Text(
                  'Supporting Document',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Brochure, proof of participation (PDF / JPG / PNG, max 5 MB)',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
                              style: BorderStyle.solid,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: kBlue.withOpacity(0.03),
                          ),
                          child: _fileLoading
                              ? const Center(child: CircularProgressIndicator())
                              : const Column(
                                  children: [
                                    Icon(Icons.upload_file,
                                        size: 36, color: kBlue),
                                    SizedBox(height: 8),
                                    Text(
                                      'Click to attach file',
                                      style: TextStyle(
                                        color: kBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'PDF, JPG or PNG',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _fileName!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.red,
                                size: 18,
                              ),
                              onPressed: () => setState(() {
                                _fileName = null;
                                _fileBase64 = null;
                                _fileMime = null;
                              }),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 16),
                _field(
                  'Reason *',
                  _reasonCtrl,
                  'Why are you attending?',
                  maxLines: 3,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your request goes: Mentor → HoD',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit OD request',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: hint,
                border: _border(Colors.grey),
                enabledBorder: _border(Colors.grey),
                focusedBorder: _border(kBlue),
              ),
            ),
          ],
        ),
      );

  Widget _dateTile(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) =>
      _pickerTile(
        label,
        icon,
        onTap,
        label.contains('/') ? kBlue : Colors.grey,
      );

  Widget _timeTile(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) =>
      _pickerTile(
        label,
        icon,
        onTap,
        label.contains(':') ? kBlue : Colors.grey,
      );

  Widget _pickerTile(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color iconColor,
  ) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: iconColor == Colors.grey
                        ? Colors.grey
                        : Colors.black,
                  ),
                ),
              ),
            ],
          ),
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
  List _items = [];
  String? _error;

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
    final r = await OdApi.myRequests();
    setState(() {
      _loading = false;
      if (r.ok) {
        _items = r.data ?? [];
      } else {
        _error = r.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 80),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_error != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 80),
          _ErrorView(_error!, _load),
        ],
      );
    }
    if (_items.isEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const PortalDecoratedBackground(bottomCircleOffset: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: portalWhiteCardDecoration(),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history_edu, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No requests in history',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create an OD from the New OD tab.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        const PortalDecoratedBackground(bottomCircleOffset: 80),
        RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1040),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request history',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_items.length} request${_items.length == 1 ? '' : 's'} — tap for details',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._items.map(
                      (r) => PortalRequestCard(r: r as Map),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── PROFILE ───────────────────────────────────────────────────────────────────
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Student';
    final sp = AuthStore.studentProfile ?? {};
    final initials = name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0] : '')
        .join()
        .toUpperCase();

    return Stack(
      fit: StackFit.expand,
      children: [
        const PortalDecoratedBackground(bottomCircleOffset: 90),
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            children: [
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: portalWhiteCardDecoration(),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: kBlue,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      sp['register_number'] ?? '',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _infoCard(
                [
                  ('Department', sp['department'] ?? '—'),
                  ('Section', sp['section'] ?? '—'),
                  ('Semester', sp['semester']?.toString() ?? '—'),
                  ('Batch', sp['batch']?.toString() ?? '—'),
                  (
                    'Attendance',
                    sp['attendance_percent'] != null
                        ? '${sp['attendance_percent']}%'
                        : '—',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
        ),
      ],
    );
  }

  Widget _infoCard(List<(String, String)> rows) => Container(
        decoration: portalWhiteCardDecoration(radius: 16),
        child: Column(
          children: List.generate(
            rows.length,
            (i) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        rows[i].$1,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        rows[i].$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (i < rows.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
        ),
      );
}

// ── SHARED WIDGETS ─────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message, this.onRetry);

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
}

