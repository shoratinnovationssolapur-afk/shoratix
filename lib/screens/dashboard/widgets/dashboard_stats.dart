import 'package:flutter/material.dart';

class DashboardStats extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardStats({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
