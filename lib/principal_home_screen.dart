import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'main.dart';
import 'screens/login_screen.dart';

class PrincipalHomeScreen extends StatefulWidget {
  const PrincipalHomeScreen({super.key});

  @override
  State<PrincipalHomeScreen> createState() => _PrincipalHomeScreenState();
}

class _PrincipalHomeScreenState extends State<PrincipalHomeScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _queue = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_busy) {
        _loadQueue(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue({bool silent = false}) async {
    if (_busy) return;
    _busy = true;
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final res = await PrincipalApi.queue();
    if (!mounted) {
      _busy = false;
      return;
    }

    setState(() {
      _loading = false;
      if (res.ok) {
        final data = res.data;
        if (data is List) {
          _queue = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          _queue = [];
        }
      } else {
        _error = res.error ?? 'Failed to load principal queue';
      }
    });
    _busy = false;
  }

  Future<void> _approveOne(Map<String, dynamic> row) async {
    await PrincipalApi.action(
      requestId: row['id'].toString(),
      action: 'APPROVED',
      reason: 'Approved by Principal',
    );
    await _loadQueue();
  }

  Future<void> _rejectOne(Map<String, dynamic> row) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    await PrincipalApi.action(
      requestId: row['id'].toString(),
      action: 'REJECTED',
      reason: reason,
    );
    await _loadQueue();
  }

  Future<void> _bulkApproveEvent(String eventName) async {
    await PrincipalApi.bulkApprove(eventName);
    await _loadQueue();
  }

  Future<void> _logout() async {
    AuthStore.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ODLoginUI()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in _queue) {
      final key = (row['event_name']?.toString().trim().isNotEmpty == true)
          ? row['event_name'].toString().trim()
          : 'Unknown event';
      grouped.putIfAbsent(key, () => <Map<String, dynamic>>[]).add(row);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Principal Dashboard'),
        actions: [
          IconButton(onPressed: ThemeController.toggle, icon: const Icon(Icons.brightness_6_outlined)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _loadQueue,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: grouped.entries.map((entry) {
                      final eventName = entry.key;
                      final items = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      eventName,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _bulkApproveEvent(eventName),
                                    child: Text('Approve All for $eventName'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ...items.map((row) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFFE2E6F0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Student Request ID: ${row['id']}'),
                                        Text('Venue: ${row['venue'] ?? '—'}'),
                                        Text('Date/Time: ${row['datetime'] ?? '—'}'),
                                        Text('Reason: ${row['reason'] ?? '—'}'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            FilledButton(
                                              onPressed: () => _approveOne(row),
                                              child: const Text('Approve'),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () => _rejectOne(row),
                                              child: const Text('Reject'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
    );
  }
}
