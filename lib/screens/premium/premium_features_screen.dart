import 'package:flutter/material.dart';

class PremiumFeaturesScreen extends StatelessWidget {
  const PremiumFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Premium Student Hub"), backgroundColor: Colors.red[800], foregroundColor: Colors.white),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _premiumModule(Icons.track_changes, "Internship Tracker", Colors.blue),
          _premiumModule(Icons.description, "Resume Builder", Colors.green),
          _premiumModule(Icons.record_voice_over, "Mock Interviews", Colors.orange),
          _premiumModule(Icons.code, "Coding Playground", Colors.purple),
          _premiumModule(Icons.people, "Referral System", Colors.teal),
        ],
      ),
    );
  }

  Widget _premiumModule(IconData icon, String title, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("PREMIUM", style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
