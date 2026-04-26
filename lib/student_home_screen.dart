// ignore_for_file: avoid_web_libraries_in_flutter
// dart:html only available on web build — used for file picker
// ignore: uri_does_not_exist
// ignore: deprecated_member_use
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'api_service.dart';
import 'domain/rules/od_rule_engine.dart';
import 'main.dart';
import 'screens/login_screen.dart';
import 'widgets/portal_od_helpers.dart';
import 'widgets/portal_page_layout.dart';
import 'widgets/portal_request_card.dart';
import 'widgets/proof_action_buttons.dart';

const Color kStudentPrimary = Color(0xFF1257B0);
const Color kStudentSidebar = Color(0xFF102A5C);

// ─────────────────────────────────────────────────────────────────────────────
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  int _dashboardReloadToken = 0;

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.of(context).size.width >= 1024;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: scheme.surfaceContainerLowest,
      drawer: desktop
          ? null
          : Drawer(
              child: _StudentSidebar(current: _tab, onTap: _onSelectTab),
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (desktop)
              SizedBox(
                width: 260,
                child: _StudentSidebar(current: _tab, onTap: _onSelectTab),
              ),
            Expanded(
              child: Column(
                children: [
                  _StudentTopbar(
                    title: _titleForTab(_tab),
                    isDesktop: desktop,
                    onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                    onToggleTheme: ThemeController.toggle,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _tab,
                      children: [
                        _Dashboard(
                          key: ValueKey('dashboard-$_dashboardReloadToken'),
                          onCreateNewRequest: () => setState(() => _tab = 1),
                        ),
                        _NewODPage(
                          onSubmitted: () => setState(() {
                            _tab = 0;
                            _dashboardReloadToken++;
                          }),
                        ),
                        const _HistoryPage(),
                        const _ProfilePage(),
                      ],
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

  void _onSelectTab(int index) {
    setState(() => _tab = index);
    Navigator.of(context).maybePop();
  }

  String _titleForTab(int index) {
    switch (index) {
      case 1:
        return 'New OD';
      case 2:
        return 'History';
      case 3:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }
}

class _StudentSidebar extends StatelessWidget {
  const _StudentSidebar({required this.current, required this.onTap});

  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final name = AuthStore.fullName ?? 'Student';
    final dept = AuthStore.userDepartment ?? 'Department';

    return Container(
      color: kStudentSidebar,
      child: Column(
        children: [
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Student Portal',
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
                  foregroundColor: kStudentSidebar,
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
          _StudentSidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            active: current == 0,
            onTap: () => onTap(0),
          ),
          _StudentSidebarItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'New OD',
            active: current == 1,
            onTap: () => onTap(1),
          ),
          _StudentSidebarItem(
            icon: Icons.history_rounded,
            label: 'History',
            active: current == 2,
            onTap: () => onTap(2),
          ),
          _StudentSidebarItem(
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

class _StudentSidebarItem extends StatelessWidget {
  const _StudentSidebarItem({
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

class _StudentTopbar extends StatelessWidget {
  const _StudentTopbar({
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
    final name = AuthStore.fullName ?? 'Student';
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
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
            backgroundColor: kStudentPrimary.withValues(alpha: 0.1),
            foregroundColor: kStudentPrimary,
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

// ── DASHBOARD ─────────────────────────────────────────────────────────────────
class _Dashboard extends StatefulWidget {
  const _Dashboard({super.key, required this.onCreateNewRequest});

  final VoidCallback onCreateNewRequest;

  @override
  State<_Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<_Dashboard> {
  late Future<List<Map<String, dynamic>>> _futureRequests;
  Map? _activeSession;
  String? _resubmittingId;

  @override
  void initState() {
    super.initState();
    _futureRequests = _fetchRequests();
    _loadActiveSession();
  }

  Future<List<Map<String, dynamic>>> _fetchRequests() async {
    try {
      final reqRes = await OdApi.myRequests();
      if (!reqRes.ok) {
        throw Exception(reqRes.error ?? 'Failed to load dashboard');
      }
      final data = reqRes.data;
      if (data is! List) return const [];
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadActiveSession() async {
    final sessRes = await OdApi.activeSession();
    if (!mounted || !sessRes.ok) return;
    setState(() {
      _activeSession = sessRes.data;
    });
  }

  Future<void> _refreshRequests() async {
    final next = _fetchRequests();
    setState(() {
      _futureRequests = next;
    });
    await next;
  }

  String _statusValue(Map item) {
    return (item['status']?.toString() ?? 'Pending').trim().toLowerCase();
  }

  String _rejectionReason(Map item) {
    final reason = item['rejection_reason']?.toString().trim();
    if (reason != null && reason.isNotEmpty) return reason;
    final review = item['review_note']?.toString().trim();
    if (review != null && review.isNotEmpty) return review;
    return 'Details were incomplete or did not meet policy checks.';
  }

  String _getSuggestion(String reason) {
    final lower = reason.toLowerCase();
    if (lower.contains('proof')) {
      return 'Upload valid proof document.';
    }
    if (lower.contains('late')) {
      return 'Apply before deadline next time.';
    }
    if (lower.contains('details')) {
      return 'Fill all details correctly.';
    }
    return 'Check your request and resubmit.';
  }

  Future<void> _resubmit(Map item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;

    setState(() => _resubmittingId = id);
    final res = await OdApi.resubmitRequest(item);
    if (!mounted) return;
    setState(() => _resubmittingId = null);

    if (!res.ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res.error ?? 'Resubmit failed')));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request sent back for review.')),
    );
    widget.onCreateNewRequest();
    await _refreshRequests();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = AuthStore.fullName ?? 'Student';
    final sp = AuthStore.studentProfile;
    final section =
        sp?['section']?.toString() ??
        sp?['class']?.toString() ??
        sp?['department']?.toString() ??
        '';
    final welcomeSub = section.isNotEmpty
        ? 'Welcome, $name ($section)'
        : 'Welcome, $name';
    final activeSessionName =
        ((_activeSession?['session'] as Map?)?['event_name']
                    ?.toString()
                    .trim() ??
                '')
            .trim();
    final sessionLabel = activeSessionName.isNotEmpty
        ? activeSessionName
        : 'Active OD session';

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _futureRequests,
      builder: (context, snapshot) {
        return RefreshIndicator(
          onRefresh: _refreshRequests,
          child: Stack(
            children: [
              const PortalDecoratedBackground(bottomCircleOffset: 80),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                _ErrorView('Error loading dashboard', _refreshRequests)
              else
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Builder(
                        builder: (context) {
                          final requests =
                              snapshot.data ?? const <Map<String, dynamic>>[];
                          final total = requests.length;
                          var approved = 0;
                          var rejected = 0;
                          for (final x in requests) {
                            final s = x['status']?.toString() ?? '';
                            if (s == 'Approved') {
                              approved++;
                            } else if (s == 'Rejected') {
                              rejected++;
                            }
                          }
                          final pending = total - approved - rejected;

                          return Column(
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
                                style: TextStyle(
                                  fontSize: 15,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildStatsRow(
                                total,
                                approved,
                                pending,
                                rejected,
                              ),
                              const SizedBox(height: 16),
                              if (_activeSession?['has_active_session'] == true)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    border: Border.all(
                                      color: scheme.secondary.withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: scheme.onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'OD active: $sessionLabel',
                                          style: TextStyle(
                                            color: scheme.onSecondaryContainer,
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
                                  decoration: portalCardDecoration(
                                    context,
                                    radius: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'No active OD session',
                                          style: TextStyle(
                                            color: scheme.onSurface.withValues(
                                              alpha: 0.72,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                              _buildActionCenter(requests),
                              const SizedBox(height: 18),
                              _buildRequestsSection(requests),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsRow(int total, int approved, int pending, int rejected) {
    final cards = [
      _buildStatCard('Total', total, Colors.blue),
      _buildStatCard('Approved', approved, Colors.green),
      _buildStatCard('Pending', pending, Colors.orange),
      _buildStatCard('Rejected', rejected, Colors.red),
    ];

    final isWide = MediaQuery.of(context).size.width >= 980;
    if (isWide) {
      return Row(
        children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
          const SizedBox(width: 12),
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards.map((card) => SizedBox(width: 220, child: card)).toList(),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCenter(List<Map<String, dynamic>> requests) {
    final rejected = requests
        .where((e) => _statusValue(e) == 'rejected')
        .toList();
    final pending = requests
        .where((e) => _statusValue(e) == 'pending')
        .toList();

    if (rejected.isNotEmpty) {
      final item = rejected.first;
      final reason = _rejectionReason(item);
      final suggestion = _getSuggestion(reason);
      final isBusy = _resubmittingId == (item['id']?.toString() ?? '');

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Action Center',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Action Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Reason: $reason'),
            const SizedBox(height: 8),
            Text(suggestion, style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: isBusy ? null : () => _resubmit(item),
              child: Text(isBusy ? 'Resubmitting...' : 'Fix & Resubmit'),
            ),
          ],
        ),
      );
    }

    if (pending.isNotEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action Center',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Your OD request is under review'),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Action Center',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('All requests are approved'),
        ],
      ),
    );
  }

  Widget _buildRequestsSection(List<Map<String, dynamic>> requests) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OD Requests',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          '${requests.length} total request${requests.length == 1 ? '' : 's'}',
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('od_requests')
              .where('student_id', isEqualTo: AuthStore.userId ?? '')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                child: const Text(
                  'Unable to load OD requests right now.',
                  style: TextStyle(color: Colors.redAccent),
                ),
              );
            }

            final docs = snapshot.data?.docs ?? const [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
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
              children: docs.map((doc) {
                final data = doc.data();
                final item = <String, dynamic>{
                  ...data,
                  'id': data['id']?.toString().isNotEmpty == true
                      ? data['id']
                      : doc.id,
                };
                return PortalRequestCard(r: item);
              }).toList(),
            );
          },
        ),
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
  final TextEditingController eventNameController = TextEditingController();
  final TextEditingController venueController = TextEditingController();
  final TextEditingController organizerController = TextEditingController();
  final TextEditingController reasonController = TextEditingController();
  final TextEditingController dateTimeController = TextEditingController();
  DateTime? selectedDateTime;

  // File attachment
  String? _fileName;
  String? _fileUrl;
  String? _fileBase64;
  String? _fileMime;
  bool _fileLoading = false;

  bool _submitting = false;

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    eventNameController.dispose();
    venueController.dispose();
    organizerController.dispose();
    reasonController.dispose();
    dateTimeController.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    // Validate
    if (selectedDateTime == null) {
      _err('Select date and time');
      return;
    }
    if (eventNameController.text.trim().isEmpty) {
      _err('Enter event name');
      return;
    }
    if (venueController.text.trim().isEmpty) {
      _err('Enter venue');
      return;
    }
    if (organizerController.text.trim().isEmpty) {
      _err('Enter organizer');
      return;
    }
    if (reasonController.text.trim().isEmpty) {
      _err('Enter a reason');
      return;
    }

    final validation = OdRuleEngine.validateApplication(
      startDateTime: selectedDateTime!,
      endDateTime: selectedDateTime!,
      isMultiDay: false,
    );
    if (!validation.isValid) {
      _err(validation.violations.first.message);
      return;
    }

    setState(() {
      _submitting = true;
    });

    // Build reason — append file info if attached
    String reason = reasonController.text.trim();
    if (_fileName != null) {
      reason += '\n[Attachment: $_fileName]';
    }

    try {
      await FirebaseFirestore.instance.collection('od_requests').add({
        'event_name': eventNameController.text.trim(),
        'datetime': selectedDateTime!.toIso8601String(),
        'start_datetime': selectedDateTime!.toIso8601String(),
        'venue': venueController.text.trim(),
        'organizer': organizerController.text.trim(),
        'organiser': organizerController.text.trim(),
        'reason': reason,
        'file_url': _fileUrl ?? '',
        'attachment_base64': _fileBase64,
        'attachment_mime': _fileMime,
        'attachment_name': _fileName,
        'status': 'Pending',
        'mentor_approved': false,
        'hod_approved': false,
        'principal_approved': false,
        'rejected': false,
        'is_pinned': false,
        'expired': false,
        'created_at': FieldValue.serverTimestamp(),
        'student_name': AuthStore.fullName ?? 'Student',
        'student_id': AuthStore.userId ?? '',
      });
      await FirebaseFirestore.instance.collection('notifications').add({
        'user_role': 'mentor',
        'title': 'New OD Request',
        'message': 'A student submitted OD request',
        'seen': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('OD stored successfully');

      setState(() => _submitting = false);
      if (!mounted) return;

      setState(() {
        eventNameController.clear();
        venueController.clear();
        organizerController.clear();
        reasonController.clear();
        dateTimeController.clear();
        _fileName = null;
        _fileUrl = null;
        _fileBase64 = null;
        selectedDateTime = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OD Request submitted successfully! ✓'),
          backgroundColor: Colors.green,
        ),
      );
      // After successful submit, go back to dashboard where the OD is visible.
      widget.onSubmitted?.call();
    } catch (e) {
      debugPrint('Error submitting OD: $e');
      setState(() => _submitting = false);
      if (!mounted) return;
      _err('Failed to submit OD: $e');
    }
  }

  void _err(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );

    if (date == null) return;

    if (!context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      final finalDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      selectedDateTime = finalDateTime;
      dateTimeController.text = _formatDateTime(finalDateTime);
    });
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

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
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mentor → HoD',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.72),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: portalCardDecoration(context),
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
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: eventNameController,
                            decoration: InputDecoration(
                              labelText: 'Event Name',
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Date & Time *',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: dateTimeController,
                                readOnly: true,
                                onTap: pickDateTime,
                                decoration: InputDecoration(
                                  hintText: 'Select Date & Time',
                                  border: _border(Colors.grey),
                                  enabledBorder: _border(Colors.grey),
                                  focusedBorder: _border(kBlue),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today_outlined,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _field(
                          'Venue *',
                          venueController,
                          'e.g. Anna University, Chennai',
                        ),
                        _field(
                          'Organizer *',
                          organizerController,
                          'e.g. IEEE Chennai Section',
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: kBlue.withValues(alpha: 0.4),
                                      style: BorderStyle.solid,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    color: kBlue.withValues(alpha: 0.03),
                                  ),
                                  child: _fileLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(),
                                        )
                                      : const Column(
                                          children: [
                                            Icon(
                                              Icons.upload_file,
                                              size: 36,
                                              color: kBlue,
                                            ),
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
                                  border: Border.all(
                                    color: Colors.green.shade300,
                                  ),
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
                                        _fileUrl = null;
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
                          reasonController,
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
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
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

    final file = input.files![0];
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    final result = reader.result as String;
    final commaIdx = result.indexOf(',');
    final base64 = result.substring(commaIdx + 1);
    final mime = result.substring(5, result.indexOf(';'));

    if (base64.length * 3 / 4 > 5 * 1024 * 1024) {
      if (!mounted) return;
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
      _fileUrl = result;
      _fileBase64 = base64;
      _fileMime = mime;
      _fileLoading = false;
    });
  }
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
                decoration: portalCardDecoration(context),
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
                      '${_items.length} request${_items.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._items
                        .where((r) {
                          final status = (r['status']?.toString() ?? '')
                              .toLowerCase();
                          return status == 'approved' || status == 'rejected';
                        })
                        .map((r) => _historyListItem(r as Map)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _historyListItem(Map r) {
    final status = r['status']?.toString() ?? 'Pending';
    final isApproved = status.toLowerCase() == 'approved';
    final color = isApproved ? Colors.green : Colors.red;
    final dateText = portalOdDateTime(r['datetime']);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r['event_name']?.toString() ?? 'Untitled event',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(dateText, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                ProofActionButtons(
                  fileUrl: r['file_url']?.toString() ?? '',
                  showDownload: true,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
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
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: portalCardDecoration(context),
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
              _infoCard(context, [
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
              ]),
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
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
        ),
      ],
    );
  }

  Widget _infoCard(
    BuildContext context,
    List<(String, String)> rows,
  ) => Container(
    decoration: portalCardDecoration(context, radius: 16),
    child: Column(
      children: List.generate(
        rows.length,
        (i) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(rows[i].$1, style: const TextStyle(color: Colors.grey)),
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
