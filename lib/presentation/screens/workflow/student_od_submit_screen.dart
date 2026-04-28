import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/od_request.dart';
import '../../../domain/enums/od_status.dart';
import '../../../domain/enums/user_role.dart';
import '../../../widgets/role_notifications_panel.dart';
import '../../../widgets/notification_bell.dart';
import '../../app/app_providers.dart';

class StudentOdSubmitScreen extends ConsumerStatefulWidget {
  const StudentOdSubmitScreen({super.key});

  @override
  ConsumerState<StudentOdSubmitScreen> createState() =>
      _StudentOdSubmitScreenState();
}

class _StudentOdSubmitScreenState extends ConsumerState<StudentOdSubmitScreen> {
  final _eventCtrl = TextEditingController();
  final _organizerCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _multiDay = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _submitting = false;

  @override
  void dispose() {
    _eventCtrl.dispose();
    _organizerCtrl.dispose();
    _venueCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    final value = DateTime(picked.year, picked.month, picked.day, 9, 0);
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    if (_start == null || _end == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select start and end date')));
      return;
    }
    // Validation
    final now = DateTime.now();
    if (_start!.isBefore(DateTime(now.year, now.month, now.day))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot apply for past dates.')),
      );
      return;
    }
    if (!_multiDay) {
      if (_startTime == null || _endTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select start and end time.')),
        );
        return;
      }
      final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
      final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
      if (startMinutes < 8 * 60 || endMinutes > 17 * 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Allowed time: 8:00 AM to 5:00 PM')), 
        );
        return;
      }
      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End time must be after start time.')),
        );
        return;
      }
    }
    final startDateTime = _multiDay
        ? DateTime(_start!.year, _start!.month, _start!.day, 8, 0)
        : DateTime(_start!.year, _start!.month, _start!.day, _startTime?.hour ?? 8, _startTime?.minute ?? 0);
    final endDateTime = _multiDay
        ? DateTime(_end!.year, _end!.month, _end!.day, 17, 0)
        : DateTime(_end!.year, _end!.month, _end!.day, _endTime?.hour ?? 17, _endTime?.minute ?? 0);
    final request = OdRequest(
      id: 'od_${DateTime.now().millisecondsSinceEpoch}',
      studentId: user.id,
      eventName: _eventCtrl.text.trim(),
      organizer: _organizerCtrl.text.trim(),
      venue: _venueCtrl.text.trim(),
      startDateTime: startDateTime,
      endDateTime: endDateTime,
      isMultiDay: _multiDay,
      reason: _reasonCtrl.text.trim(),
      status: OdStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() => _submitting = true);
    final result = await ref.read(odRequestServiceProvider).createRequest(
          actorRole: UserRole.student,
          request: request,
        );
    await ref.read(auditLogServiceProvider).log(
          actorId: user.id,
          actorRole: user.role.value,
          action: 'OD_SUBMITTED',
          entityType: 'od_request',
          entityId: request.id,
          metadata: {'status': request.status.value},
        );
    setState(() => _submitting = false);

    if (!mounted) return;
    if (!result.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.violations.first.message)),
      );
      return;
    }

    await ref.read(notificationServiceProvider).sendNotification(
          'mentor',
          'New OD request submitted by ${user.fullName}',
          requestId: request.id,
          stage: 'student_submitted',
          dedupeKey: '${request.id}_student_submitted_mentor',
        );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OD submitted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final requestsStream = user == null
        ? const Stream<List<OdRequest>>.empty()
        : ref.watch(odRequestRepositoryProvider).watchByStudent(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student OD'),
        actions: [
          const NotificationBell(),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CheckboxListTile(
                  title: const Text('Multi-day OD'),
                  value: _multiDay,
                  onChanged: (value) {
                    setState(() {
                      _multiDay = value ?? false;
                      if (_multiDay) {
                        _startTime = null;
                        _endTime = null;
                      }
                    });
                  },
                ),
                TextField(
                  controller: _eventCtrl,
                  decoration: const InputDecoration(labelText: 'Event'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _organizerCtrl,
                  decoration: const InputDecoration(labelText: 'Organizer'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(start: true),
                        child: Text(_start == null ? 'Start date' : _start!.toString().split(' ').first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(start: false),
                        child: Text(_end == null ? 'End date' : _end!.toString().split(' ').first),
                      ),
                    ),
                  ],
                ),
                if (!_multiDay) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(start: true),
                          child: Text(_startTime == null
                              ? 'Start time'
                              : _startTime!.format(context)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _pickTime(start: false),
                          child: Text(_endTime == null
                              ? 'End time'
                              : _endTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Submitting...' : 'Submit OD'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<OdRequest>>(
                    stream: requestsStream,
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? const <OdRequest>[];
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.eventName),
                              subtitle: Text(item.status.value),
                              trailing: item.status == OdStatus.expired
                                  ? const Text(
                                      'Expired',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: RoleNotificationsPanel(currentRole: 'student'),
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
