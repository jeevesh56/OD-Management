import 'package:flutter/material.dart';

class ODHomeScreen extends StatelessWidget {
  const ODHomeScreen({super.key, this.username});

  final String? username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD3D3D3),
      appBar: AppBar(
        title: const Text(
          "OD Management",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFF11154A),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 24),
            Text(
              username != null && username!.isNotEmpty
                  ? "Welcome, $username"
                  : "Welcome to OD Management",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071B3B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Request and manage your OD applications here.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
