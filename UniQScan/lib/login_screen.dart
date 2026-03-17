import 'package:flutter/material.dart';
import 'api_service.dart';
import 'student_home_screen.dart';
import 'mentor_home_screen.dart';
import 'ec_home_screen.dart';
import 'hod_home_screen.dart';

const Color kBlue = Color(0xFF1565C0);
const Color kRed  = Color(0xFFB71C1C);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _regController       = TextEditingController();
  final _studentPwController = TextEditingController();
  bool  _studentPwVisible    = false;
  bool  _studentLoading      = false;

  final _staffIdController   = TextEditingController();
  final _staffPwController   = TextEditingController();
  bool  _staffPwVisible      = false;
  bool  _staffLoading        = false;
  int   _staffRole           = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _regController.dispose();
    _studentPwController.dispose();
    _staffIdController.dispose();
    _staffPwController.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: c),
  );

  void _err(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));

  Future<void> _loginStudent() async {
    final reg = _regController.text.trim();
    final pw  = _studentPwController.text.trim();
    if (reg.isEmpty) { _err('Enter your register number'); return; }
    if (pw.isEmpty)  { _err('Enter your password'); return; }
    setState(() => _studentLoading = true);
    final r = await AuthApi.login(emailOrId: reg, password: pw);
    setState(() => _studentLoading = false);
    if (!r.ok) { _err(r.error!); return; }
    if (AuthStore.role != 'student') { _err('Not a student account'); return; }
    if (!mounted) return;
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => const StudentHomeScreen()));
  }

  Future<void> _loginStaff() async {
    final id = _staffIdController.text.trim();
    final pw = _staffPwController.text.trim();
    if (id.isEmpty) { _err('Enter your Staff ID / email'); return; }
    if (pw.isEmpty) { _err('Enter your password'); return; }
    setState(() => _staffLoading = true);
    final r = await AuthApi.login(emailOrId: id, password: pw);
    setState(() => _staffLoading = false);
    if (!r.ok) { _err(r.error!); return; }
    if (!mounted) return;
    final role = AuthStore.role ?? '';
    final dest = <String, Widget>{
      'mentor': const MentorHomeScreen(),
      'ec':     const ECHomeScreen(),
      'hod':    const HoDHomeScreen(),
    }[role];
    if (dest == null) { _err('Role "$role" has no screen'); return; }
    Navigator.pushReplacement(context,
      MaterialPageRoute(builder: (_) => dest));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: kBlue, borderRadius: BorderRadius.circular(16)),
              child: const Center(
                child: Text('RIT', style: TextStyle(fontSize: 28,
                  fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('RIT OD Manager', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: kBlue)),
            const Text('Rajalakshmi Institute of Technology',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              labelColor: kBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kBlue,
              tabs: const [Tab(text: 'Student'), Tab(text: 'Staff')],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildStudentTab(), _buildStaffTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String t) => Text(t,
    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  Widget _buildStudentTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 16),
      _lbl('Register Number'),
      const SizedBox(height: 8),
      TextField(
        controller: _regController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: 'e.g. 2117240020160',
          border: _border(Colors.grey), enabledBorder: _border(Colors.grey),
          focusedBorder: _border(kBlue)),
      ),
      const SizedBox(height: 16),
      _lbl('Password'),
      const SizedBox(height: 8),
      TextField(
        controller: _studentPwController,
        obscureText: !_studentPwVisible,
        decoration: InputDecoration(hintText: 'Enter password',
          border: _border(Colors.grey), enabledBorder: _border(Colors.grey),
          focusedBorder: _border(kBlue),
          suffixIcon: IconButton(
            icon: Icon(_studentPwVisible
              ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
            onPressed: () => setState(
              () => _studentPwVisible = !_studentPwVisible),
          )),
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _studentLoading ? null : _loginStudent,
          style: ElevatedButton.styleFrom(backgroundColor: kBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12))),
          child: _studentLoading
            ? const SizedBox(width: 24, height: 24,
                child: CircularProgressIndicator(color: Colors.white,
                  strokeWidth: 2))
            : const Text('LOGIN AS STUDENT', style: TextStyle(
                color: Colors.white, fontSize: 16,
                fontWeight: FontWeight.bold)),
        ),
      ),
      const SizedBox(height: 12),
      const Center(child: Text(
        'Seed: student@rit.edu  •  pw: Test@1234',
        style: TextStyle(color: Colors.grey, fontSize: 11))),
    ]),
  );

  Widget _buildStaffTab() {
    final roles = [
      ('Mentor',            Icons.supervisor_account),
      ('Event Coordinator', Icons.event),
      ('HoD',               Icons.admin_panel_settings),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 16),
        _lbl('Staff Email'),
        const SizedBox(height: 8),
        TextField(
          controller: _staffIdController,
          decoration: InputDecoration(hintText: 'e.g. mentor@rit.edu',
            border: _border(Colors.grey), enabledBorder: _border(Colors.grey),
            focusedBorder: _border(kBlue)),
        ),
        const SizedBox(height: 16),
        _lbl('Password'),
        const SizedBox(height: 8),
        TextField(
          controller: _staffPwController,
          obscureText: !_staffPwVisible,
          decoration: InputDecoration(hintText: 'Enter password',
            border: _border(Colors.grey), enabledBorder: _border(Colors.grey),
            focusedBorder: _border(kBlue),
            suffixIcon: IconButton(
              icon: Icon(_staffPwVisible
                ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: () => setState(
                () => _staffPwVisible = !_staffPwVisible),
            )),
        ),
        const SizedBox(height: 16),
        _lbl('Role'),
        const SizedBox(height: 4),
        ...List.generate(roles.length, (i) => RadioListTile<int>(
          value: i, groupValue: _staffRole, activeColor: kBlue,
          title: Row(children: [
            Icon(roles[i].$2, size: 20, color: kBlue),
            const SizedBox(width: 8),
            Text(roles[i].$1),
          ]),
          onChanged: (v) => setState(() => _staffRole = v!),
        )),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: _staffLoading ? null : _loginStaff,
            style: ElevatedButton.styleFrom(backgroundColor: kBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12))),
            child: _staffLoading
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white,
                    strokeWidth: 2))
              : const Text('LOGIN AS STAFF', style: TextStyle(
                  color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Text(
          'mentor@rit.edu  |  ec@rit.edu  |  hod@rit.edu  •  Test@1234',
          style: TextStyle(color: Colors.grey, fontSize: 11))),
      ]),
    );
  }
}
