import 'package:flutter/material.dart';

class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Performance"), elevation: 0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics_rounded, size: 80, color: Color(0xFFFF5252)),
            const SizedBox(height: 20),
            const Text("Track student progress and test scores.", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text("Performance analytics will appear here.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
