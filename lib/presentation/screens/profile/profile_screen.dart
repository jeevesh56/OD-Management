import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/app_user.dart';
import '../../app/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _classNameCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _deptCtrl.dispose();
    _classNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(AppUser user) async {
    setState(() => _saving = true);
    final updated = AppUser(
      id: user.id,
      email: user.email,
      fullName: _nameCtrl.text.trim(),
      role: user.role,
      regNo: user.regNo,
      staffId: user.staffId,
      phone: _phoneCtrl.text.trim(),
      department: _deptCtrl.text.trim(),
      className: _classNameCtrl.text.trim(),
      section: user.section,
      classAdvisorId: user.classAdvisorId,
      photoUrl: user.photoUrl,
      createdAt: user.createdAt,
      updatedAt: DateTime.now(),
      isActive: user.isActive,
      requiresPasswordChange: user.requiresPasswordChange,
    );
    await ref.read(userRepositoryProvider).updateProfile(updated);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _nameCtrl.text = _nameCtrl.text.isEmpty ? user.fullName : _nameCtrl.text;
    _phoneCtrl.text = _phoneCtrl.text.isEmpty ? (user.phone ?? '') : _phoneCtrl.text;
    _deptCtrl.text =
        _deptCtrl.text.isEmpty ? user.department : _deptCtrl.text;
    _classNameCtrl.text =
        _classNameCtrl.text.isEmpty ? (user.className ?? '') : _classNameCtrl.text;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () => ref.read(authServiceProvider).signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: user.email,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _deptCtrl,
                decoration: const InputDecoration(labelText: 'Department'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _classNameCtrl,
                decoration: const InputDecoration(labelText: 'Class'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : () => _save(user),
                child: Text(_saving ? 'Saving...' : 'Save profile'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => context.go('/change-password'),
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
